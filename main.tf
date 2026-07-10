// TERRAFORM & PROVIDER CONFIGURATION
// ===================================================================

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=4.50.0"
    }
  }
}

provider "azurerm" {
  subscription_id     = var.azure_subscription_id_E
  storage_use_azuread = true
  features {}
}

// ===================================================================
// LOCAL VALUES - USE CASE DRIVEN CONDITIONAL LOGIC
// ===================================================================
//
// Use Case Matrix:
// UC | Session Host Join | FSLogix | Storage Identity    | FSLogix Config
// 1  | ADDS              | yes     | AD (OnPrem)         | GPO
// 2  | ADDS              | yes     | AADKERB             | Registry Key

locals {
  // ---- Session host join type ----
  // UC1 and UC2 are both ADDS-joined
  session_host_join_type = "ADDS"

  // ---- FSLogix enablement ----
  // UC1 and UC2 both use FSLogix
  enable_fslogix     = true
  create_new_storage = var.existing_storage_account_name == null

  // ---- Storage identity type ----
  // UC1 = on-prem AD, UC2 = Azure AD Kerberos
  storage_identity_type = var.use_case == 1 ? "AD" : "AADKERB"

  // ---- FSLogix config method ----
  // UC1 = GPO, UC2 = RegistryKey
  fslogix_config_method = var.use_case == 1 ? "GPO" : "RegistryKey"

  // ---- Derived booleans ----
  use_adds_join         = true
  use_onprem_ad_storage = var.use_case == 1
  use_aadkerb_storage   = var.use_case == 2

  // ---- Naming helpers ----
  prefix = lookup(var.prefix_E, lower(replace(var.location_E, " ", "")))

  // Storage account reference (only when FSLogix is enabled)
  avd_storage_account_name = local.create_new_storage ? module.create-storage-account[0].StorageAccountName_I : (
    local.enable_fslogix ? var.existing_storage_account_name : null
  )
  avd_storage_account_id = local.create_new_storage ? module.create-storage-account[0].StorageAccountID_I : (
    local.enable_fslogix ? data.azurerm_storage_account.existing[0].id : null
  )

  // File share name (computed once for reuse) — must be all lowercase for Azure Storage Share
  fileshare_name = var.fileshare_name_E != null ? (var.folllowNomenclature_E ? lower("${local.prefix}-${var.env_E}-${var.fileshare_name_E}") : lower(var.fileshare_name_E)) : null

  // Resource group name (new or existing)
  rg_name = var.existing_RGname != null ? var.existing_RGname : module.createRG[0].NewRGName

  // Subnet ID (new or existing)
  subnet_id = var.existing_vNet_name != null ? (
    "/subscriptions/${var.azure_subscription_id_E}/resourceGroups/${local.rg_name}/providers/Microsoft.Network/virtualNetworks/${var.existing_vNet_name}/subnets/${var.existing_subnet}"
  ) : module.create-vNet[0].subnet_details[0].id

  // Common tags merged with user-defined custom tags (cm-resource-parent is set per-resource in each module)
  common_tags = merge(
    {
      CreationTimeUTC = timestamp()
      Environment     = var.env_E
      ServiceWorkload = "AVD"
    },
    var.custom_tags_E
  )

  // RDP properties — UC1 and UC2 are ADDS-joined; no Entra RDP properties needed
  rdp_properties_base = ""

  // Merge auto-derived RDP properties with any user-supplied custom ones
  _rdp_user             = var.custom_rdp_properties_E != null ? var.custom_rdp_properties_E : ""
  custom_rdp_properties = local.rdp_properties_base != "" && local._rdp_user != "" ? "${local.rdp_properties_base};${local._rdp_user}" : (local.rdp_properties_base != "" ? local.rdp_properties_base : local._rdp_user)
}

// ===================================================================
// RESOURCE GROUP
// ===================================================================

module "createRG" {
  source            = "./createRG"
  env_I             = var.env_E
  rg_name_I         = var.folllowNomenclature_E ? "${local.prefix}-${var.env_E}-${var.newRGname_E}" : var.newRGname_E
  location_I        = var.location_E
  subscription_id_I = var.azure_subscription_id_E
  tags_I            = local.common_tags
  count             = var.existing_RGname == null ? 1 : 0
}

// ===================================================================
// VIRTUAL NETWORK & SUBNET
// ===================================================================

module "create-vNet" {
  source                = "./createvnet"
  env_I                 = var.env_E
  prefix_I              = local.prefix
  folllowNomenclature_I = var.folllowNomenclature_E
  vnet_name_I           = var.folllowNomenclature_E ? "${local.prefix}-${var.env_E}-${var.vnet_name_E}" : var.vnet_name_E
  location_I            = var.location_E
  rg_name_I             = local.rg_name
  vnet_address_space_I  = var.vnet_cidr_E
  subnet_names_I        = var.subnet_names
  subnet_prefixes_I     = var.subnet_cidrs_E 
  dns_servers_I         = var.dns_servers_E
  subscription_id_I     = var.azure_subscription_id_E
  tags_I                = local.common_tags

