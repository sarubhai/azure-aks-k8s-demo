# Name: aks_identity.tf
# Owner: Saurav Mitra
# Description: This terraform config will create Managed Identity for AKS Cluster

# AKS UserAssigned Managed Identity
resource "azurerm_user_assigned_identity" "aks_identity" {
  name                = "aks-identity"
  location            = var.rg_location
  resource_group_name = var.rg_name
}
# resource_id = azurerm_user_assigned_identity.aks_identity.id
# principal_id = azurerm_user_assigned_identity.aks_identity.principal_id

# Role Assignment for Private DNS
resource "azurerm_role_assignment" "aks_identity_dns_role" {
  principal_id         = azurerm_user_assigned_identity.aks_identity.principal_id
  role_definition_name = "Private DNS Zone Contributor"
  scope                = azurerm_private_dns_zone.private_dns_aks.id
}

resource "azurerm_role_assignment" "aks_identity_rg_role" {
  principal_id         = azurerm_user_assigned_identity.aks_identity.principal_id
  role_definition_name = "Contributor"
  scope                = var.rg_id
}

resource "azurerm_role_assignment" "cluster_admin" {
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  scope                = azurerm_kubernetes_cluster.aks_cluster.id
}

# KV: Key Vault Secrets User
resource "azurerm_role_assignment" "aks_kv_secrets_role" {
  principal_id         = azurerm_user_assigned_identity.aks_identity.principal_id
  role_definition_name = "Key Vault Secrets User" # Key Vault Administrator
  scope                = azurerm_key_vault.aks_kv.id
}


# Kubelet UserAssigned Managed Identity
resource "azurerm_user_assigned_identity" "kubelet_identity" {
  name                = "kubelet-identity"
  location            = var.rg_location
  resource_group_name = var.rg_name
}

# Role Assignment for Kubelet Identity
resource "azurerm_role_assignment" "kubelet_role_assignment" {
  principal_id         = azurerm_user_assigned_identity.aks_identity.principal_id
  scope                = azurerm_user_assigned_identity.kubelet_identity.id
  role_definition_name = "Managed Identity Operator"
}

# Container Registry: AcrPull
resource "azurerm_role_assignment" "kubelet_identity_acr_role" {
  principal_id         = azurerm_user_assigned_identity.kubelet_identity.principal_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.aks_acr.id
}

# Application Gateway
resource "azurerm_role_assignment" "agic" {
  principal_id         = azurerm_kubernetes_cluster.aks_cluster.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
  role_definition_name = "Contributor"
  scope                = var.rg_id
}

resource "azurerm_user_assigned_identity" "agw_identity" {
  name                = "agw-identity"
  location            = var.rg_location
  resource_group_name = var.rg_name
}

resource "azurerm_role_assignment" "agw_secret_user" {
  principal_id         = azurerm_user_assigned_identity.agw_identity.principal_id
  role_definition_name = "Key Vault Secrets User"
  scope                = azurerm_key_vault.aks_kv.id
}
