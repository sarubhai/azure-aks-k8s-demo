# Name: aks_dependencies.tf
# Owner: Saurav Mitra
# Description: This terraform config will create resources like DNS, AGW, KV, ACR etc for the AKS Cluster

data "azurerm_client_config" "current" {}

# AKS Private DNS Zone
resource "azurerm_private_dns_zone" "private_dns_aks" {
  name                = "privatelink.${var.rg_location}.azmk8s.io"
  resource_group_name = var.rg_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dna_aks_vnet_link" {
  name                  = "aks-dns-link-${var.prefix}-vnet"
  resource_group_name   = var.rg_name
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_aks.name
  virtual_network_id    = var.vnet_id
}



# Application Gateway
resource "azurerm_public_ip" "agw_public_ip" {
  name                = "${var.prefix}-agw-public-ip"
  location            = var.rg_location
  resource_group_name = var.rg_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Name  = "${var.prefix}-agw-public-ip"
    Owner = var.owner
  }
}

locals {
  backend_address_pool_name      = "${var.prefix}-vnet-beap"
  frontend_port_name             = "${var.prefix}-vnet-feport"
  frontend_ip_configuration_name = "${var.prefix}-vnet-feip"
  http_setting_name              = "${var.prefix}-vnet-be-htst"
  listener_name                  = "${var.prefix}-vnet-httplstn"
  request_routing_rule_name      = "${var.prefix}-vnet-rqrt"
  redirect_configuration_name    = "${var.prefix}-vnet-rdrcfg"
}

resource "azurerm_application_gateway" "aks_agw" {
  name                = "${var.prefix}-aks-agw"
  location            = var.rg_location
  resource_group_name = var.rg_name

  sku {
    name     = "Standard_v2" # WAF_v2
    tier     = "Standard_v2" # WAF_v2
    capacity = 2
  }

  identity {
    type         = "UserAssigned" # SystemAssigned
    identity_ids = [azurerm_user_assigned_identity.agw_identity.id]
  }

  gateway_ip_configuration {
    name = "appGatewayIpConfig"
    # subnet_id = var.private_subnet_id[0]
    subnet_id = var.public_subnet_id[2]
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  # frontend_port {
  #   name = "https_port"
  #   port = 443
  # }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.agw_public_ip.id
  }

  # frontend_ip_configuration {
  #   name                          = "${local.frontend_ip_configuration_name}-private"
  #   subnet_id                     = var.public_subnet_id[2] # var.private_subnet_id[0]
  #   private_ip_address_allocation = "Static"
  #   private_ip_address            = "10.30.5.10"
  # }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  # http_listener {
  #   name                           = local.listener_name
  #   frontend_ip_configuration_name = "${local.frontend_ip_configuration_name}-private"
  #   frontend_port_name             = local.frontend_port_name
  #   protocol                       = "Http"
  # }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic" # "PathBasedRouting"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
    priority                   = 10
  }

  lifecycle {
    ignore_changes = [
      backend_address_pool,
      backend_http_settings,
      http_listener,
      probe,
      request_routing_rule,
      tags,
    ]
  }
}



# Key Vault
resource "random_integer" "rid" {
  min = 100
  max = 900
}
locals {
  suffix  = random_integer.rid.result
  kv_name = "aks-kv-${local.suffix}"
}

resource "azurerm_key_vault" "aks_kv" {
  name                            = local.kv_name
  location                        = var.rg_location
  resource_group_name             = var.rg_name
  sku_name                        = "standard" # premium
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  enable_rbac_authorization       = true
  public_network_access_enabled   = false
  purge_protection_enabled        = false
  soft_delete_retention_days      = 7
  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true

  network_acls {
    bypass         = "AzureServices"
    default_action = "Allow"
    # virtual_network_subnet_ids = var.private_subnet_id
  }
}

resource "azurerm_private_dns_zone" "private_dns_kv" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.rg_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "kv_vnet_link" {
  name                  = "kv-dns-link-${var.prefix}-vnet"
  resource_group_name   = var.rg_name
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_kv.name
  virtual_network_id    = var.vnet_id
}

resource "azurerm_private_endpoint" "kv_private_endpoint" {
  name                = "${local.kv_name}PrivateEndpoint"
  location            = var.rg_location
  resource_group_name = var.rg_name
  subnet_id           = var.private_subnet_id[1]

  private_service_connection {
    name                           = "aksAcrDemoConnection"
    private_connection_resource_id = azurerm_key_vault.aks_kv.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "KeyVaultPrivateDnsZoneGroup"
    private_dns_zone_ids = [azurerm_private_dns_zone.private_dns_kv.id]
  }
}



# Container Registry
resource "azurerm_user_assigned_identity" "acr_identity" {
  name                = "acr-identity"
  location            = var.rg_location
  resource_group_name = var.rg_name
}

resource "azurerm_container_registry" "aks_acr" {
  name                          = "aksAcrDemo"
  location                      = var.rg_location
  resource_group_name           = var.rg_name
  sku                           = "Premium" # Basic, Standard, Premium
  admin_enabled                 = false
  public_network_access_enabled = false # When sku is Premium
  # data_endpoint_enabled       = false

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.acr_identity.id]
  }
}

resource "azurerm_private_dns_zone" "private_dns_acr" {
  name                = "privatelink.azurecr.io"
  resource_group_name = var.rg_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr_vnet_link" {
  name                  = "acr-dns-link-${var.prefix}-vnet"
  resource_group_name   = var.rg_name
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_acr.name
  virtual_network_id    = var.vnet_id
}

resource "azurerm_private_endpoint" "acr_private_endpoint" {
  name                = "aksAcrDemoPrivateEndpoint"
  location            = var.rg_location
  resource_group_name = var.rg_name
  subnet_id           = var.private_subnet_id[1]

  private_service_connection {
    name                           = "aksAcrDemoConnection"
    private_connection_resource_id = azurerm_container_registry.aks_acr.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }

  private_dns_zone_group {
    name                 = "AcrPrivateDnsZoneGroup"
    private_dns_zone_ids = [azurerm_private_dns_zone.private_dns_acr.id]
  }
}