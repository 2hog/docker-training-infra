variable "do_token" {}

variable "cloudflare_domain" {}

variable "cloudflare_zone_id" {}

variable "cloudflare_email" {}

variable "cloudflare_token" {}

variable "vm_count" {
  type    = number
  default = 3
}

variable "per_user" {
  type    = number
  default = 3
}

variable "vm_offset" {
  type    = number
  default = 0
}

variable "do_ssh_keys" {
  type    = list
  default = []
}

variable "region" {
  type    = string
  default = "fra1"
}

variable "size" {
  type    = string
  default = "s-1vcpu-1gb"
}

variable "vm_password" {}

variable "init_kube" {
  type    = string
  default = "1"
}

variable "docker_version" {
  type    = string
  default = "19.03.13"
}

variable "docker_compose_version" {
  type    = string
  default = "1.27.4"
}

variable "helm_version" {
  type    = string
  default = "3.4.1"
}

# Template file for user data
data "template_file" "user_data" {
  template = file("scripts/bootstrap")

  vars = {
    vm_password            = var.vm_password
    init_kube              = var.init_kube
    docker_version         = var.docker_version
    docker_compose_version = var.docker_compose_version
    helm_version           = var.helm_version
  }
}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = var.do_token
}

# Create the droplets
resource "digitalocean_droplet" "workshop_node_vm" {
  count              = var.vm_count
  name               = format("workshop-vm-%02.0f-%.0f", 1 + (count.index + var.vm_offset) / var.per_user, (count.index + var.vm_offset) % var.per_user + 1)
  region             = var.region
  image              = "ubuntu-20-04-x64"
  size               = var.size
  monitoring         = true
  private_networking = true
  user_data          = data.template_file.user_data.rendered
  ssh_keys           = var.do_ssh_keys
}

provider "cloudflare" {
  email   = var.cloudflare_email
  api_key = var.cloudflare_token
}

resource "cloudflare_record" "workshop_dns_record" {
  count   = var.vm_count
  zone_id = var.cloudflare_zone_id
  name    = element(digitalocean_droplet.workshop_node_vm.*.name, count.index)
  value   = element(digitalocean_droplet.workshop_node_vm.*.ipv4_address, count.index)
  type    = "A"
  ttl     = 300
}

resource "cloudflare_record" "workshop_dns_record_subdomains" {
  count   = var.vm_count
  zone_id = var.cloudflare_zone_id
  name    = "*.${element(digitalocean_droplet.workshop_node_vm.*.name, count.index)}"
  value   = "${element(digitalocean_droplet.workshop_node_vm.*.name, count.index)}.${var.cloudflare_domain}"
  type    = "CNAME"
  ttl     = 300
}
