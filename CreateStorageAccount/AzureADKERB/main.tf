resource "azurerm_storage_account" "storage_account" {
  name                            = var.storage_name_I
  resource_group_name             = var.rg_name_I
  location                        = var.location_I
  account_tier                    = var.account_tier_I
  account_replication_type        = var.replication_type_I
  allow_nested_items_to_be_public = false

  #  Explicitly declare shared key access is enabled for private blob downloads.
  shared_access_key_enabled = true

  #  Tell the provider to use Azure AD for data plane ops
  default_to_oauth_authentication = true

  azure_files_authentication {
    directory_type = var.directory_type_I
    active_directory {
      domain_name = var.domain_name_I
      domain_guid = var.domain_guid_I
    }
    default_share_level_permission = var.share_level_permission_I
  }
  tags = {
    Environment = var.env_I
  }
}


