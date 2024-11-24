# variables.tf
# Owner: Saurav Mitra
# Description: Variables used by terraform config to create the infrastructure resources
# https://www.terraform.io/docs/configuration/variables.html

# Tags
variable "prefix" {
  description = "This prefix will be included in the name of the resources."
}

variable "env" {
  description = "The Deployment Environment."
}

variable "owner" {
  description = "This owner name tag will be included in the owner of the resources."
}

# Resource Group
variable "rg_location" {
  description = "Location of Resource Group"
}

variable "rg_name" {
  description = "Resource Group Name"
}

# VNET CIDR
variable "vnet_cidr_block" {
  description = "The address space that is used by the virtual network."
}

# Subnet CIDR
variable "private_subnets" {
  description = "A list of CIDR blocks to use for the private subnet."
}

variable "public_subnets" {
  description = "A list of CIDR blocks to use for the public subnet."
}

# OpenVPN Access Server
variable "openvpn_server_image_name" {
  description = "The OpenVPN Access Server AMI Name."
}

variable "vm_size" {
  description = "Azure Virtual Machine Size."
}

variable "ssh_user" {
  description = "The SSH Username."
}

variable "ssh_public_key" {
  description = "The SSH Public Key."
}

variable "vpn_admin_user" {
  description = "The OpenVPN Admin User."
}

variable "vpn_admin_password" {
  description = "The OpenVPN Admin Password."
}
