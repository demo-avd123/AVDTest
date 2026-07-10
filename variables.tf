# ===================================================================
# USE CASE SELECTION
# ===================================================================
# Use case number (1 or 2) drives ALL conditional logic in this project.
# UC1: ADDS join, FSLogix, On-Prem AD storage (GPO config)
# UC2: ADDS join, FSLogix, AADKERB storage (Registry Key config)
# ===================================================================

variable "use_case" {
  type        = number
  description = "Use case number (1 or 2): UC1 = ADDS + OnPrem AD storage, UC2 = ADDS + AADKERB storage"

  validation {
    condition     = contains([1, 2], var.use_case)
    error_message = "use_case must be 1 or 2."
  }
}

# ===================================================================
# EXISTING RESOURCE VARIABLES
# ===================================================================

variable "existing_RGname" {
  type        = string
  description = "Name of an existing resource group. Set to null to create a new one."
  default     = null
}

variable "existing_vNet_name" {
  type        = string
  description = "Name of an existing virtual network. Set to null to create a new one."
  default     = null
}

variable "existing_vNet_address" {
  type        = list(string)
  description = "Address space for existing vNet. Example: [\"10.0.0.0/16\"]"
  default     = []
}

variable "existing_subnet" {
  type        = string
  description = "Name of an existing subnet."
  default     = null
}

// ---- VNet Peering (UC 1, 2 — peer new AVD VNet with an existing VNet) ----
variable "enable_vnet_peering_E" {
  type        = bool
  description = "Set to true to peer the new AVD VNet with an existing VNet. Applicable for UC 1 and UC 2."
  default     = false
}

variable "peer_vnet_name_E" {
  type        = string
  description = "Name of the existing remote VNet to peer with."
  default     = null
}

variable "peer_vnet_id_E" {
  type        = string
  description = "Full resource ID of the existing remote VNet. Format: /subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.Network/virtualNetworks/{name}"
  default     = null
}

variable "peer_vnet_rg_E" {
  type        = string
  description = "Resource group of the existing remote VNet."
  default     = null
}

variable "peer_allow_forwarded_traffic_E" {
  type        = bool
  description = "Allow forwarded traffic across the peering."
  default     = true
}

variable "peer_allow_gateway_transit_E" {
  type        = bool
  description = "Allow gateway transit (set true if remote VNet has a VPN/ExpressRoute gateway)."
  default     = false
}

variable "peer_use_remote_gateways_E" {
  type        = bool
  description = "Use remote VNet's gateway for routing."
  default     = false
}

variable "existing_storage_account_name" {
  type        = string
  description = "Name of an existing storage account. Set to null to create a new one."
  default     = null
}

# ===================================================================
# GENERAL VARIABLES
# ===================================================================

variable "azure_subscription_id_E" {
  type        = string
  description = "Azure Subscription ID"
}

variable "folllowNomenclature_E" {
  type        = bool
  description = "Whether to use naming convention. true or false."
}

