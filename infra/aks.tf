resource "azurerm_kubernetes_cluster" "aks" {
  name                              = var.aks_name
  resource_group_name               = azurerm_resource_group.aks_rg.name
  location                          = azurerm_resource_group.aks_rg.location
  dns_prefix                        = "dns-${var.aks_name}"
  role_based_access_control_enabled = true
  oidc_issuer_enabled               = true
  workload_identity_enabled         = true
  local_account_disabled            = true

  default_node_pool {
    name       = "system"
    vm_size    = "Standard_B2s"
    node_count = "1"
  }

  identity {
    type = "SystemAssigned"
  }

  azure_active_directory_role_based_access_control {
    managed                = true
    azure_rbac_enabled     = true
    admin_group_object_ids = [data.azurerm_client_config.current.object_id]
  }

  network_profile {
    network_plugin = "kubenet"
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = false
  }
}

resource "azurerm_role_assignment" "cluster_admin" {
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  scope                = azurerm_kubernetes_cluster.aks.id
  principal_id         = data.azurerm_client_config.current.object_id
}