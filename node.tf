resource "azurerm_virtual_network" "workshop_node_virtual_network" {
  name                = "workshop-node-virtual-network"
  address_space       = ["10.0.0.0/16"]
  location            = "West Europe"
  resource_group_name = "docker-swarm-from-theory-to-practice"
}

resource "azurerm_subnet" "workshop_node_subnet" {
  name                 = "workshop-node-subnet"
  resource_group_name  = "docker-swarm-from-theory-to-practice"
  virtual_network_name = "${azurerm_virtual_network.workshop_node_virtual_network.name}"
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_network_security_group" "workshop_node_network_security_group" {
  name                = "workshop-node-network-security-group"
  location            = "West Europe"
  resource_group_name = "docker-swarm-from-theory-to-practice"

  security_rule {
    name                       = "AllowSSH"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 1020
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "workshop_node_network_interface" {
  name                      = "workshop-node-network-interface"
  location                  = "West Europe"
  resource_group_name       = "docker-swarm-from-theory-to-practice"
  network_security_group_id = "${azurerm_network_security_group.workshop_node_network_security_group.id}"

  ip_configuration {
    name                          = "workshop-node-ip-configuration"
    subnet_id                     = "${azurerm_subnet.workshop_node_subnet.id}"
    private_ip_address_allocation = "dynamic"
  }
}

resource "azurerm_virtual_machine" "workshop_node_vm" {
  name                             = "workshop-node-vm"
  location                         = "West Europe"
  resource_group_name              = "docker-swarm-from-theory-to-practice"
  network_interface_ids            = ["${azurerm_network_interface.workshop_node_network_interface.id}"]
  vm_size                          = "Standard_D2s_v3"
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  # Optional data disks
  storage_data_disk {
    name              = "workshop-node-vm-data-disk"
    managed_disk_type = "Premium_LRS"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "128"
  }

  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}
