resource "azurerm_key_vault" "kv" {
  name                      = local.key_vault_name
  resource_group_name       = data.azurerm_kubernetes_cluster.aks.resource_group_name
  location                  = data.azurerm_kubernetes_cluster.aks.location
  enable_rbac_authorization = true
  sku_name                  = "standard"
  tenant_id                 = data.azurerm_client_config.current.tenant_id
}

resource "azurerm_role_assignment" "key_vault_admin" {
  role_definition_name = "Key Vault Administrator"
  scope                = azurerm_key_vault.kv.id
  principal_id         = var.cluster_writer_aad_object_id
}

resource "azurerm_role_assignment" "key_vault_secrets_user" {
  role_definition_name = "Key Vault Secrets User"
  scope                = azurerm_key_vault.kv.id
  principal_id         = azurerm_user_assigned_identity.workload_identity.principal_id
}

resource "azurerm_key_vault_secret" "test_secret" {
  name         = "secret"
  value        = "supersecretvalue"
  key_vault_id = azurerm_key_vault.kv.id
  depends_on = [
    azurerm_role_assignment.key_vault_admin
  ]
}