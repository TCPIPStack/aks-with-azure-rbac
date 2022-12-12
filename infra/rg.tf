resource "azurerm_resource_group" "aks_rg" {
  name     = var.resource_group_name
  location = var.location
}