variable "env_E" {
  type        = string
  description = "Environment name. Must be exactly 1 character. Example: 'T', 'D', 'P'"

  validation {
    condition     = length(var.env_E) == 1
    error_message = "env_E must be exactly 1 character (e.g. 'T', 'D', 'P')."
  }
}
variable "location_E" {
  type        = string
  description = "Azure region"
  validation {
    condition = contains([
      # Americas
      "eastus", "eastus2", "westus", "westus2", "westus3",
      "centralus", "northcentralus", "southcentralus", "westcentralus",
      "canadacentral", "canadaeast",
      "brazilsouth", "brazilsoutheast",
      "mexicocentral",
      # Europe
      "northeurope", "westeurope",
      "uksouth", "ukwest",
      "francecentral", "francesouth",
      "germanywestcentral", "germanynorth",
      "norwayeast", "norwaywest",
      "switzerlandnorth", "switzerlandwest",
      "swedencentral", "polandcentral",
      "italynorth", "spaincentral",
      # Asia Pacific
      "eastasia", "southeastasia",
      "australiaeast", "australiasoutheast", "australiacentral", "australiacentral2",
      "centralindia", "southindia", "westindia",
      "japaneast", "japanwest",
      "koreacentral", "koreasouth",
      "jioindiacentral", "jioindiawest",
      "newzealandnorth",
      # Middle East & Africa
      "southafricanorth", "southafricawest",
      "uaenorth", "uaecentral",
      "israelcentral", "qatarcentral"
    ], var.location_E)
    error_message = <<-EOT
      Invalid location. Select one of the 52 supported Azure regions:
        Americas    : eastus, eastus2, westus, westus2, westus3, centralus, northcentralus, southcentralus, westcentralus, canadacentral, canadaeast, brazilsouth, brazilsoutheast, mexicocentral
        Europe      : northeurope, westeurope, uksouth, ukwest, francecentral, francesouth, germanywestcentral, germanynorth, norwayeast, norwaywest, switzerlandnorth, switzerlandwest, swedencentral, polandcentral, italynorth, spaincentral
        Asia Pacific: eastasia, southeastasia, australiaeast, australiasoutheast, australiacentral, australiacentral2, centralindia, southindia, westindia, japaneast, japanwest, koreacentral, koreasouth, jioindiacentral, jioindiawest, newzealandnorth
        ME & Africa : southafricanorth, southafricawest, uaenorth, uaecentral, israelcentral, qatarcentral
    EOT
  }
}

variable "prefix_E" {
  type = map(any)
  default = {
    # Americas
    eastus             = "eus"
    eastus2            = "eu2"
    westus             = "wus"
    westus2            = "wu2"
    westus3            = "wu3"
    centralus          = "cus"
    northcentralus     = "ncu"
    southcentralus     = "scu"
    westcentralus      = "wcu"
    canadacentral      = "cac"
    canadaeast         = "cae"
    brazilsouth        = "brs"
    brazilsoutheast    = "bse"
    mexicocentral      = "mxc"
    # Europe
    northeurope        = "neu"
    westeurope         = "weu"
    uksouth            = "uks"
    ukwest             = "ukw"
    francecentral      = "frc"
    francesouth        = "frs"
    germanywestcentral = "gwc"
    germanynorth       = "grn"
    norwayeast         = "noe"
    norwaywest         = "now"
    switzerlandnorth   = "swn"
    switzerlandwest    = "sww"
    swedencentral      = "swc"
    polandcentral      = "plc"
    italynorth         = "itn"
    spaincentral       = "spc"
    # Asia Pacific
    eastasia           = "eas"
    southeastasia      = "sea"
    australiaeast      = "aue"
    australiasoutheast = "ase"
    australiacentral   = "auc"
    australiacentral2  = "ac2"
    centralindia       = "cin"
    southindia         = "sin"
    westindia          = "win"
    japaneast          = "jpe"
    japanwest          = "jpw"
    koreacentral       = "koc"
    koreasouth         = "kos"
    jioindiacentral    = "jic"
    jioindiawest       = "jiw"
    newzealandnorth    = "nzn"
    # Middle East & Africa
    southafricanorth   = "san"
    southafricawest    = "saw"
    uaenorth           = "uan"
    uaecentral         = "uac"
    israelcentral      = "isc"
    qatarcentral       = "qtc"
  }
}

# ===================================================================
# RESOURCE GROUP
# ===================================================================

variable "newRGname_E" {
  type        = string
  description = "Name for new resource group. Not required when existing_RGname is set."
  default     = null
}

# ===================================================================
# VIRTUAL NETWORK & SUBNET
# ===================================================================

variable "vnet_name_E" {
  type        = string
  description = "Name for new virtual network. Set to null if using existing."
  default     = null
}

variable "vnet_cidr_E" {
  type        = list(string)
  description = "Address space for the new VNet (e.g. [\"10.10.0.0/16\"]). Not required when existing_vNet_name is set."
  default     = []
}

variable "subnet_cidrs_E" {
  type        = list(string)
  description = "List of CIDR blocks for each subnet. Not required when existing_vNet_name is set."
  default     = []
}

