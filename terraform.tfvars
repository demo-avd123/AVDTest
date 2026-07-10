# ===================================================================
# TERRAFORM CLOUD WORKSPACE VARIABLES TEMPLATE
# ===================================================================
# This file is intentionally commented-out.
#
# When using Terraform Cloud, set the values below in:
#   Workspace -> Variables -> Terraform variables
#
# Keep sensitive values marked Sensitive in Terraform Cloud.
# Do not keep real passwords or secrets in this file.
#
# Mandatory input guide:
#   - `REQUIRED`      -> always set in the workspace
#   - `CONDITIONAL`   -> set only when that feature/path is used
#   - `OPTIONAL`      -> keep default/null unless you need it
# ===================================================================

# ===================================================================
# COMMON — required for both UC1 and UC2
# ===================================================================
# REQUIRED: use_case                = 1          # 1 = ADDS + OnPrem AD storage (GPO)
#                                                 # 2 = ADDS + AADKERB storage (Registry Key)
# REQUIRED: azure_subscription_id_E = "<subscription-id>"
# REQUIRED: folllowNomenclature_E   = true
# REQUIRED: env_E                   = "P"
# REQUIRED: location_E              = "eastus"

# ===================================================================
# EXISTING RESOURCE GROUP
# Set existing_RGname to reuse an existing resource group.
# Leave newRGname_E unset when reusing an existing RG.
# ===================================================================
# REQUIRED when reusing RG: existing_RGname = "<existing-resource-group-name>"
# CONDITIONAL when creating RG: newRGname_E = "<new-rg-name>"

# ===================================================================
# EXISTING VIRTUAL NETWORK & SUBNET
# Set existing_vNet_name and existing_subnet to reuse existing network
# resources. Leave new VNet inputs unset when reusing them.
# ===================================================================
# REQUIRED when reusing network: existing_vNet_name = "<existing-vnet-name>"
# REQUIRED when reusing network: existing_subnet    = "<existing-subnet-name>"
# OPTIONAL: existing_vNet_address = []
# CONDITIONAL when creating VNet: vnet_name_E    = "<new-vnet-name>"
# CONDITIONAL when creating VNet: vnet_cidr_E    = ["10.0.0.0/16"]
# CONDITIONAL when creating VNet: subnet_names   = ["snet-avd"]
# CONDITIONAL when creating VNet: subnet_cidrs_E = ["10.0.0.0/24"]
# CONDITIONAL when creating VNet: dns_servers_E  = ["<domain-controller-ip>"]

# ===================================================================
# VNET PEERING
# ===================================================================
# OPTIONAL: enable_vnet_peering_E          = false
# CONDITIONAL: peer_vnet_name_E               = null
# CONDITIONAL: peer_vnet_id_E                 = null
# CONDITIONAL: peer_vnet_rg_E                 = null
# OPTIONAL: peer_allow_forwarded_traffic_E = true
# OPTIONAL: peer_allow_gateway_transit_E   = false
# OPTIONAL: peer_use_remote_gateways_E     = false

# ===================================================================
# STORAGE ACCOUNT
# Set existing_storage_account_name to reuse an existing storage account,
# or keep it null and provide storage_name_E to create a new one.
# ===================================================================
# OPTIONAL: existing_storage_account_name = null
# CONDITIONAL when creating storage: storage_name_E     = "<globally-unique-storage-name>"
# OPTIONAL: account_tier_E               = "Standard"
# OPTIONAL: replication_type_E           = "LRS"

# ===================================================================
# FILE SHARE
# ===================================================================
# REQUIRED: fileshare_name_E = "fslogix"
# OPTIONAL: quota_E          = 100

# ===================================================================
# ADDS DOMAIN JOIN
# ===================================================================
# REQUIRED: domain_name_E            = "<contoso.com>"
# REQUIRED: OUPath_E                 = "OU=AVD,DC=contoso,DC=com"
# REQUIRED: ad_admin_user_name_E     = "<admin@contoso.com>"
# REQUIRED: ad_admin_user_password_E = "<sensitive>"

