
resource "azurerm_storage_account" "storage_account" {
  name                            = var.storage_name_I
  resource_group_name             = var.rg_name_I
  location                        = var.location_I
  account_tier                    = var.account_tier_I
  account_replication_type        = var.replication_type_I
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true

  # Configure Azure Files identity with on-prem Active Directory.
  azure_files_authentication {
    directory_type = "AD"
    active_directory {
      domain_name         = var.domain_name_I
      domain_guid         = var.domain_guid_I
      domain_sid          = var.domain_sid_I
      forest_name         = var.forest_name_I
      netbios_domain_name = var.netbios_domain_name_I
      storage_sid         = var.storage_sid_I
    }
  }

  tags = {
    Environment = var.env_I
  }
}
