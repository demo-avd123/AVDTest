variable "env_I" {
  type        = string
  description = "Environment tag"
}

variable "rg_name_I" {
  type        = string
  description = "Resource group name"
}

variable "location_I" {
  type        = string
  description = "Azure region"
}

variable "folllowNomenclature_I" {
  type = bool
}

variable "prefix_I" {
  type = string
}

variable "sessionHost_name_I" {
  type = string
}

variable "sh_count_I" {
  type = number
}

variable "sku_I" {
  type = string
}

variable "admin_username_I" {
  type = string
}

variable "admin_password_I" {
  type      = string
  sensitive = true
}

variable "os_disk_st_acc_type_I" {
  type = string
}

variable "image_publisher_I" {
  type = string
}

variable "image_offer_I" {
  type = string
}

variable "image_sku_I" {
  type = string
}

variable "image_version_I" {
  type = string
}

variable "subnet_id_I" {
  type = string
}

variable "zone_I" {
  type = string
}

variable "encryption_I" {
  type = bool
}

variable "secure_boot_I" {
  type = bool
}

variable "vtpm_I" {
  type = bool
}

variable "auto_shutdown_enabled_I" {
  type        = bool
  description = "Enable auto-shutdown schedule for session host VMs."
  default     = false
}

variable "auto_shutdown_time_I" {
  type        = string
  description = "Daily auto-shutdown time in 24-hour HHMM format (e.g. \"1900\")."
  default     = "1900"
}

variable "auto_shutdown_timezone_I" {
  type        = string
  description = "Windows timezone name for auto-shutdown (e.g. \"India Standard Time\")."
  default     = "UTC"
}

# ===================================================================
# CUSTOM IMAGE FROM AZURE COMPUTE GALLERY
# ===================================================================
variable "use_custom_image_I" {
  type        = bool
  description = "Use a custom image from Azure Compute Gallery instead of a marketplace image."
  default     = false
}

variable "image_gallery_name_I" {
  type        = string
  description = "Name of the Azure Compute Gallery. Required when use_custom_image_I = true."
  default     = null
}

variable "image_gallery_rg_I" {
  type        = string
  description = "Resource group of the Azure Compute Gallery. Required when use_custom_image_I = true."
  default     = null
}

variable "image_definition_name_I" {
  type        = string
  description = "Image definition (image name) inside the gallery. Required when use_custom_image_I = true."
  default     = null
}

variable "image_gallery_version_I" {
  type        = string
  description = "Image version to use from the gallery. Use \"latest\" for the most recent version."
  default     = "latest"
}

variable "subscription_id_I" {
  type = string
}

variable "tags_I" {
  type        = map(string)
  description = "Tags to apply to all resources."
  default     = {}
}
