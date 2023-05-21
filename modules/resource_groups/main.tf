resource "azurerm_resource_group" "poc" {
  for_each = var.resource_groups

  location = "UK South"
  name     = each.key
  tags     = var.tags
}

resource "azurerm_storage_account" "poc" {
  for_each = var.resource_groups

  account_replication_type = "GRS"
  account_tier             = "Standard"
  location                 = azurerm_resource_group.poc[each.key].location
  name                     = "fabrik${azurerm_resource_group.poc[each.key].name}"
  resource_group_name      = azurerm_resource_group.poc[each.key].name
  tags                     = var.tags
}

resource "azurerm_storage_container" "poc" {
  for_each = var.resource_groups

  container_access_type = "container"
  name                  = "terraform-state"
  storage_account_name  = azurerm_storage_account.poc[each.key].name
}
