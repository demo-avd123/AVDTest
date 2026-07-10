variable "storage_name_I" {
  type = string
}

variable "rg_name_I" {
  type = string
}

variable "location_I" {
  type = string
}

variable "account_tier_I" {
  type = string
}

variable "replication_type_I" {
  type = string
}

variable "env_I" {
  type = string
}

variable "storage_identity_type_I" {
  type        = string
  description = "AD for OnPrem AD, AADKERB for Azure AD Kerberos"
}

# OnPrem AD fields
variable "domain_name_I" {
  type    = string
  default = null
}

variable "domain_guid_I" {
  type    = string
  default = null
}

variable "domain_sid_I" {
  type    = string
  default = null
}

variable "forest_name_I" {
  type    = string
  default = null
}

variable "netbios_domain_name_I" {
  type    = string
  default = null
}

variable "storage_sid_I" {
  type    = string
  default = null
}

# AADKERB fields
variable "share_level_permission_I" {
  type    = string
  default = null
}

variable "subscription_id_I" {
  type = string
}

variable "tags_I" {
  type    = map(string)
  default = {}
}
