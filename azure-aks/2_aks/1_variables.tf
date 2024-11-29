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

variable "rg_id" {
  description = "Resource Group Id"
}

# VNET CIDR
variable "vnet_cidr_block" {
  description = "The address space that is used by the virtual network."
}

variable "vnet_id" {
  description = "The VNET ID."
}

variable "private_subnet_id" {
  description = "The private subnets ID."
}

variable "public_subnet_id" {
  description = "The public subnets ID."
}

# AKS
variable "aks_version" {
  description = "The AKS Version."
}

variable "aks_vm_size" {
  description = "The AKS VM Size."
}

variable "aks_sku_tier" {
  description = "The AKS SKU Tier."
}

variable "aks_support_plan" {
  description = "The AKS Support Plan."
}