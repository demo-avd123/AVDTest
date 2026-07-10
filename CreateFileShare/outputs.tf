output "FileShareName_I" {
  value = azurerm_storage_share.fileshare.name
}

output "FileShareQuota_I" {
  value = azurerm_storage_share.fileshare.quota
}
