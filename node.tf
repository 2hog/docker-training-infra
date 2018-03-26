variable "location" {
  type    = "string"
  default = "West Europe"
}

variable "resource_group" {
  type    = "string"
  default = "docker-swarm-from-theory-to-practice"
}

variable "vm_count" {
  type    = "string"
  default = "42"
}

variable "vm_password" {}

resource "azurerm_virtual_network" "workshop_node_virtual_network" {
  count               = "${var.vm_count}"
  name                = "workshop-node-${format("%02d", count.index)}-virtual-network"
  address_space       = ["10.0.0.0/16"]
  location            = "${var.location}"
  resource_group_name = "${var.resource_group}"
}

resource "azurerm_subnet" "workshop_node_subnet" {
  count                = "${var.vm_count}"
  name                 = "workshop-node-${format("%02d", count.index)}-subnet"
  resource_group_name  = "${var.resource_group}"
  virtual_network_name = "${element(azurerm_virtual_network.workshop_node_virtual_network.*.name, count.index)}"
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_network_security_group" "workshop_node_network_security_group" {
  count               = "${var.vm_count}"
  name                = "workshop-node-${format("%02d", count.index)}-network-security-group"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group}"

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

resource "azurerm_public_ip" "workshop_node_network_public_ip" {
  count                        = "${var.vm_count}"
  name                         = "workshop-node-${format("%02d", count.index)}-network-public-ip"
  location                     = "${var.location}"
  resource_group_name          = "${var.resource_group}"
  public_ip_address_allocation = "static"
}

resource "azurerm_network_interface" "workshop_node_network_interface" {
  count                     = "${var.vm_count}"
  name                      = "workshop-node-${format("%02d", count.index)}-network-interface"
  location                  = "${var.location}"
  resource_group_name       = "${var.resource_group}"
  network_security_group_id = "${element(azurerm_network_security_group.workshop_node_network_security_group.*.id, count.index)}"

  ip_configuration {
    name                          = "workshop-node-${format("%02d", count.index)}-ip-configuration"
    subnet_id                     = "${element(azurerm_subnet.workshop_node_subnet.*.id, count.index)}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${element(azurerm_public_ip.workshop_node_network_public_ip.*.id, count.index)}"
  }
}

resource "azurerm_virtual_machine" "workshop_node_vm" {
  count                         = "${var.vm_count}"
  name                          = "workshop-node-${format("%02d", count.index)}-vm"
  location                      = "${var.location}"
  resource_group_name           = "${var.resource_group}"
  network_interface_ids         = ["${element(azurerm_network_interface.workshop_node_network_interface.*.id, count.index)}"]
  vm_size                       = "Standard_D2s_v3"
  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  # Create a 128GB OS disk, in order to have sufficient space to store
  # Docker data.
  storage_os_disk {
    name              = "workshop-node-${format("%02d", count.index)}-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
    disk_size_gb      = "128"
  }

  os_profile {
    computer_name  = "workshop-node"
    admin_username = "workshop"
    admin_password = "${var.vm_password}"
  }

  os_profile_linux_config {
    # Allow password authentication for workshop attendees.
    disable_password_authentication = false

    # Add my public key to all Virtual Machines created for debugging reasons.
    ssh_keys = [{
      path     = "/home/workshop/.ssh/authorized_keys"
      key_data = "${file("~/.ssh/id_rsa.pub")}"
    }]
  }

  # After creating the Virtual Machine, provision it by installing Docker
  # automatically and adding the user "workshop" to the "docker" group.
  provisioner "remote-exec" {
    script = "scripts/install-docker"

    connection {
      type        = "ssh"
      host        = "${element(azurerm_public_ip.workshop_node_network_public_ip.*.ip_address, count.index)}"
      user        = "workshop"
      private_key = "${file("~/.ssh/id_rsa")}"
    }
  }
}
