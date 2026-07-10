resource "azurerm_virtual_desktop_host_pool_registration_info" "registrationinfo" {
  hostpool_id     = var.hostpool_id_I
  expiration_date = var.expiration_date_I
}
