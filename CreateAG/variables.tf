variable "rg_name_I" {
  type = string
}

variable "hostpool_id_I" {
  type = string
}

variable "location_I" {
  type = string
}

variable "app_group_name_I" {
  type = string
}

variable "app_group_type_I" {
  type = string
}

variable "app_group_friendly_name_I" {
  type = string
}

variable "env_I" {
  type = string
}

variable "subscription_id_I" {
  type = string
}

variable "tags_I" {
  type    = map(string)
  default = {}
}
