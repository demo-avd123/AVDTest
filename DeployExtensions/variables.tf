# Session host info
variable "sessionHost_ID_I" {
  type = list(string)
}

variable "sessionHost_names_I" {
  type        = list(string)
  description = "List of session host VM names (for az vm run-command and data lookups)"
}

variable "sh_count_I" {
  type = number
}

variable "prefix_I" {
  type = string
}

variable "rg_name_I" {
  type        = string
  description = "Resource group name (for data source lookups and az commands)"
}

# AVD registration
variable "hostpool_name_I" {
  type = string
}

variable "registration_token_I" {
  type = string
}

# Use case driven flags
variable "session_host_join_type_I" {
  type        = string
  description = "ADDS (UC1 and UC2 only)"
}

variable "enable_fslogix_I" {
  type = bool
}

variable "fslogix_config_method_I" {
  type        = string
  description = "GPO, RegistryKey, or NA"
}

# ADDS domain join params (UC 1, 2)
variable "domain_name_I" {
  type    = string
  default = null
}

variable "OUPath_I" {
  type    = string
  default = null
}

variable "ad_admin_user_name_I" {
  type    = string
  default = null
}

variable "ad_admin_user_password_I" {
  type      = string
  sensitive = true
  default   = null
}

# Storage info (for FSLogix config)
variable "storage_account_id_I" {
  type        = string
  description = "Storage account resource ID"
  default     = null
}

variable "storage_account_name_I" {
  type        = string
  description = "Storage account name (for FSLogix UNC path)"
  default     = null
}

variable "file_share_name_I" {
  type        = string
  description = "File share name (for FSLogix UNC path)"
  default     = null
}

variable "use_case_I" {
  type        = number
  description = "Use case number (1 or 2)"
}
