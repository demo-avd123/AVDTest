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
