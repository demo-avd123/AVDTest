resource "azurerm_virtual_desktop_workspace" "workspace" {
  name                = var.workspace_name_I
  resource_group_name = var.rg_name_I
  location            = var.location_I
  friendly_name       = var.workspace_name_friendly_name_I
  tags = merge(var.tags_I, {
    cm-resource-parent = "/subscriptions/${var.subscription_id_I}/resourceGroups/${var.rg_name_I}/providers/Microsoft.DesktopVirtualization/workspaces/${var.workspace_name_I}"
  })
}

resource "azurerm_virtual_desktop_workspace_application_group_association" "ws_dag_association" {
  application_group_id = var.app_group_id_I
  workspace_id         = azurerm_virtual_desktop_workspace.workspace.id
}