# # # # variable "vnet_address_space_E" {
# # # #   type = map(any)
# # # #   default = {
# # # #     # Americas
# # # #     eastus             = ["10.1.0.0/16"]
# # # #     eastus2            = ["10.2.0.0/16"]
# # # #     westus             = ["10.3.0.0/16"]
# # # #     westus2            = ["10.4.0.0/16"]
# # # #     westus3            = ["10.5.0.0/16"]
# # # #     centralus          = ["10.6.0.0/16"]
# # # #     northcentralus     = ["10.7.0.0/16"]
# # # #     southcentralus     = ["10.8.0.0/16"]
# # # #     westcentralus      = ["10.9.0.0/16"]
# # # #     canadacentral      = ["10.10.0.0/16"]
# # # #     canadaeast         = ["10.11.0.0/16"]
# # # #     brazilsouth        = ["10.12.0.0/16"]
# # # #     brazilsoutheast    = ["10.13.0.0/16"]
# # # #     mexicocentral      = ["10.14.0.0/16"]
# # # #     # Europe
# # # #     northeurope        = ["10.15.0.0/16"]
# # # #     westeurope         = ["10.16.0.0/16"]
# # # #     uksouth            = ["10.17.0.0/16"]
# # # #     ukwest             = ["10.18.0.0/16"]
# # # #     francecentral      = ["10.19.0.0/16"]
# # # #     francesouth        = ["10.20.0.0/16"]
# # # #     germanywestcentral = ["10.21.0.0/16"]
# # # #     germanynorth       = ["10.22.0.0/16"]
# # # #     norwayeast         = ["10.23.0.0/16"]
# # # #     norwaywest         = ["10.24.0.0/16"]
# # # #     switzerlandnorth   = ["10.25.0.0/16"]
# # # #     switzerlandwest    = ["10.26.0.0/16"]
# # # #     swedencentral      = ["10.27.0.0/16"]
# # # #     polandcentral      = ["10.28.0.0/16"]
# # # #     italynorth         = ["10.29.0.0/16"]
# # # #     spaincentral       = ["10.30.0.0/16"]
# # # #     # Asia Pacific
# # # #     eastasia           = ["10.31.0.0/16"]
# # # #     southeastasia      = ["10.32.0.0/16"]
# # # #     australiaeast      = ["10.33.0.0/16"]
# # # #     australiasoutheast = ["10.34.0.0/16"]
# # # #     australiacentral   = ["10.35.0.0/16"]
# # # #     australiacentral2  = ["10.36.0.0/16"]
# # # #     centralindia       = ["10.37.0.0/16"]
# # # #     southindia         = ["10.38.0.0/16"]
# # # #     westindia          = ["10.39.0.0/16"]
# # # #     japaneast          = ["10.40.0.0/16"]
# # # #     japanwest          = ["10.41.0.0/16"]
# # # #     koreacentral       = ["10.42.0.0/16"]
# # # #     koreasouth         = ["10.43.0.0/16"]
# # # #     jioindiacentral    = ["10.44.0.0/16"]
# # # #     jioindiawest       = ["10.45.0.0/16"]
# # # #     newzealandnorth    = ["10.46.0.0/16"]
# # # #     # Middle East & Africa
# # # #     southafricanorth   = ["10.47.0.0/16"]
# # # #     southafricawest    = ["10.48.0.0/16"]
# # # #     uaenorth           = ["10.49.0.0/16"]
# # # #     uaecentral         = ["10.50.0.0/16"]
# # # #     israelcentral      = ["10.51.0.0/16"]
# # # #     qatarcentral       = ["10.52.0.0/16"]
# # # #   }
# # # # }

# # # # variable "subnet_prefixes" {
# # # #   type        = map(any)
# # # #   description = "The address prefix to use for the subnet."
# # # #   default = {
# # # #     uksouth       = ["10.0.0.0/24", "10.0.1.0/24"]
# # # #     canadacentral = ["20.0.0.0/24", "20.0.1.0/24"]
# # # #     ukwest        = ["30.0.0.0/24", "30.0.1.0/24"]
# # # #     centralindia  = ["40.0.0.0/24", "40.0.1.0/24"]
# # # #   }
# # # # }

variable "subnet_names" {
  type        = list(string)
  description = "List of subnet names inside the vNet."
  default     = null
}

