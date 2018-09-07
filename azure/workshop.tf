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

variable "dns-namespace" {
  type    = "string"
  default = "swarm-workshop-2hog"
}

variable "cloudflare_domain" {}

variable "cloudflare_email" {}

variable "cloudflare_token" {}

resource "azurerm_resource_group" "resource_group" {
  name     = "${var.resource_group}"
  location = "${var.location}"

  tags {
    environment = "workshop"
  }
}

# We are creating a single Virtual Network for all VMs needed for the workshop
# because of Azure's rate limiting policies.
resource "azurerm_virtual_network" "workshop_node_virtual_network" {
  name                = "workshop-virtual-network"
  address_space       = ["10.0.0.0/16"]
  location            = "${var.location}"
  resource_group_name = "${var.resource_group}"
}

# We are creating a single Subnet for all VMs needed for the workshop
# because of Azure's rate limiting policies.
resource "azurerm_subnet" "workshop_node_subnet" {
  name                 = "workshop-node-subnet"
  resource_group_name  = "${var.resource_group}"
  virtual_network_name = "${azurerm_virtual_network.workshop_node_virtual_network.name}"
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_network_security_group" "workshop_node_network_security_group" {
  name                = "workshop-node-network-security-group"
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

  security_rule {
    name                       = "AllowFiveThousand"
    priority                   = 1030
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowEightThousand"
    priority                   = 1040
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowEightyEighty"
    priority                   = 1050
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowEightEightEightEight"
    priority                   = 1060
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8888"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowNineNineNineNine"
    priority                   = 1070
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9999"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowNinetyNinety"
    priority                   = 1078
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9090"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "workshop_node_network_public_ip" {
  count                        = "${var.vm_count}"
  name                         = "workshop-node-${format("%02d", count.index)}-network-public-ip"
  location                     = "${var.location}"
  resource_group_name          = "${var.resource_group}"
  domain_name_label            = "${var.dns-namespace}-${format("%02d", count.index / 3 + 1)}-${format("%02d", count.index % 3 + 1)}"
  public_ip_address_allocation = "dynamic"
}

resource "azurerm_network_interface" "workshop_node_network_interface" {
  count                     = "${var.vm_count}"
  name                      = "workshop-node-${format("%02d", count.index)}-network-interface"
  location                  = "${var.location}"
  resource_group_name       = "${var.resource_group}"
  network_security_group_id = "${azurerm_network_security_group.workshop_node_network_security_group.id}"

  ip_configuration {
    name                          = "workshop-node-${format("%02d", count.index)}-ip-configuration"
    subnet_id                     = "${azurerm_subnet.workshop_node_subnet.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${element(azurerm_public_ip.workshop_node_network_public_ip.*.id, count.index)}"
  }
}

resource "azurerm_virtual_machine" "workshop_node_vm" {
  count                         = "${var.vm_count}"
  name                          = "workshop-vm-${format("%02d", count.index / 3)}-${format("%02d", count.index % 3)}"
  location                      = "${var.location}"
  resource_group_name           = "${var.resource_group}"
  network_interface_ids         = ["${element(azurerm_network_interface.workshop_node_network_interface.*.id, count.index)}"]
  vm_size                       = "Standard_DS1_v2"
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
    computer_name  = "workshop-node-${count.index % 3 + 1}"
    admin_username = "workshop"
    admin_password = "${var.vm_password}"
  }

  os_profile_linux_config {
    # Allow password authentication for workshop attendees.
    disable_password_authentication = false

    # Add my public key to all Virtual Machines created for debugging reasons.
    ssh_keys = [
      {
        path     = "/home/workshop/.ssh/authorized_keys"
        key_data = "${file("~/.ssh/id_rsa.pub")}"
      },
    ]
  }

  # After creating the Virtual Machine, provision it by installing Docker
  # automatically and adding the user "workshop" to the "docker" group.
  provisioner "remote-exec" {
    script = "scripts/install-docker"

    # We need to connect through the Public IP's Fully Qualified Domain Name
    # because the actual IP address has not been populated to Terraform yet,
    # as it's dynamically allocated.
    connection {
      type        = "ssh"
      host        = "${element(azurerm_public_ip.workshop_node_network_public_ip.*.fqdn, count.index)}"
      user        = "workshop"
      password    = "${var.vm_password}"
    }
  }
}

provider "cloudflare" {
  email = "${var.cloudflare_email}"
  token = "${var.cloudflare_token}"
}

resource "cloudflare_record" "workshop_dns_record" {
  count  = "${var.vm_count}"
  domain = "${var.cloudflare_domain}"
  name   = "${element(azurerm_virtual_machine.workshop_node_vm.*.name, count.index)}"
  value  = "${element(azurerm_public_ip.workshop_node_network_public_ip.*.fqdn, count.index)}"
  type   = "CNAME"
  ttl    = 3600
}
