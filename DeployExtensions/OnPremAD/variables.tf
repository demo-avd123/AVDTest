variable "sessionHost_ID_I" {
  type = list(string)
}

variable "sh_count_I" {
  type = number
}

variable "hostpool_name_I" {
  type = string
}

variable "registration_token_I" {
  type = string
}

variable "prefix_I" {
  type = string
}

variable "domain_name_I" {
  type = string
}
variable "OUPath_I" {
  type = string
}
variable "ad_admin_user_name_I" {
  type = string
}
variable "ad_admin_user_password_I" {
  type = string
}

variable "avd_agent_script_url_I" {
  type = string
}

variable "avd_agent_msi_url_I" {
  type = string
}

variable "avd_boot_loader_msi_url_I" {
  type = string
}

variable "avd_storage_account_name_I" {
  type = string
}

variable "avd_storage_account_key_I" {
  type      = string
  sensitive = true
}
