# Name: outputs.tf
# Owner: Saurav Mitra
# Description: Outputs the VNET, Subnet IDs, AKS ARNs
# https://www.terraform.io/docs/configuration/outputs.html

output "resource_group_location" {
  value       = azurerm_resource_group.azure_infra.location
  description = "The Resource Group Location."
}

output "resource_group_name" {
  value       = azurerm_resource_group.azure_infra.name
  description = "The Resource Group Name."
}

# VNET
output "vnet_id" {
  value       = module.vnet_vpn.vnet_id
  description = "The VNET ID."
}

output "vnet_cidr_block" {
  value       = var.vnet_cidr_block
  description = "The address space that is used by the virtual network."
}

output "public_subnet_id" {
  value       = module.vnet_vpn.public_subnet_id
  description = "The public subnets ID."
}

output "private_subnet_id" {
  value       = module.vnet_vpn.private_subnet_id
  description = "The private subnets ID."
}

# OpenVPN Access Server
output "openvpn_access_server" {
  value       = module.vnet_vpn.openvpn_access_server
  description = "OpenVPN Access Server URL."
}

output "openvpn_access_server_admin" {
  value       = module.vnet_vpn.openvpn_access_server_admin
  description = "OpenVPN Access Server Admin URL."
}

# AKS
output "cluster_name" {
  value       = module.aks.cluster_name
  description = "AKS cluster Name."
}

output "cluster_id" {
  value       = module.aks.cluster_id
  description = "AKS cluster Id."
}

output "cluster_private_endpoint" {
  value       = module.aks.cluster_private_endpoint
  description = "Endpoint for AKS control plane."
}

output "kube_config" {
  value       = module.aks.kube_config
  description = "Kubeconfig block for AKS cluster"
  sensitive   = true
}

output "client_certificate" {
  value       = module.aks.client_certificate
  description = "client certificate for AKS cluster"
  sensitive   = true
}

output "kubeconfig_ca_data" {
  value       = module.aks.kubeconfig_ca_data
  description = "certificate-authority-data for AKS cluster"
  sensitive   = true
}