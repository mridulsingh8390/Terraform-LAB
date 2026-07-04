################################################################################
# Azure AKS Root Configuration
# Wires: vnet → keyvault → storage → aks
#
# CMK dependency order (critical — each step must complete before the next):
#   1. Key Vault + CMK key created
#   2. Disk Encryption Set created (references Key Vault)
#   3. DES identity granted Key Vault Crypto access
#   4. Storage Account created (references CMK key via customer_managed_key)
#   5. Storage Account identity granted Key Vault Crypto access
#   6. AKS cluster created (references DES for OS disk encryption)
#
# Terraform handles this via depends_on and module output references.
################################################################################

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# ── Step 1+2+3: VNet + Key Vault (with CMK key and Disk Encryption Set) ───────

module "vnet" {
  source = "../../modules/azure/vnet"

  vnet_name              = var.vnet_name
  prefix                 = var.prefix
  location               = azurerm_resource_group.rg.location
  resource_group_name    = azurerm_resource_group.rg.name
  vnet_cidr              = var.vnet_cidr
  aks_system_subnet_cidr = var.aks_system_subnet_cidr
  aks_user_subnet_cidr   = var.aks_user_subnet_cidr
  storage_subnet_cidr    = var.storage_subnet_cidr
  tags                   = var.tags
}

module "keyvault" {
  source = "../../modules/azure/keyvault"

  key_vault_name                = var.key_vault_name
  prefix                        = var.prefix
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  sku_name                      = var.kv_sku_name
  soft_delete_retention_days    = var.kv_soft_delete_retention_days
  purge_protection_enabled      = var.kv_purge_protection_enabled
  public_network_access_enabled = var.kv_public_network_access_enabled
  network_default_action        = var.kv_network_default_action
  tags                          = var.tags
}

# ── Step 4+5: Storage Account (CMK via Key Vault, NFS share for PostgreSQL) ───

module "storage" {
  source = "../../modules/azure/storage"

  storage_account_name     = var.storage_account_name
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  key_vault_id             = module.keyvault.key_vault_id
  cmk_key_id               = module.keyvault.cmk_key_id
  replication_type         = var.storage_replication_type
  postgres_share_name      = var.postgres_share_name
  postgres_share_quota_gb  = var.postgres_share_quota_gb
  k8s_manifest_output_path = var.k8s_manifest_output_path
  allowed_subnet_ids = [
    module.vnet.aks_user_subnet_id,
    module.vnet.storage_subnet_id,
  ]
  tags = var.tags
}

# ── Step 6: AKS (CMK OS disks via DES, Azure Files CSI enabled) ───────────────

module "aks" {
  source = "../../modules/azure/aks"

  cluster_name           = var.cluster_name
  location               = azurerm_resource_group.rg.location
  resource_group_name    = azurerm_resource_group.rg.name
  dns_prefix             = var.dns_prefix
  kubernetes_version     = var.kubernetes_version
  system_subnet_id       = module.vnet.aks_system_subnet_id
  user_subnet_id         = module.vnet.aks_user_subnet_id
  disk_encryption_set_id = module.keyvault.disk_encryption_set_id
  key_vault_id           = module.keyvault.key_vault_id
  node_os_disk_size_gb   = var.node_os_disk_size_gb
  service_cidr           = var.service_cidr
  dns_service_ip         = var.dns_service_ip

  system_node_vm_size   = var.system_node_vm_size
  system_node_autoscale = var.system_node_autoscale
  system_node_min       = var.system_node_min
  system_node_max       = var.system_node_max

  user_node_vm_size   = var.user_node_vm_size
  user_node_autoscale = var.user_node_autoscale
  user_node_min       = var.user_node_min
  user_node_max       = var.user_node_max

  tags = var.tags

  # AKS must be created AFTER storage so all CMK role assignments are done
  depends_on = [module.storage]
}
