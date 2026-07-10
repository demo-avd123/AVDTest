variable "env_I" {
  type = string
}

variable "rg_name_I" {
  type = string
}

variable "location_I" {
  type = string
}

variable "hostpool_name_I" {
  type = string
}

variable "hostpool_type_I" {
  type = string
}

variable "personal_desktop_assignment_type_I" {
  type = string
}

variable "load_balancer_type_I" {
  type = string
}

variable "max_sessions_I" {
  type = number
}

variable "app_group_type_I" {
  type = string
}

variable "start_vm_on_connect_I" {
  type = bool
}

variable "validate_env_I" {
  type = bool
}

variable "custom_rdp_properties_I" {
  type        = string
  description = "Custom RDP properties string for the host pool (Advanced tab in portal)."
  default     = null
}

variable "subscription_id_I" {
  type = string
}

variable "tags_I" {
  type    = map(string)
  default = {}
}