variable "dns_servers_E" {
  type        = list(string)
  description = "Custom DNS server IPs for the VNet (e.g. AD DC IP). Empty = Azure default DNS."
  default     = []
}

# ===================================================================
# STORAGE ACCOUNT (required for UC1 and UC2: both use FSLogix)
# ===================================================================

variable "storage_name_E" {
  type        = string
  description = "Globally unique name for the storage account"
  default     = null
}

variable "account_tier_E" {
  type        = string
  description = "Storage account tier (Standard or Premium), Default value is set to Standard"
  default     = "Standard"
}

variable "replication_type_E" {
  type        = string
  description = "Replication type (LRS, GRS, ZRS, etc.)"
  default     = "LRS"
}

variable "share_level_permission_E" {
  type        = string
  description = "Share level permission for AADKERB storage (e.g., StorageFileDataSmbShareContributor)"
  default     = "StorageFileDataSmbShareContributor"
}

# ===================================================================
# ACTIVE DIRECTORY / DOMAIN VARIABLES
# ===================================================================

variable "domain_name_E" {
  type        = string
  description = "Domain name for Active Directory (e.g., contoso.com)"
  default     = null
}

variable "domain_guid_E" {
  type        = string
  description = "Domain GUID / Tenant ID for Active Directory"
  default     = null
}

variable "domain_sid_E" {
  type        = string
  description = "Domain SID for on-prem AD (example: S-1-5-21-...)"
  default     = null
}

variable "forest_name_E" {
  type        = string
  description = "Forest name for on-prem AD (example: contoso.com)"
  default     = null
}

variable "netbios_domain_name_E" {
  type        = string
  description = "NetBIOS domain name for on-prem AD (example: CONTOSO)"
  default     = null
}

variable "storage_sid_E" {
  type        = string
  description = "Storage SID for pre-created AD computer account (required for UC1)"
  default     = null
}

variable "OUPath_E" {
  type        = string
  description = "OU path for AD domain join (e.g., OU=avdusers,DC=contoso,DC=com)"
  default     = null
}

variable "ad_admin_user_name_E" {
  type        = string
  description = "AD admin username for domain join"
  default     = null
}

variable "ad_admin_user_password_E" {
  type        = string
  description = "AD admin password for domain join"
  sensitive   = true
  default     = null
}

# ===================================================================
# FILE SHARE (required for UC1 and UC2: both use FSLogix)
# ===================================================================

variable "fileshare_name_E" {
  type        = string
  description = "Name of the Azure File Share"
  default     = "fslogix"
}

variable "quota_E" {
  type        = number
  description = "Quota in GB for the file share"
  default     = 100
}

# ===================================================================
# SESSION HOST VMs
# ===================================================================

variable "sessionHost_name_E" {
  type        = string
  description = "Name of the Session Host" ##Add Default values
}

variable "sh_count_E" {
  type        = number
  description = "Number of session host VMs"
}

variable "sku_E" {
  type        = string
  description = "Size of the session host VM"
}

variable "admin_username_E" {
  type        = string
  description = "Admin username for session host VM"
}

variable "admin_password_E" {
  type        = string
  description = "Admin password for session host VM"
  sensitive   = true
}

variable "os_disk_st_acc_type_E" {
  type        = string
  description = "Disk Storage Account Type"
  validation {
    condition     = contains(["Premium_LRS", "Standard_LRS", "StandardSSD_LRS", "StandardSSD_ZRS", "Premium_ZRS"], var.os_disk_st_acc_type_E)
    error_message = "Select from Premium_LRS/Standard_LRS/StandardSSD_LRS/StandardSSD_ZRS/Premium_ZRS"
  }
}

variable "zone_E" {
  type        = number
  description = "Availability zone for the session host VM"
}

variable "encryption_E" {
  type        = bool
  description = "Enable encryption at host"
  default = false
}

variable "secure_boot_E" {
  type        = bool
  description = "Enable secure boot"
}

variable "vtpm_E" {
  type        = bool
  description = "Enable vTPM"
}

variable "image_publisher_E" {
  type        = string
  description = "Publisher of the VM image"
}

variable "image_offer_E" {
  type        = string
  description = "Offer of the VM image"
}