  // VNet peering — enabled for UC 1 and UC 2 when peer details are provided
  enable_vnet_peering_I          = var.enable_vnet_peering_E
  peer_vnet_name_I               = var.peer_vnet_name_E
  peer_vnet_id_I                 = var.peer_vnet_id_E
  peer_vnet_rg_I                 = var.peer_vnet_rg_E
  peer_allow_forwarded_traffic_I = var.peer_allow_forwarded_traffic_E
  peer_allow_gateway_transit_I   = var.peer_allow_gateway_transit_E
  peer_use_remote_gateways_I     = var.peer_use_remote_gateways_E

  count      = var.existing_vNet_name == null ? 1 : 0
  depends_on = [module.createRG]
}

// ===================================================================
// EXISTING STORAGE ACCOUNT DATA SOURCE
// ===================================================================

data "azurerm_storage_account" "existing" {
  count               = local.enable_fslogix && var.existing_storage_account_name != null ? 1 : 0
  name                = var.existing_storage_account_name
  resource_group_name = local.rg_name
}

// ===================================================================
// STORAGE ACCOUNT (unified module, conditional on FSLogix)
// ===================================================================

module "create-storage-account" {
  count  = local.create_new_storage ? 1 : 0
  source = "./CreateStorageAccount"

  env_I              = var.env_E
  location_I         = var.location_E
  rg_name_I          = local.rg_name
  storage_name_I     = var.folllowNomenclature_E ? lower("${local.prefix}${var.env_E}${var.storage_name_E}") : lower(var.storage_name_E)
  account_tier_I     = var.account_tier_E
  replication_type_I = var.replication_type_E

  // Identity configuration driven by use case
  storage_identity_type_I = local.storage_identity_type

  // OnPrem AD fields (UC1 only)
  domain_name_I         = var.domain_name_E
  domain_guid_I         = var.domain_guid_E
  domain_sid_I          = var.domain_sid_E
  forest_name_I         = var.forest_name_E
  netbios_domain_name_I = var.netbios_domain_name_E
  storage_sid_I         = try(coalesce(var.storage_sid_E, var.domain_sid_E), null)

  // AADKERB fields (UC2)
  share_level_permission_I = var.share_level_permission_E
  subscription_id_I        = var.azure_subscription_id_E
  tags_I                   = local.common_tags

  depends_on = [module.createRG]
}

// ===================================================================
// FILE SHARE (conditional on FSLogix)
// ===================================================================

module "create-file-share" {
  source               = "./CreateFileShare"
  fileshare_name_I     = local.fileshare_name
  storage_account_id_I = local.avd_storage_account_id
  quota_I              = var.quota_E
  count                = local.create_new_storage ? 1 : 0
}

// ===================================================================
// AD-JOIN STORAGE ACCOUNT (UC1 only — runs Join-AzStorageAccount)
// Prerequisite: Run terraform from a domain-joined machine with
//   Az PowerShell logged in, RSAT AD tools, and AzFilesHybrid module.
// ===================================================================

resource "null_resource" "join_storage_to_ad" {
  count = local.use_onprem_ad_storage && local.create_new_storage ? 1 : 0

  triggers = {
    storage_account_id = local.avd_storage_account_id
  }

  provisioner "local-exec" {
    command     = "powershell -ExecutionPolicy Bypass -File \"${path.module}/scripts/join-storage-to-ad.ps1\" -ResourceGroupName \"${local.rg_name}\" -StorageAccountName \"${local.avd_storage_account_name}\" -SubscriptionId \"${var.azure_subscription_id_E}\" -OUDistinguishedName \"${var.OUPath_E}\""
    interpreter = ["cmd", "/C"]
  }

  depends_on = [module.create-storage-account, module.create-file-share]
}

// ===================================================================
// IMAGE GALLERY
// ===================================================================

# # # # module "create-image-gallery" {
# # # #   source     = "./CreateImageGallery"
# # # #   rg_name_I  = local.rg_name
# # # #   location_I = var.location_E
# # # #   env_I      = var.env_E

# # # #   depends_on = [module.createRG]
# # # # }

// ===================================================================
// SESSION HOST VMs
// ===================================================================

module "create-SessionHost" {
  source                = "./CreateSessionHosts"
  env_I                 = var.env_E
  prefix_I              = local.prefix
  folllowNomenclature_I = var.folllowNomenclature_E
  location_I            = var.location_E
  rg_name_I             = local.rg_name
  sessionHost_name_I    = var.sessionHost_name_E
  sh_count_I            = var.sh_count_E
  sku_I                 = var.sku_E
  admin_username_I      = var.admin_username_E
  admin_password_I      = var.admin_password_E
  os_disk_st_acc_type_I = var.os_disk_st_acc_type_E
  image_publisher_I     = var.image_publisher_E
  image_offer_I         = var.image_offer_E
  image_sku_I           = var.image_sku_E
  image_version_I       = var.image_version_E
  subnet_id_I           = local.subnet_id
  zone_I                = var.zone_E
  encryption_I          = var.encryption_E
  secure_boot_I         = var.secure_boot_E
  vtpm_I                = var.vtpm_E

