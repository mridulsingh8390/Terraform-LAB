# Azure AKS — STAGING
resource_group_name = "rg-aks-staging"
location             = "eastus"
prefix               = "aks-staging"

tags = {
  environment = "staging"
  cloud       = "azure"
  managed_by  = "terraform"
}

vnet_name              = "vnet-aks-staging"
vnet_cidr              = "10.0.0.0/8"
aks_system_subnet_cidr = "10.0.0.0/20"
aks_user_subnet_cidr   = "10.0.16.0/20"
storage_subnet_cidr    = "10.0.32.0/24"

key_vault_name                    = "kv-aksstg-REPLACE"
kv_sku_name                       = "premium"
kv_soft_delete_retention_days    = 90
kv_purge_protection_enabled      = true
kv_public_network_access_enabled = true

storage_account_name     = "staksstgREPLACE"
storage_replication_type = "ZRS"
postgres_share_name      = "postgres-data"
postgres_share_quota_gb  = 200

cluster_name = "aks-staging-cluster"
dns_prefix   = "aksstg"

system_node_vm_size = "Standard_D4s_v5"
system_node_min     = 2
system_node_max     = 3

user_node_vm_size = "Standard_E8s_v5"
user_node_min     = 2
user_node_max     = 5
