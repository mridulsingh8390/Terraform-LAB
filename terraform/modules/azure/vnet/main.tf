################################################################################
# Azure VNet Module
# Creates: VNet, subnets (aks_system, aks_user, storage), NSG per subnet,
# NSG associations
################################################################################

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.vnet_cidr]
  tags                = var.tags
}

# ── Subnets ──────────────────────────────────────────────────────────────────

resource "azurerm_subnet" "aks_system" {
  name                 = "${var.prefix}-snet-aks-system"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.aks_system_subnet_cidr]
}

resource "azurerm_subnet" "aks_user" {
  name                 = "${var.prefix}-snet-aks-user"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.aks_user_subnet_cidr]

  # Required so the storage account network ACL can allow this subnet.
  # AKS pods (including PostgreSQL) mount Azure Files NFS from this subnet.
  service_endpoints = ["Microsoft.Storage"]
}

resource "azurerm_subnet" "storage" {
  name                 = "${var.prefix}-snet-storage"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.storage_subnet_cidr]

  service_endpoints = ["Microsoft.Storage"]
}

# ── NSG — AKS system subnet ───────────────────────────────────────────────────

resource "azurerm_network_security_group" "aks_system" {
  name                = "${var.prefix}-nsg-aks-system"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "allow-aks-internal"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.vnet_cidr
    destination_address_prefix = var.vnet_cidr
  }

  security_rule {
    name                       = "deny-internet-inbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

# ── NSG — AKS user subnet ─────────────────────────────────────────────────────

resource "azurerm_network_security_group" "aks_user" {
  name                = "${var.prefix}-nsg-aks-user"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "allow-aks-internal"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.vnet_cidr
    destination_address_prefix = var.vnet_cidr
  }

  # Allow inbound from Azure Files (SMB 445 / NFS 2049) within the VNet
  security_rule {
    name                       = "allow-azure-files-nfs"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "2049"
    source_address_prefix      = var.storage_subnet_cidr
    destination_address_prefix = var.aks_user_subnet_cidr
  }

  security_rule {
    name                       = "deny-internet-inbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

# ── NSG — Storage subnet ──────────────────────────────────────────────────────

resource "azurerm_network_security_group" "storage" {
  name                = "${var.prefix}-nsg-storage"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "allow-aks-to-nfs"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "2049"
    source_address_prefix      = var.aks_user_subnet_cidr
    destination_address_prefix = var.storage_subnet_cidr
  }

  security_rule {
    name                       = "deny-internet-inbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

# ── NSG associations ──────────────────────────────────────────────────────────

resource "azurerm_subnet_network_security_group_association" "aks_system" {
  subnet_id                 = azurerm_subnet.aks_system.id
  network_security_group_id = azurerm_network_security_group.aks_system.id
}

resource "azurerm_subnet_network_security_group_association" "aks_user" {
  subnet_id                 = azurerm_subnet.aks_user.id
  network_security_group_id = azurerm_network_security_group.aks_user.id
}

resource "azurerm_subnet_network_security_group_association" "storage" {
  subnet_id                 = azurerm_subnet.storage.id
  network_security_group_id = azurerm_network_security_group.storage.id
}