variable "image_sku_E" {
  type        = string
  description = "SKU of the VM image"
}

variable "image_version_E" {
  type        = string
  description = "Version of the VM image"
}

# ===================================================================
# CUSTOM IMAGE FROM AZURE COMPUTE GALLERY
# ===================================================================
variable "use_custom_image_E" {
  type        = bool
  description = "Use a custom image from Azure Compute Gallery. Set to true to use gallery image, false to use marketplace image."
  default     = false
}

variable "image_gallery_name_E" {
  type        = string
  description = "Name of the Azure Compute Gallery. Required when use_custom_image_E = true."
  default     = null
}

variable "image_gallery_rg_E" {
  type        = string
  description = "Resource group containing the Azure Compute Gallery. Required when use_custom_image_E = true."
  default     = null
}

variable "image_definition_name_E" {
  type        = string
  description = "Image definition name inside the gallery. Required when use_custom_image_E = true."
  default     = null
}

variable "image_gallery_version_E" {
  type        = string
  description = "Image version from the gallery. Use \"latest\" for the most recent version."
  default     = "latest"
}

variable "auto_shutdown_enabled_E" {
  type        = bool
  description = "Enable auto-shutdown schedule for session host VMs. Set to true to enable, false to disable."
  default     = false
}

variable "auto_shutdown_time_E" {
  type        = string
  description = "Daily auto-shutdown time in 24-hour HHMM format (e.g. \"1900\" = 7:00 PM). Required when auto_shutdown_enabled_E = true."
  default     = "1900"
}

variable "auto_shutdown_timezone_E" {
  type        = string
  description = "Windows timezone name for auto-shutdown (e.g. \"India Standard Time\", \"UTC\", \"Eastern Standard Time\")."
  default     = "UTC"
}

# ===================================================================
# HOST POOL
# ===================================================================

variable "hostpool_name_E" {
  type        = string
  description = "Name of the host pool"
}

variable "hostpool_type_E" {
  type        = string
  description = "Type of host pool (Pooled or Personal)"
  validation {
    condition     = contains(["Pooled", "Personal"], var.hostpool_type_E)
    error_message = "Select Pooled or Personal"
  }
}

variable "personal_desktop_assignment_type_E" {
  type        = string
  description = "Assignment type for personal desktops (Automatic or Direct)"
  default     = "Automatic"
}

variable "load_balancer_type_E" {
  type        = string
  description = "Load balancer type (BreadthFirst or DepthFirst)"
  default     = "BreadthFirst"
}

variable "max_sessions_E" {
  type        = number
  description = "Maximum sessions allowed per session host VM"
}

variable "app_group_type_E" {
  type        = string
  description = "Preferred application group type (Desktop or RemoteApp)"
}

variable "start_vm_on_connect_E" {
  type        = bool
  description = "Start VM on user connection"
}

variable "validate_env_E" {
  type        = bool
  description = "Validate environment setting before deployment"
  default = false
}

# ===================================================================
# APPLICATION GROUP
# ===================================================================

variable "app_group_name_E" {
  type        = string
  description = "Name of the application group"
}

variable "app_group_friendly_name_E" {
  type        = string
  description = "Friendly name for the application group"
}

# ===================================================================
# WORKSPACE
# ===================================================================

variable "workspace_name_E" {
  type        = string
  description = "Name of the Virtual Desktop Workspace"
}

variable "workspace_name_friendly_name_E" {
  type        = string
  description = "Friendly name for the workspace"
}

# ===================================================================
# REGISTRATION INFO
# ===================================================================

variable "expiration_date_E" {
  type        = string
  description = "Expiration date for the host pool registration info in ISO 8601 format. Defaults to current time + 1 month when not set."
  default     = null
}

variable "custom_tags_E" {
  type        = map(string)
  description = "User-defined custom tags to apply to all resources in addition to the mandatory tags (CreationTimeUTC, Environment, ServiceWorkload, cm-resource-parent)."
  default     = {}
}

variable "custom_rdp_properties_E" {
  type        = string
  description = "Custom RDP properties for the host pool Advanced tab (semicolon-separated key:type:value pairs)."
  default     = null
}









