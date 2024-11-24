# variables.tf
# Owner: Saurav Mitra
# Description: Variables used by terraform config to create the infrastructure resources
# https://www.terraform.io/docs/configuration/variables.html

# Tags
variable "prefix" {
  description = "This prefix will be included in the name of the resources."
  default     = "azure-aks-k8s-demo"
}

variable "env" {
  description = "The Deployment Environment."
  default     = "dev"
}

variable "owner" {
  description = "This owner name tag will be included in the owner of the resources."
  default     = "Saurav Mitra"
}

# Resource Group Location
variable "rg_location" {
  description = "Location of Resource Group"
  default     = "germanywestcentral"
}

# VNET CIDR
variable "vnet_cidr_block" {
  description = "The address space that is used by the virtual network."
  default     = "10.30.0.0/16"
}

# Subnet CIDR
variable "private_subnets" {
  description = "A list of CIDR blocks to use for the private subnet."
  default     = ["10.30.1.0/24", "10.30.2.0/24", "10.30.3.0/24"]
}

variable "public_subnets" {
  description = "A list of CIDR blocks to use for the public subnet."
  default     = ["10.30.4.0/24", "10.30.5.0/24", "10.30.6.0/24"]
}

# OpenVPN Access Server
variable "openvpn_server_image_name" {
  description = "The OpenVPN Access Server AMI Name."
  default     = "OpenVPN Access Server Community Image"
  # default     = "ami-0269405596354b6a4"
}

variable "vm_size" {
  description = "Azure Virtual Machine Size."
  default     = "Standard_B1s"
}

variable "ssh_user" {
  description = "The SSH Username."
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "The SSH Public Key."
}

variable "vpn_admin_user" {
  description = "The OpenVPN Admin User."
  default     = "openvpn"
}

variable "vpn_admin_password" {
  description = "The OpenVPN Admin Password."
}

# AKS
variable "aks_version" {
  description = "The AKS Version."
  default     = "1.30"
}

variable "aks_vm_size" {
  description = "The AKS VM Size."
  default     = "Standard_D2_v2"
}