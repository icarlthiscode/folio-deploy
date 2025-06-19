terraform {
    required_version = "~> 1.12.2"
    required_providers {
        cloudflare = {
            source  = "cloudflare/cloudflare"
            version = "~> 5"
        }
        digitalocean = {
            source = "digitalocean/digitalocean"
            version = "~> 2.55"
        }
    }
}

provider "cloudflare" {
    api_token = var.cf_token
}

provider "digitalocean" {
    token = var.do_token
}

locals {
    app_version = (
        var.app_version != ""
            ? var.app_version
            : jsondecode(file("${path.module}/../folio/package.json")).version
    )
}

resource "digitalocean_droplet" "app" {
    name = "app"
    image = "debian-12-x64"
    region = "tor1"
    size = "s-1vcpu-1gb"
    ssh_keys = [48495529]
    user_data = templatefile(
        "${path.module}/cloud-init.tftpl",
        {
            ssh_port = var.ssh_port,
            ssh_public_key = file(var.ssh_public_key_file),
            hostname = var.domain,
            app_package = join("", [
                "ghcr.io/${var.namespace}/",
                "${var.app_package}:${local.app_version}"
            ])
        }
    )
    tags = ["folio", "production"]
}

resource "cloudflare_dns_record" "a" {
    zone_id = var.dns_zone
    name = var.domain
    type = "A"
    comment = "Personal website * portfolio"
    content = digitalocean_droplet.app.ipv4_address
    proxied = true
    ttl = 1
}
