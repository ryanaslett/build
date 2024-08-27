variable "orka_endpoint" {
  type    = string
  default = ""
}

variable "orka_auth_token" {
  type    = string
  default = ""
}

variable "ssh_username" {
  type    = string
  default = ""
}

variable "ssh_password" {
  type    = string
  default = ""
}

packer {
  required_plugins {
    macstadium-orka = {
      version = "~> 3.0"
      source  = "github.com/macstadium/macstadium-orka"
    }
  }
}

source "macstadium-orka" "macos11-intel-test-image" {
  source_image      = "90gbigsurssh.img"
  image_name        = "macos11-intel-test-latest.img"
  image_description = "The MacOS 11 Intel test image"
  orka_endpoint     = var.orka_endpoint
  orka_auth_token   = var.orka_auth_token
}

build {
  sources = [
    "macstadium-orka.macos11-intel-test-image"
  ]
  provisioner "shell" {
    inline = [
      "echo we are running on the remote host",
      "hostname",
      "touch .we-ran-packer-successfully"
    ]
  }
}