# ===================================================================
# SESSION HOST VMS
# ===================================================================
# REQUIRED: sessionHost_name_E    = "<vm-prefix>"
# REQUIRED: sh_count_E            = 2
# REQUIRED: sku_E                 = "Standard_D4s_v5"
# REQUIRED: admin_username_E      = "<local-admin-user>"
# REQUIRED: admin_password_E      = "<sensitive>"
# REQUIRED: os_disk_st_acc_type_E = "Premium_LRS"
# REQUIRED: zone_E                = 1
# REQUIRED: encryption_E          = false
# REQUIRED: secure_boot_E         = true
# REQUIRED: vtpm_E                = true

# ===================================================================
# IMAGE
# ===================================================================
# REQUIRED: use_custom_image_E = false
# CONDITIONAL when use_custom_image_E = false: image_publisher_E = "microsoftwindowsdesktop"
# CONDITIONAL when use_custom_image_E = false: image_offer_E     = "windows-11"
# CONDITIONAL when use_custom_image_E = false: image_sku_E       = "win11-24h2-avd"
# CONDITIONAL when use_custom_image_E = false: image_version_E   = "latest"
# CONDITIONAL when use_custom_image_E = true: image_gallery_name_E    = "<gallery-name>"
# CONDITIONAL when use_custom_image_E = true: image_gallery_rg_E      = "<gallery-rg>"
# CONDITIONAL when use_custom_image_E = true: image_definition_name_E = "<image-definition>"
# OPTIONAL: image_gallery_version_E = "latest"

# ===================================================================
# AUTO-SHUTDOWN
# ===================================================================
# OPTIONAL: auto_shutdown_enabled_E  = false
# CONDITIONAL when auto_shutdown_enabled_E = true: auto_shutdown_time_E     = "1900"
# CONDITIONAL when auto_shutdown_enabled_E = true: auto_shutdown_timezone_E = "UTC"

# ===================================================================
# HOST POOL
# ===================================================================
# REQUIRED: hostpool_name_E                    = "<hostpool-name>"
# REQUIRED: hostpool_type_E                    = "Pooled"
# OPTIONAL: personal_desktop_assignment_type_E = "Automatic"
# REQUIRED: load_balancer_type_E               = "BreadthFirst"
# REQUIRED: max_sessions_E                     = 4
# REQUIRED: start_vm_on_connect_E              = true
# OPTIONAL: validate_env_E                     = false

# ===================================================================
# APPLICATION GROUP
# ===================================================================
# REQUIRED: app_group_type_E          = "Desktop"
# REQUIRED: app_group_name_E          = "<appgroup-name>"
# REQUIRED: app_group_friendly_name_E = "<App Group Friendly Name>"

# ===================================================================
# WORKSPACE
# ===================================================================
# REQUIRED: workspace_name_E               = "<workspace-name>"
# REQUIRED: workspace_name_friendly_name_E = "<Workspace Friendly Name>"

# ===================================================================
# REGISTRATION & TAGS
# ===================================================================
# OPTIONAL: expiration_date_E       = "2026-08-06T00:00:00Z"
# OPTIONAL: custom_rdp_properties_E = null
# OPTIONAL: custom_tags_E           = { Product = "AVD" }

# ===================================================================
# UC1-ONLY VARIABLES  (OnPrem AD storage)
# ===================================================================
# REQUIRED for UC1: domain_guid_E         = "<xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx>"
# REQUIRED for UC1: domain_sid_E          = "S-1-5-21-<domain-sid>"
# REQUIRED for UC1: forest_name_E         = "<contoso.com>"
# REQUIRED for UC1: netbios_domain_name_E = "CONTOSO"
# OPTIONAL for UC1: storage_sid_E         = "S-1-5-21-<storage-computer-account-sid>"

# ===================================================================
# UC2-ONLY VARIABLES  (AADKERB storage)
# ===================================================================
# OPTIONAL for UC2: share_level_permission_E = "StorageFileDataSmbShareContributor"
