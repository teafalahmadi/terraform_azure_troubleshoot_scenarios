##########################################
# Resource Group
##########################################
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

##########################################
# Virtual Network
##########################################
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

##########################################
# Subnets
##########################################
resource "azurerm_subnet" "public_subnet" {
  name                 = "public_subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "private_subnet" {
  name                 = "private_subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

##########################################
# Network Interfaces
##########################################
resource "azurerm_network_interface" "public_nic" {
  name                = "public_nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.public_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "private_nic" {
  name                = "private_nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.private_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

##########################################
# Network Security Groups
##########################################
resource "azurerm_network_security_group" "sg_8080" {
  name                = "sg_8080"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

resource "azurerm_network_security_group" "sg_ping" {
  name                = "sg_ping"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

##########################################
# Network Security Rules
##########################################
resource "azurerm_network_security_rule" "allow_ping" {
  name                        = "allow_ping"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Icmp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  source_application_security_group_ids = [azurerm_network_security_group.sg_8080.id]
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.sg_ping.name
}

resource "azurerm_network_security_rule" "allow_8080" {
  name                        = "allow_8080"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "8080"
  destination_port_range      = "8080"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  source_application_security_group_ids = [azurerm_network_security_group.sg_ping.id]
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.sg_8080.name
}

##########################################
# SSH Key
##########################################
resource "tls_private_key" "example_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

output "tls_private_key" {
  value     = tls_private_key.example_ssh.private_key_pem
  sensitive = true
}

##########################################
# Local NIC map
##########################################
locals {
  nic = {
    public_nic  = azurerm_network_interface.public_nic
    private_nic = azurerm_network_interface.private_nic
  }
}

##########################################
# Linux Virtual Machines
##########################################
resource "azurerm_linux_virtual_machine" "vm" {
  for_each = local.nic

  name                = "${var.vm_name}-learn"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    each.value.id
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.example_ssh.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  tags = var.tags
}
