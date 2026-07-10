# Storage Account module supporting OnPrem AD (UC1) and AADKERB (UC2) identity.
# storage_identity_type_I = "AD"      → On-premises AD authentication (UC1)
# storage_identity_type_I = "AADKERB" → Azure AD Kerberos authentication (UC2)

resource "azurerm_storage_account" "storage_account" {
  name                            = var.storage_name_I
  resource_group_name             = var.rg_name_I
  location                        = var.location_I
  account_tier                    = var.account_tier_I
  account_replication_type        = var.replication_type_I
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true
  default_to_oauth_authentication = true

  # OnPrem AD authentication (UC1)
  dynamic "azure_files_authentication" {
    for_each = var.storage_identity_type_I == "AD" ? [1] : []
    content {
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
  }

  # Azure AD Kerberos authentication (UC 2,3,5,7,8)
  # active_directory sub-block is only required in hybrid scenarios (domain_name/domain_guid present)
  dynamic "azure_files_authentication" {
    for_each = var.storage_identity_type_I == "AADKERB" ? [1] : []
    content {
      directory_type = "AADKERB"
      dynamic "active_directory" {
        for_each = var.domain_name_I != null && var.domain_guid_I != null ? [1] : []
        content {
          domain_name = var.domain_name_I
          domain_guid = var.domain_guid_I
        }
      }
      default_share_level_permission = var.share_level_permission_I
    }
  }

  # Prevent Terraform from reverting azure_files_authentication after
  # the Join-AzStorageAccount script updates storage_sid in Azure.
  lifecycle {
    ignore_changes = [azure_files_authentication]
  }

  tags = merge(var.tags_I, {
    cm-resource-parent = "/subscriptions/${var.subscription_id_I}/resourceGroups/${var.rg_name_I}/providers/Microsoft.Storage/storageAccounts/${var.storage_name_I}"
  })
}
