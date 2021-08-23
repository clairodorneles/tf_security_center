
# Resource Group

resource "random_id" "randomId" {
    byte_length = 5
}

resource azurerm_resource_group "rg" {
    name     = "rg-${random_id.randomId.hex}"
    location = var.location
    tags     = var.tags 
}

resource "azurerm_log_analytics_workspace" "law" {
  name                = "la-${random_id.randomId.hex}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags

}

resource "azurerm_storage_account" "stg" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = azurerm_resource_group.rg.name
    location                    = azurerm_resource_group.rg.location
    account_replication_type    = "LRS"
    account_tier                = "Standard"
    tags                        = var.tags
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${random_id.randomId.hex}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["192.168.0.0/16"]
  tags                = var.tags

}

resource "azurerm_subnet" "snet" {
  name                 = "snet01"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["192.168.2.0/24"]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-${random_id.randomId.hex}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

}

resource "azurerm_network_security_rule" "example" {
  name                        = "rdp"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_network_security_rule" "ssh" {
  name                        = "ssh"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_subnet_network_security_group_association" "nsg-prd-snet" {
  subnet_id                 = azurerm_subnet.snet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_public_ip" "pip1" {
  name                = "pip1-${random_id.randomId.hex}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  tags                = var.tags

}

resource "azurerm_public_ip" "pip2" {
  name                = "pip2-${random_id.randomId.hex}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  tags                = var.tags

}

resource "azurerm_network_interface" "nic1" {
  name                = "nic1-${random_id.randomId.hex}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.snet.id
    public_ip_address_id          = azurerm_public_ip.pip1.id
    private_ip_address_allocation = "Dynamic"
  }
  tags                = var.tags

}

resource "azurerm_network_interface" "nic2" {
  name                = "nic2-${random_id.randomId.hex}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.snet.id
    public_ip_address_id          = azurerm_public_ip.pip2.id
    private_ip_address_allocation = "Dynamic"
  }
  tags                = var.tags

}

resource "azurerm_linux_virtual_machine" "vm-linux-n1" {
    name                  = "vm-linux-1"
    location              = azurerm_resource_group.rg.location
    resource_group_name   = azurerm_resource_group.rg.name
    network_interface_ids = [azurerm_network_interface.nic1.id]
    size                  = "Standard_B1MS"

    os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.10"
        version   = "latest"
    }

    computer_name  = "vm-linux-1"
    admin_username = var.adminuser
    admin_password = var.adminpass
    disable_password_authentication = false


    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.stg.primary_blob_endpoint
    }

    tags          = var.tags

}

resource "azurerm_windows_virtual_machine" "vm-windows-1" {
  name                = "vm-win-1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = var.adminuser
  admin_password      = var.adminpass
  network_interface_ids = [
    azurerm_network_interface.nic2.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
  tags          = var.tags
}