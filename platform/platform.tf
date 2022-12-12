
resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
  numeric = false
}

locals {
  namespace_name          = "app"
  sa_name                 = "workload-identity-sa"
  spc_name                = "azure-kvname-workload-identity"
  fererated_identity_name = "aksfederatedidentity"
  key_vault_name          = "key-vault-${random_string.suffix.result}"
}

resource "kubernetes_namespace" "app1" {
  metadata {
    name = local.namespace_name
  }
}

resource "azurerm_user_assigned_identity" "workload_identity" {
  name                = "workload-identity-${local.namespace_name}"
  resource_group_name = data.azurerm_kubernetes_cluster.aks.resource_group_name
  location            = data.azurerm_kubernetes_cluster.aks.location
}

resource "azurerm_federated_identity_credential" "fererated_identity" {
  name                = local.fererated_identity_name
  resource_group_name = data.azurerm_kubernetes_cluster.aks.resource_group_name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = data.azurerm_kubernetes_cluster.aks.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.workload_identity.id
  subject             = "system:serviceaccount:${local.namespace_name}:${local.sa_name}"
}

resource "kubernetes_service_account" "sa" {
  metadata {
    annotations = {
      "azure.workload.identity/client-id" = azurerm_user_assigned_identity.workload_identity.client_id
    }
    labels = {
      "azure.workload.identity/use" = true
    }
    name      = local.sa_name
    namespace = local.namespace_name
  }
}

resource "kubernetes_manifest" "secret_provider_class" {
  manifest = {
    apiVersion = "secrets-store.csi.x-k8s.io/v1"
    kind       = "SecretProviderClass"
    metadata = {
      name      = local.spc_name
      namespace = "${local.namespace_name}"
    }
    spec = {
      provider = "azure"
      parameters = {
        usePodIdentity       = false
        useVMManagedIdentity = false
        clientID             = azurerm_user_assigned_identity.workload_identity.client_id
        keyvaultName         = local.key_vault_name
        tenantId             = data.azurerm_client_config.current.tenant_id
        objects              = <<-EOT
          array:
            - |
              objectName: ${azurerm_key_vault_secret.test_secret.name}          
              objectType: secret
        EOT
      }
      secretObjects = [{
        secretName = azurerm_key_vault_secret.test_secret.name
        data = [{
          key        = "secret1"
          objectName = azurerm_key_vault_secret.test_secret.name
        }]
        type = "Opaque"
      }]
    }
  }
}

resource "kubernetes_pod" "test" {
  metadata {
    name      = "test"
    namespace = local.namespace_name
  }

  spec {
    service_account_name = local.sa_name
    container {
      image = "nginx:1.21.6"
      name  = "example"

      volume_mount {
        mount_path = "/mnt/secrets-store"
        name       = "secrets-store"
        read_only  = true
      }

      env {
        name = azurerm_key_vault_secret.test_secret.name
        value_from {
          secret_key_ref {
            name = azurerm_key_vault_secret.test_secret.name
            key  = "secret1"
          }
        }
      }

      port {
        container_port = 8080
      }
    }
    volume {
      name = "secrets-store"
      csi {
        driver    = "secrets-store.csi.k8s.io"
        read_only = true
        volume_attributes = {
          secretProviderClass = local.spc_name
        }
      }
    }
  }
}

# Assign customer to namespace
resource "azurerm_role_assignment" "rbac_writer" {
  role_definition_name = "Azure Kubernetes Service RBAC Writer"
  scope                = "${data.azurerm_kubernetes_cluster.aks.id}/namespace/${local.namespace_name}"
  principal_id         = var.cluster_writer_aad_object_id
}