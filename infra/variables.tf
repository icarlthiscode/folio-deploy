variable "environment" {
    description = "The environment type for the deployment."
    type = string
    default = "production"
}

variable "namespace" {
    description = "The namespace for the application."
    type = string
}
variable "app_package" {
    description = "The application package to install on the app server."
    type = string
    default = "folio"
}
variable "app_version" {
    description = "The version of the application package to install."
    type = string
    default = ""
}

variable "domain" {
    description = "The application domain name."
    type = string
}
variable "dns_zone" {
    description = "The Cloudflare zone ID for the application domain."
    type = string
}

variable "ssh_port" {
    description = "The SSH port to use for the application server."
    type = number
    default = 22
}
variable "ssh_public_key_file" {
    description = "The path to the SSH public key file for server connection."
    type = string
    validation {
        condition = fileexists(var.ssh_public_key_file)
        error_message = "The SSH public key file does not exist."
    }

    validation {
        condition = can(regex(
            "^ssh-(rsa|ed25519)\\s[\\w0-9+/=]+",
            trimspace(file(var.ssh_public_key_file))
        ))
        error_message = "The file does not appear to be a valid SSH public key."
    }
}

variable "cf_token" {
    description = "Cloudflare API token for managing DNS records."
    type = string
}
variable "do_token" {
    description = "DigitalOcean API token for managing droplets."
    type = string
}
