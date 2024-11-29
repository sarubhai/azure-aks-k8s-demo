# Name: outputs.tf
# Owner: Saurav Mitra
# Description: Outputs the AKS ARNs
# https://www.terraform.io/docs/configuration/outputs.html

output "cluster_name" {
  value       = "${var.prefix}-aks-cluster"
  description = "AKS cluster Name."
}

output "cluster_id" {
  value       = azurerm_kubernetes_cluster.aks_cluster.id
  description = "AKS cluster Id."
}

output "cluster_private_endpoint" {
  value       = azurerm_kubernetes_cluster.aks_cluster.private_fqdn
  description = "Endpoint for AKS control plane."
}

output "kube_config" {
  value       = azurerm_kubernetes_cluster.aks_cluster.kube_config_raw
  description = "Kubeconfig block for AKS cluster"
  sensitive   = true
}

output "client_certificate" {
  value       = azurerm_kubernetes_cluster.aks_cluster.kube_config[0].client_certificate
  description = "client certificate for AKS cluster"
  sensitive   = true
}

output "kubeconfig_ca_data" {
  value       = base64decode(azurerm_kubernetes_cluster.aks_cluster.kube_config[0].cluster_ca_certificate)
  description = "certificate-authority-data for AKS cluster"
  sensitive   = true
}
