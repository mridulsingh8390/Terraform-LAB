# Azure AKS — PROD
resource_group_name = "rg-aks-prod"
location             = "eastus"
prefix               = "aks-prod"

tags = {
  environment = "prod"
  cloud       = "azure"
  managed_by  = "terraform"
}

vnet_name              = "vnet-aks-prod"
vnet_cidr              = "10.0.0.0/8"
aks_system_subnet_cidr = "10.0.0.0/20"
aks_user_subnet_cidr   = "10.0.16.0/20"
storage_subnet_cidr    = "10.0.32.0/24"

key_vault_name                    = "kv-aksprd-mridul05"
kv_sku_name                       = "premium"
kv_soft_delete_retention_days    = 90
kv_purge_protection_enabled      = true
kv_public_network_access_enabled = false
kv_network_default_action        = "Deny"

storage_account_name     = "staksprdmridul05"
storage_replication_type = "ZRS"
postgres_share_name      = "postgres-data"
postgres_share_quota_gb  = 500

cluster_name = "aks-prod-cluster"
dns_prefix   = "aksprd"

system_node_vm_size = "Standard_D8s_v5"
system_node_min     = 3
system_node_max     = 5

user_node_vm_size = "Standard_E16s_v5"
user_node_min     = 3
user_node_max     = 10
