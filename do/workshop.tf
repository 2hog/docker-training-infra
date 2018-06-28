variable "do_token" {}

variable "cloudflare_domain" {}

variable "cloudflare_email" {}

variable "cloudflare_token" {}

variable "region" {
  type    = "string"
  default = "fra1"
}

variable "vm_count" {
  type    = "string"
  default = "3"
}

variable "size" {
  type    = "string"
  default = "s-1vcpu-1gb"
}

variable "vm_password" {}

# Template file for user data
data "template_file" "user_data" {
  template = "${file("../scripts/install-docker")}"
  vars {
    vm_password= "${var.vm_password}"
  }
}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = "${var.do_token}"
}

# Create the droplets
resource "digitalocean_droplet" "workshop_node_vm" {
  count              = "${var.vm_count}"
  name               = "workshop-${format("%02d", count.index / 3)}-vm-${format("%02d", count.index % 3)}"
  region             = "${var.region}"
  image              = "ubuntu-16-04-x64"
  size               = "${var.size}"
  monitoring         = true
  private_networking = true
  user_data          = "${data.template_file.user_data.rendered}"
}

provider "cloudflare" {
  email = "${var.cloudflare_email}"
  token = "${var.cloudflare_token}"
}

resource "cloudflare_record" "workshop_dns_record" {
  count  = "${var.vm_count}"
  domain = "${var.cloudflare_domain}"
  name   = "workshop-${format("%02d", count.index / 3)}-${format("%02d", count.index % 3)}"
  value  = "${element(digitalocean_droplet.workshop_node_vm.*.ipv4_address, count.index)}"
  type   = "A"
  ttl    = 3600
}