  // Auto-shutdown
  auto_shutdown_enabled_I  = var.auto_shutdown_enabled_E
  auto_shutdown_time_I     = var.auto_shutdown_time_E
  auto_shutdown_timezone_I = var.auto_shutdown_timezone_E

  // Custom image from Azure Compute Gallery
  use_custom_image_I      = var.use_custom_image_E
  image_gallery_name_I    = var.image_gallery_name_E
  image_gallery_rg_I      = var.image_gallery_rg_E
  image_definition_name_I = var.image_definition_name_E
  image_gallery_version_I = var.image_gallery_version_E
  subscription_id_I       = var.azure_subscription_id_E
  tags_I                  = local.common_tags

  depends_on = [module.createRG, module.create-vNet]
}

// ===================================================================
// HOST POOL
// ===================================================================

module "create-hostpool" {
  source                             = "./CreateHostPool"
  env_I                              = var.env_E
  location_I                         = var.location_E
  rg_name_I                          = local.rg_name
  hostpool_name_I                    = var.folllowNomenclature_E ? "${local.prefix}-${var.env_E}-${var.hostpool_name_E}" :var.hostpool_name_E
  hostpool_type_I                    = var.hostpool_type_E
  personal_desktop_assignment_type_I = var.hostpool_type_E == "Personal" ? var.personal_desktop_assignment_type_E : null
  load_balancer_type_I               = var.hostpool_type_E == "Personal" ? "Persistent" : var.load_balancer_type_E
  max_sessions_I                     = var.max_sessions_E
  app_group_type_I                   = var.app_group_type_E
  start_vm_on_connect_I              = var.start_vm_on_connect_E
  validate_env_I                     = var.validate_env_E
  custom_rdp_properties_I            = local.custom_rdp_properties
  subscription_id_I                  = var.azure_subscription_id_E
  tags_I                             = local.common_tags

  depends_on = [module.createRG]
}

// ===================================================================
// APPLICATION GROUP (DAG)
// ===================================================================

module "create-App-Group" {
  source                    = "./CreateAG"
  env_I                     = var.env_E
  location_I                = var.location_E
  rg_name_I                 = local.rg_name
  hostpool_id_I             = module.create-hostpool.hostpool_id_I
  app_group_name_I          = var.folllowNomenclature_E ? "${local.prefix}-${var.env_E}-${var.app_group_name_E}" : var.app_group_name_E
  app_group_type_I          = var.app_group_type_E
  app_group_friendly_name_I = var.app_group_friendly_name_E
  subscription_id_I         = var.azure_subscription_id_E
  tags_I                    = local.common_tags
}

// ===================================================================
// WORKSPACE
// ===================================================================

module "create-workspace" {
  source                         = "./CreateWorkSpace"
  workspace_name_I               = var.folllowNomenclature_E ? "${local.prefix}-${var.env_E}-${var.workspace_name_E}" : var.workspace_name_E
  env_I                          = var.env_E
  location_I                     = var.location_E
  rg_name_I                      = local.rg_name
  workspace_name_friendly_name_I = var.workspace_name_friendly_name_E
  app_group_id_I                 = module.create-App-Group.app_group_id_I
  subscription_id_I              = var.azure_subscription_id_E
  tags_I                         = local.common_tags
}

// ===================================================================
// HOST POOL REGISTRATION INFO
// ===================================================================

module "host_pool_registration_info" {
  source            = "./CreateRegistrationInfo"
  hostpool_id_I     = module.create-hostpool.hostpool_id_I
  expiration_date_I = var.expiration_date_E
}

// ===================================================================
// EXTENSIONS (unified module handling all join types + FSLogix)
// ===================================================================

module "sessionHosts-Extensions" {
  source = "./DeployExtensions"

  // Session host info
  sessionHost_ID_I    = module.create-SessionHost.SessionHostVMs_Details_I[*].id
  sessionHost_names_I = module.create-SessionHost.SessionHostVMs_Details_I[*].name
  sh_count_I          = var.sh_count_E
  prefix_I            = local.prefix
  rg_name_I           = local.rg_name

  // AVD registration
  hostpool_name_I      = module.create-hostpool.hostpool_name_I
  registration_token_I = module.host_pool_registration_info.registration_token_I

  // Use case driven flags
  session_host_join_type_I = local.session_host_join_type
  enable_fslogix_I         = local.enable_fslogix
  fslogix_config_method_I  = local.fslogix_config_method

  // ADDS domain join params (UC 1, 2)
  domain_name_I            = var.domain_name_E
  OUPath_I                 = var.OUPath_E
  ad_admin_user_name_I     = var.ad_admin_user_name_E
  ad_admin_user_password_I = var.ad_admin_user_password_E

  // Storage info (for RBAC + FSLogix config)
  storage_account_id_I   = local.avd_storage_account_id
  storage_account_name_I = local.avd_storage_account_name
  file_share_name_I      = local.enable_fslogix ? local.fileshare_name : null

  // Use case number (for per-use-case conditional resources)
  use_case_I = var.use_case
}
