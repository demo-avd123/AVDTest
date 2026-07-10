resource "azurerm_storage_share" "fileshare" {
  name               = var.fileshare_name_I
  storage_account_id = var.storage_account_id_I
  quota              = var.quota_I
}
