################################################################################
# Azure Storage Module
# Creates:
#   - Storage Account (CMK-encrypted via Key Vault key)
#   - Azure Files share (NFS protocol) — mounted as PVC in Kubernetes pods
#   - Encryption scope linking the storage account to the CMK key
#
# The Kubernetes StorageClass YAML is written to disk as a local_file so
# you can kubectl apply it alongside your PostgreSQL pod manifests.
################################################################################

resource "azurerm_storage_account" "sa" {
  name                      = var.storage_account_name
  location                  = var.location
  resource_group_name       = var.resource_group_name
  account_tier              = "Premium"
  account_replication_type  = var.replication_type
  account_kind              = "FileStorage"
  min_tls_version            = "TLS1_2"
  https_traffic_only_enabled = false # NFS requires false — NFS uses plain TCP not HTTPS

  # Network rule: restrict to the storage subnet + AKS subnets
  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    virtual_network_subnet_ids = var.allowed_subnet_ids
  }

  # CMK encryption — links this storage account to the Key Vault key
  identity {
    type = "SystemAssigned"
  }

  customer_managed_key {
    key_vault_key_id          = var.cmk_key_id
    user_assigned_identity_id = null # use system-assigned identity
  }

  tags = var.tags
}

# Grant the storage account's managed identity access to use the CMK key
resource "azurerm_role_assignment" "sa_cmk" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_storage_account.sa.identity[0].principal_id
}

# ── Azure Files NFS share ─────────────────────────────────────────────────────

resource "azurerm_storage_share" "postgres" {
  name               = var.postgres_share_name
  storage_account_id = azurerm_storage_account.sa.id
  quota              = var.postgres_share_quota_gb
  enabled_protocol   = "NFS" # NFS 3.0 — no SMB password needed, mounts like a Linux volume
}

# ── Kubernetes StorageClass manifest ─────────────────────────────────────────
# Written to disk by Terraform — apply with:
#   kubectl apply -f <output_path>/azure-files-nfs-storageclass.yaml

resource "local_file" "storageclass" {
  filename = "${var.k8s_manifest_output_path}/azure-files-nfs-storageclass.yaml"
  content  = <<-YAML
    # Azure Files NFS StorageClass for PostgreSQL PVC
    # CMK encryption is enforced at the storage account level.
    # Apply: kubectl apply -f azure-files-nfs-storageclass.yaml
    apiVersion: storage.k8s.io/v1
    kind: StorageClass
    metadata:
      name: azure-files-nfs-cmk
    provisioner: file.csi.azure.com
    allowVolumeExpansion: true
    reclaimPolicy: Retain
    volumeBindingMode: Immediate
    parameters:
      resourceGroup:  ${var.resource_group_name}
      storageAccount: ${azurerm_storage_account.sa.name}
      protocol:       nfs
      skuName:        Premium_LRS
    mountOptions:
      - nfsvers=4.1
      - hard
      - timeo=600
      - retrans=2
      - _netdev
  YAML
}
