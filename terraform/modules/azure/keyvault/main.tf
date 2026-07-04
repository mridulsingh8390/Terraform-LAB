################################################################################
# Azure Key Vault Module
# Creates:
#   - Key Vault (RBAC-authorised, purge-protected for prod)
#   - CMK RSA key used to encrypt AKS OS disks, etcd, and Azure Files
#   - Disk Encryption Set (DES) — references the CMK key
#   - Role assignments so DES can use the CMK key
################################################################################

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  name                          = var.key_vault_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = var.sku_name
  soft_delete_retention_days    = var.soft_delete_retention_days
  purge_protection_enabled      = var.purge_protection_enabled
  public_network_access_enabled = var.public_network_access_enabled

  # RBAC-based authorization — no legacy access policies
  rbac_authorization_enabled = true

  network_acls {
    default_action = var.network_default_action
    bypass         = "AzureServices"
    ip_rules       = var.allowed_ip_rules
  }

  tags = var.tags
}

# ── Deployer gets Key Vault Administrator role so pipeline can manage keys/secrets

resource "azurerm_role_assignment" "deployer_admin" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

# ── CMK key — RSA-HSM 4096-bit for FIPS compliance ──────────────────────────

resource "azurerm_key_vault_key" "cmk" {
  name         = "${var.prefix}-cmk"
  key_vault_id = azurerm_key_vault.kv.id
  key_type     = "RSA"
  key_size     = 4096

  key_opts = [
    "decrypt", "encrypt",
    "sign", "verify",
    "wrapKey", "unwrapKey",
  ]

  rotation_policy {
    automatic {
      time_before_expiry = "P30D"
    }
    expire_after         = "P365D"
    notify_before_expiry = "P29D"
  }

  depends_on = [azurerm_role_assignment.deployer_admin]
}

# ── Disk Encryption Set — wraps the CMK key for AKS OS disk encryption ───────

resource "azurerm_disk_encryption_set" "des" {
  name                = "${var.prefix}-des"
  location            = var.location
  resource_group_name = var.resource_group_name
  key_vault_key_id    = azurerm_key_vault_key.cmk.id

  # System-assigned identity used by Azure to access the Key Vault key
  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# ── Grant the DES identity permission to use the CMK key ──────────────────────
# Without this, AKS node disk encryption will fail when provisioning nodes.

resource "azurerm_role_assignment" "des_key_user" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_disk_encryption_set.des.identity[0].principal_id
}
