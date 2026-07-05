################################################################################
# Azure AKS Module
# Creates:
#   - AKS cluster with system-assigned managed identity
#   - System node pool (CriticalAddonsOnly taint — only k8s components)
#   - User node pool (runs app workloads + PostgreSQL pods)
#   - CMK encryption: OS disks via Disk Encryption Set, etcd via Key Vault
#   - Azure Files CSI driver enabled (needed for NFS PVC mounts)
#   - OIDC issuer + workload identity enabled
################################################################################

data "azurerm_client_config" "current" {}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version

  # CMK encryption for OS disks across all node pools — top-level cluster argument
  # The Disk Encryption Set must have Key Vault Crypto access BEFORE AKS is created.
  disk_encryption_set_id = var.disk_encryption_set_id

  # System-assigned managed identity for the control plane
  identity {
    type = "SystemAssigned"
  }

  # ── System node pool ─────────────────────────────────────────────────────────
  # Runs only Kubernetes system components (CoreDNS, kube-proxy, etc.)
  # Tainted CriticalAddonsOnly so no application pods land here.
  default_node_pool {
    name       = "system"
    vm_size    = var.system_node_vm_size
    node_count = var.system_node_count

    auto_scaling_enabled = var.system_node_autoscale
    min_count            = var.system_node_autoscale ? var.system_node_min : null
    max_count            = var.system_node_autoscale ? var.system_node_max : null

    vnet_subnet_id  = var.system_subnet_id
    os_disk_size_gb = var.node_os_disk_size_gb
    os_disk_type    = "Managed"

    only_critical_addons_enabled = true

    upgrade_settings {
      max_surge = "10%"
    }

    tags = var.tags
  }

  # ── Network ──────────────────────────────────────────────────────────────────
  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
    service_cidr      = var.service_cidr
    dns_service_ip    = var.dns_service_ip
  }

  # ── Azure Files CSI driver — required for NFS PVC mounts ─────────────────────
  storage_profile {
    file_driver_enabled = true
    disk_driver_enabled = true
  }

  # ── OIDC + Workload Identity ──────────────────────────────────────────────────
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  # ── Key Vault Secrets Provider CSI ───────────────────────────────────────────
  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  # ── Azure RBAC for K8s authorization ─────────────────────────────────────────
  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = true
    tenant_id          = data.azurerm_client_config.current.tenant_id
  }

  azure_policy_enabled = true

  tags = var.tags

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count,
    ]
  }
}

# ── User node pool — runs app + PostgreSQL pods ───────────────────────────────

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = var.user_node_vm_size
  node_count            = var.user_node_count

  auto_scaling_enabled = var.user_node_autoscale
  min_count            = var.user_node_autoscale ? var.user_node_min : null
  max_count            = var.user_node_autoscale ? var.user_node_max : null

  vnet_subnet_id  = var.user_subnet_id
  os_disk_size_gb = var.node_os_disk_size_gb
  os_disk_type    = "Managed"
  mode            = "User"

  # disk_encryption_set_id is set at the cluster level (above) and applies
  # to all node pools automatically — no need to repeat it here.

  node_labels = {
    "workload-type" = "application"
    "storage-access" = "azure-files"
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [node_count]
  }
}

# ── Grant AKS control-plane identity Key Vault Crypto access ──────────────────
# AKS etcd encryption requires the cluster's identity to read the CMK key.

resource "azurerm_role_assignment" "aks_kv_crypto" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}
