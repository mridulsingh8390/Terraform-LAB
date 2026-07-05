# Azure AKS — DEV
# Update key_vault_name and storage_account_name before running (must be globally unique)
resource_group_name = "rg-aks-dev"
location             = "eastus"
prefix               = "aks-dev"

tags = {
  environment = "dev"
  cloud       = "azure"
  managed_by  = "terraform"
}

vnet_name              = "vnet-aks-dev"
vnet_cidr              = "10.0.0.0/8"
aks_system_subnet_cidr = "10.0.0.0/20"
aks_user_subnet_cidr   = "10.0.16.0/20"
storage_subnet_cidr    = "10.0.32.0/24"

key_vault_name                    = "kv-aksdev-mridul05"
kv_sku_name                       = "premium"
kv_soft_delete_retention_days    = 7
kv_purge_protection_enabled      = true
kv_public_network_access_enabled = true

storage_account_name    = "staksmridul05dev"
storage_replication_type = "LRS"
postgres_share_name     = "postgres-data"
postgres_share_quota_gb = 100
k8s_manifest_output_path = "./k8s-manifests"

cluster_name       = "aks-dev-cluster"
dns_prefix         = "aksdev"
kubernetes_version = null

system_node_vm_size   = "Standard_D2s_v5"
system_node_autoscale = true
system_node_min       = 1
system_node_max       = 2

user_node_vm_size   = "Standard_E4s_v5"
user_node_autoscale = true
user_node_min       = 1
user_node_max       = 3
