output "StorageAccountName_I" {
  value = azurerm_storage_account.storage_account.name
}

output "StorageAccountID_I" {
  value = azurerm_storage_account.storage_account.id
}

output "StorageAccountPrimaryAccessKey_I" {
  value     = azurerm_storage_account.storage_account.primary_access_key
  sensitive = true
}
