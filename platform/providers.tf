terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.32.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.16.1"
    }
    random = {
      source = "hashicorp/random"
    }
  }

  backend "azurerm" {
    resource_group_name  = "tf-exercise-backend"
    storage_account_name = "bu4tfexercisebackend"
    container_name       = "tfstate"
    key                  = "k8s.tfstate"
  }
}

data "azurerm_client_config" "current" {
}

provider "azurerm" {
  features {}
}

data "azurerm_kubernetes_cluster" "aks" {
  name                = "aks"
  resource_group_name = "aks-azure-rbac"
}

provider "kubernetes" {
  # host                   = data.azurerm_kubernetes_cluster.aks.kube_config.0.host
  #   client_certificate     = base64decode(data.azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)
  #   client_key             = base64decode(data.azurerm_kubernetes_cluster.aks.kube_config.0.client_key)
  # cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
  config_path = "~/.kube/config"
  #   exec {
  #     api_version = "client.authentication.k8s.io/v1beta1"
  #     command     = "kubelogin"
  #     args = [
  #       "convert-kubeconfig",
  #       "--login",
  #       "spn",
  #       "--environment",
  #       "AzurePublicCloud",
  #       "--tenant-id",
  #       data.azurerm_kubernetes_cluster.aks.azure_active_directory_role_based_access_control[0].tenant_id,
  #       "--server-id",
  #       data.azuread_service_principal.aks.application_id,
  #       "--client-id",
  #       data.azurerm_key_vault_secret.id.value,
  #       "--client-secret",
  #       data.azurerm_key_vault_secret.secret.value
  #     ]
  #   }
}


data "kubernetes_all_namespaces" "allns" {}

output "all-ns" {
  value = data.kubernetes_all_namespaces.allns.namespaces
}
