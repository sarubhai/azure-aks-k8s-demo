# Name: outputs.tf
# Owner: Saurav Mitra
# Description: Outputs the VNET, Subnet ARNs & VPN URL
# https://www.terraform.io/docs/configuration/outputs.html

# VNET
output "vnet_id" {
  value       = azurerm_virtual_network.vnet.id
  description = "The VNET ID."
}

output "vnet_cidr_block" {
  value       = var.vnet_cidr_block
  description = "The address space that is used by the virtual network."
}

output "public_subnet_id" {
  value       = azurerm_subnet.public_subnet.*.id
  description = "The public subnets ID."
}

output "private_subnet_id" {
  value       = azurerm_subnet.private_subnet.*.id
  description = "The private subnets ID."
}

# OpenVPN Access Server
output "openvpn_access_server" {
  value       = "https://${azurerm_public_ip.vpn_public_ip.ip_address}"
  description = "OpenVPN Access Server URL."
}

output "openvpn_access_server_admin" {
  value       = "https://${azurerm_public_ip.vpn_public_ip.ip_address}:943/admin"
  description = "OpenVPN Access Server Admin URL."
}