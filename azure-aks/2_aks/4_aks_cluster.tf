# Name: aks_cluster.tf
# Owner: Saurav Mitra
# Description: This terraform config will create AKS Cluster

resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                                = "${var.prefix}-aks-cluster"
  location                            = var.rg_location
  resource_group_name                 = var.rg_name
  kubernetes_version                  = var.aks_version
  sku_tier                            = var.aks_sku_tier
  support_plan                        = var.aks_support_plan
  private_cluster_enabled             = true
  private_cluster_public_fqdn_enabled = false
  dns_prefix_private_cluster          = "aks-demo"
  private_dns_zone_id                 = azurerm_private_dns_zone.private_dns_aks.id
  role_based_access_control_enabled   = true # Kubernetes RBAC
  oidc_issuer_enabled                 = true
  local_account_disabled              = false # When true, enable role_based_access_control_enabled & azure_active_directory_role_based_access_control
  # dns_prefix                        = "aks-demo"
  # Enable Azure AD/Microsoft Entra Workload Identity
  workload_identity_enabled = false # When true, oidc_issuer_enabled must be true
  automatic_upgrade_channel = "patch"
  node_os_upgrade_channel   = "NodeImage"
  node_resource_group       = "rg-aks-node"

  identity {
    type         = "UserAssigned" # SystemAssigned
    identity_ids = [azurerm_user_assigned_identity.aks_identity.id]
  }

  kubelet_identity {
    client_id                 = azurerm_user_assigned_identity.kubelet_identity.client_id
    object_id                 = azurerm_user_assigned_identity.kubelet_identity.principal_id
    user_assigned_identity_id = azurerm_user_assigned_identity.kubelet_identity.id
  }

  network_profile {
    # network_plugin     = "azure" # kubenet
    # network_policy     = "azure" # "calico"/"cilium"
    # network_data_plane = "azure"
    network_plugin    = "kubenet"
    load_balancer_sku = "standard"     # basic
    outbound_type     = "loadBalancer" # "userDefinedRouting"

    # allows for more control over egress traffic in the future
    # load_balancer_profile {
    #   outbound_ip_address_ids = [azurerm_public_ip.aks_outbound_ip.id]
    # }
  }

  # api_server_access_profile {
  #   authorized_ip_ranges = "198.51.100.0/24" # API server access from Authorized IP ranges
  # }


  default_node_pool {
    name                         = "system"
    type                         = "VirtualMachineScaleSets"
    vm_size                      = var.aks_vm_size
    vnet_subnet_id               = var.private_subnet_id[1]
    zones                        = [1, 2, 3]
    node_count                   = 3
    auto_scaling_enabled         = true # Enable Cluster Autoscaler
    min_count                    = 3
    max_count                    = 5
    temporary_name_for_rotation  = "tempsystem" # Temporary node pool name used to cycle the default node pool for VM resizing
    only_critical_addons_enabled = false

    node_labels = {
      "worker-name" = "system"
    }
  }

  # Cluster Autoscaler Config
  # auto_scaler_profile {
  # }



  # Enable Application Gateway Ingress controller Addon
  ingress_application_gateway {
    gateway_id = azurerm_application_gateway.aks_agw.id
  }

  # Enable HTTP Application Routing
  # http_application_routing_enabled = false

  # Application Routing NGINX Ingress controller Addon
  # web_app_routing {
  #   dns_zone_ids = [azurerm_private_dns_zone.private_dns_aks.id]
  # }


  # Enable Storage Addon
  storage_profile {
    blob_driver_enabled         = false
    disk_driver_enabled         = true
    file_driver_enabled         = true
    snapshot_controller_enabled = true
  }

  # Enable Azure Key Vault provider for Secrets Store CSI Driver
  key_vault_secrets_provider {
    secret_rotation_enabled = true
    # secret_rotation_interval = 2m
  }


  # Enable KEDA & VPA
  workload_autoscaler_profile {
    keda_enabled                    = true
    vertical_pod_autoscaler_enabled = true
  }


  # Enable Open Service Mesh
  open_service_mesh_enabled = false

  # Enable Istio Service Mesh
  # service_mesh_profile {
  #   mode                             = "Istio"
  #   revisions                        = ["asm-1-21"]
  #   internal_ingress_gateway_enabled = true
  #   external_ingress_gateway_enabled = true
  # }


  # Enable Cost Analysis
  cost_analysis_enabled = false # When true, sku_tier must be Standard or Premium

  # Enable Image Cleaner
  image_cleaner_enabled = false

  # Enable Azure Open Policy Agent Addon
  azure_policy_enabled = false

  # Enable Microsoft Defender for Containers
  # microsoft_defender {
  #   log_analytics_workspace_id = azurerm_log_analytics_solution.main.id
  # }

  # Enable Prometheus Addon profile
  # monitor_metrics {
  #   annotations_allowed = []
  #   labels_allowed      = []
  # }

  # Enable Azure Monitor Agent
  # oms_agent {
  #   log_analytics_workspace_id      = azurerm_log_analytics_solution.main.id
  #   msi_auth_for_monitoring_enabled = false
  # }


  # AKS-managed Azure AD integration
  # azure_active_directory_role_based_access_control {
  #   tenant_id              = data.azurerm_client_config.current.tenant_id
  #   azure_rbac_enabled     = true
  #   admin_group_object_ids = []
  #   managed                = true
  # }


  tags = {
    Name  = "${var.prefix}-aks-cluster"
    Owner = var.owner
  }

  lifecycle {
    ignore_changes = [
      auto_scaler_profile,
      default_node_pool
    ]
  }

  depends_on = [
    azurerm_role_assignment.aks_identity_dns_role,
    azurerm_role_assignment.kubelet_role_assignment,
    azurerm_role_assignment.aks_identity_rg_role,
  ]
}


/*
# User node pool
resource "azurerm_kubernetes_cluster_node_pool" "user_pool" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks_cluster.id
  vm_size               = var.aks_vm_size
  vnet_subnet_id        = var.private_subnet_id[2]
  zones                 = [1, 2, 3]
  node_count            = 1
  auto_scaling_enabled  = true
  min_count             = 1
  max_count             = 3
  mode                  = "User"

  node_labels = {
    "worker-name" = "user"
  }
}
*/


/*
## Flux
resource "azurerm_kubernetes_cluster_extension" "flux" {
  name           = "flux-extension"
  cluster_id     = azurerm_kubernetes_cluster.aks_cluster.id
  extension_type = "microsoft.flux"
}

resource "azurerm_kubernetes_flux_configuration" "flux" {
  name       = "cluster-config"
  cluster_id = azurerm_kubernetes_cluster.aks_cluster.id
  namespace  = "cluster-config"
  scope      = "cluster"

  git_repository {
    url             = "https://github.com/Azure/gitops-flux2-kustomize-helm-mt"
    reference_type  = "branch"
    reference_value = "main"
  }

  kustomizations {
    name                       = "infra"
    path                       = "./infrastructure"
    garbage_collection_enabled = true
  }

  kustomizations {
    name                       = "apps"
    path                       = "./apps/staging"
    garbage_collection_enabled = true
    depends_on                 = ["infra"]
  }

  depends_on = [
    azurerm_kubernetes_cluster_extension.flux
  ]
}
*/
