resource "azurerm_virtual_desktop_host_pool" "hostpool" {
  name                             = var.hostpool_name_I
  location                         = var.location_I
  resource_group_name              = var.rg_name_I
  type                             = var.hostpool_type_I
  load_balancer_type               = var.load_balancer_type_I
  maximum_sessions_allowed         = var.max_sessions_I
  preferred_app_group_type         = var.app_group_type_I
  start_vm_on_connect              = var.start_vm_on_connect_I
  validate_environment             = var.validate_env_I
  personal_desktop_assignment_type = var.personal_desktop_assignment_type_I
  custom_rdp_properties            = var.custom_rdp_properties_I
  tags = merge(var.tags_I, {
    cm-resource-parent = "/subscriptions/${var.subscription_id_I}/resourceGroups/${var.rg_name_I}/providers/Microsoft.DesktopVirtualization/hostPools/${var.hostpool_name_I}"
  })
}
