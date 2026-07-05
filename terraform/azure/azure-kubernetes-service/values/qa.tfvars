# Azure AKS — QA
resource_group_name = "rg-aks-qa"
location             = "eastus"
prefix               = "aks-qa"

tags = {
  environment = "qa"
  cloud       = "azure"
  managed_by  = "terraform"
}

vnet_name              = "vnet-aks-qa"
vnet_cidr              = "10.0.0.0/8"
aks_system_subnet_cidr = "10.0.0.0/20"
aks_user_subnet_cidr   = "10.0.16.0/20"
storage_subnet_cidr    = "10.0.32.0/24"

key_vault_name                    = "kv-aksqa-REPLACE"
kv_sku_name                       = "premium"
kv_soft_delete_retention_days    = 30
kv_purge_protection_enabled      = true
kv_public_network_access_enabled = true

storage_account_name     = "staksqaREPLACE"
storage_replication_type = "LRS"
postgres_share_name      = "postgres-data"
postgres_share_quota_gb  = 100

cluster_name = "aks-qa-cluster"
dns_prefix   = "aksqa"

system_node_vm_size = "Standard_D2s_v5"
system_node_min     = 1
system_node_max     = 2

user_node_vm_size = "Standard_E4s_v5"
user_node_min     = 1
user_node_max     = 3
