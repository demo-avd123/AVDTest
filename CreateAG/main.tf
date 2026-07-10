resource "azurerm_virtual_desktop_application_group" "app_group" {
  resource_group_name = var.rg_name_I
  host_pool_id        = var.hostpool_id_I
  location            = var.location_I
  type                = var.app_group_type_I
  name                = var.app_group_name_I
  friendly_name       = var.app_group_friendly_name_I
  tags = merge(var.tags_I, {
    cm-resource-parent = "/subscriptions/${var.subscription_id_I}/resourceGroups/${var.rg_name_I}/providers/Microsoft.DesktopVirtualization/applicationGroups/${var.app_group_name_I}"
  })
}
