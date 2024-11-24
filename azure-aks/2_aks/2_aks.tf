# Private DNS Zone
resource "azurerm_private_dns_zone" "private_dns_aks" {
  name                = "privatelink.${var.rg_location}.azmk8s.io"
  resource_group_name = var.rg_name
}

# Private DNS Zone Virtual Network Link
resource "azurerm_private_dns_zone_virtual_network_link" "private_dns_vnet_link" {
  name                  = "dns-link-${var.prefix}-vnet"
  resource_group_name   = var.rg_name
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_aks.name
  virtual_network_id    = var.vnet_id
}

# User Assigned Managed Identity for AKS
resource "azurerm_user_assigned_identity" "aks_identity" {
  name                = "aks-identity"
  location            = var.rg_location
  resource_group_name = var.rg_name
}

# Role Assignment for AKS Managed Identity
resource "azurerm_role_assignment" "aks_identity_role" {
  principal_id         = azurerm_user_assigned_identity.aks_identity.principal_id
  role_definition_name = "Private DNS Zone Contributor"
  scope                = var.rg_id
}


# AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                              = "${var.prefix}-aks-cluster"
  location                          = var.rg_location
  resource_group_name               = var.rg_name
  kubernetes_version                = var.aks_version
  sku_tier                          = "Free"
  private_cluster_enabled           = true
  dns_prefix                        = "aks-demo"
  private_dns_zone_id               = azurerm_private_dns_zone.private_dns_aks.id
  oidc_issuer_enabled               = true
  role_based_access_control_enabled = true
  # open_service_mesh_enabled         = true

  default_node_pool {
    name                 = "system"
    vm_size              = var.aks_vm_size
    vnet_subnet_id       = var.private_subnet_id[0]
    node_count           = 1
    auto_scaling_enabled = true
    min_count            = 1
    max_count            = 3
  }

  # auto_scaler_profile {
  # }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks_identity.id]
  }

  network_profile {
    network_plugin     = "azure" # kubenet
    network_policy     = "azure" # "calico"
    network_data_plane = "azure"
    load_balancer_sku  = "standard"
    # outbound_type    = "userDefinedRouting" # "loadBalancer"
  }


  # ingress_application_gateway {
  #   gateway_id = azurerm_application_gateway.aks_agw.id
  # }

  # service_mesh_profile {
  #   mode      = "Istio"
  #   revisions = ["asm-1-21"]
  # }

  # workload_autoscaler_profile {
  #   keda_enabled                    = true
  #   vertical_pod_autoscaler_enabled = true
  # }

  # api_server_access_profile {
  #   authorized_ip_ranges = "198.51.100.0/24"
  # }

  lifecycle {
    ignore_changes = [
      auto_scaler_profile
    ]
  }

  depends_on = [
    azurerm_role_assignment.aks_identity_role
  ]
}

# User node pool
resource "azurerm_kubernetes_cluster_node_pool" "user_pool" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = var.aks_vm_size
  node_count            = 1
  mode                  = "User"
  vnet_subnet_id        = var.private_subnet_id[1]

  auto_scaling_enabled = true
  min_count            = 1
  max_count            = 3
}

# Application Gateway
# resource "azurerm_public_ip" "agw_public_ip" {
#   name                = "${var.prefix}-agw-public-ip"
#   location            = var.rg_location
#   resource_group_name = var.rg_name
#   allocation_method   = "Static"
#   sku                 = "Standard"

#   tags = {
#     Name  = "${var.prefix}-agw-public-ip"
#     Owner = var.owner
#   }
# }

# locals {
#   backend_address_pool_name      = "${var.prefix}-beap"
#   frontend_port_name             = "${var.prefix}-feport"
#   frontend_ip_configuration_name = "${var.prefix}-feip"
#   http_setting_name              = "${var.prefix}-be-htst"
#   listener_name                  = "${var.prefix}-httplstn"
#   request_routing_rule_name      = "${var.prefix}-rqrt"
#   redirect_configuration_name    = "${var.prefix}-rdrcfg"
# }

# resource "azurerm_application_gateway" "aks_agw" {
#   name                = "${var.prefix}-aks-agw"
#   location            = var.rg_location
#   resource_group_name = var.rg_name

#   sku {
#     name     = "Standard_v2"
#     tier     = "Standard_v2"
#     capacity = 2
#   }

#   gateway_ip_configuration {
#     name      = "${var.prefix}-gwip-config"
#     subnet_id = var.public_subnet_id[1]
#   }

#   frontend_port {
#     name = local.frontend_port_name
#     port = 80
#   }

#   frontend_ip_configuration {
#     name                 = local.frontend_ip_configuration_name
#     public_ip_address_id = azurerm_public_ip.agw_public_ip.id
#   }

#   backend_address_pool {
#     name = local.backend_address_pool_name
#   }

#   backend_http_settings {
#     name                  = local.http_setting_name
#     cookie_based_affinity = "Disabled"
#     path                  = "/path1/"
#     port                  = 80
#     protocol              = "Http"
#     request_timeout       = 60
#   }

#   http_listener {
#     name                           = local.listener_name
#     frontend_ip_configuration_name = local.frontend_ip_configuration_name
#     frontend_port_name             = local.frontend_port_name
#     protocol                       = "Http"
#   }

#   request_routing_rule {
#     name                       = local.request_routing_rule_name
#     priority                   = 9
#     rule_type                  = "Basic"
#     http_listener_name         = local.listener_name
#     backend_address_pool_name  = local.backend_address_pool_name
#     backend_http_settings_name = local.http_setting_name
#   }
# }