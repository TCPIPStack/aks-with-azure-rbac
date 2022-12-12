terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.32.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "tf-exercise-backend"
    storage_account_name = "bu4tfexercisebackend"
    container_name       = "tfstate"
    key                  = "aks-rbac.tfstate"
  }
}

provider "azurerm" {
  features {

  }
}

data "azurerm_client_config" "current" {
}

