resource "azurerm_resource_group" "newRG" {
  name     = var.rg_name_I
  location = var.location_I
  tags = merge(var.tags_I, {
    cm-resource-parent = "/subscriptions/${var.subscription_id_I}/resourceGroups/${var.rg_name_I}"
  })
}
