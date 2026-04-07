terraform {
  backend "s3" {
    endpoints                   = { s3 = "https://fra1.digitaloceanspaces.com" }
    region                      = "us-east-1"
    key                         = "terraform.tfstate"
    bucket                      = "skorokhid-bucket"
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_s3_checksum            = true
  }
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {}

resource "digitalocean_vpc" "vpc" {
  name     = "skorokhid-vpc"
  region   = "fra1"
  ip_range = "10.10.10.0/24"
}

data "digitalocean_ssh_key" "main" {
  name = "skorokhid-key"
}

resource "digitalocean_droplet" "node" {
  image    = "ubuntu-24-04-x64"
  name     = "skorokhid-node"
  region   = "fra1"
  size     = "s-4vcpu-8gb"
  vpc_uuid = digitalocean_vpc.vpc.id
  ssh_keys = [data.digitalocean_ssh_key.main.id]
}

resource "digitalocean_firewall" "firewall" {
  name = "skorokhid-firewall"
  droplet_ids = [digitalocean_droplet.node.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "8000-8003"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

output "droplet_ip" {
  value = digitalocean_droplet.node.ipv4_address
}