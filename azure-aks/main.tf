# Name: main.tf
# Owner: Saurav Mitra
# Description: This terraform config will provision vnet, vpn & aks cluster

# Resource Group
resource "azurerm_resource_group" "azure_infra" {
  name     = "${var.prefix}-rg"
  location = var.rg_location
}

# VNET & VPN
module "vnet_vpn" {
  source                    = "./1_vnet_vpn"
  prefix                    = var.prefix
  env                       = var.env
  owner                     = var.owner
  rg_location               = var.rg_location
  rg_name                   = azurerm_resource_group.azure_infra.name
  vnet_cidr_block           = var.vnet_cidr_block
  private_subnets           = var.private_subnets
  public_subnets            = var.public_subnets
  openvpn_server_image_name = var.openvpn_server_image_name
  vm_size                   = var.vm_size
  vpn_admin_user            = var.vpn_admin_user
  vpn_admin_password        = var.vpn_admin_password
  ssh_user                  = var.ssh_user
  ssh_public_key            = var.ssh_public_key
}


# AKS
module "aks" {
  source            = "./2_aks"
  prefix            = var.prefix
  env               = var.env
  owner             = var.owner
  rg_location       = var.rg_location
  rg_name           = azurerm_resource_group.azure_infra.name
  rg_id             = azurerm_resource_group.azure_infra.id
  vnet_cidr_block   = var.vnet_cidr_block
  vnet_id           = module.vnet_vpn.vnet_id
  private_subnet_id = module.vnet_vpn.private_subnet_id
  public_subnet_id  = module.vnet_vpn.public_subnet_id
  aks_version       = var.aks_version
  aks_vm_size       = var.aks_vm_size
}