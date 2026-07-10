variable "env_I" {
  type = string
}

variable "rg_name_I" {
  type = string

}

variable "location_I" {
  type = string
}

variable "subscription_id_I" {
  type = string
}

variable "tags_I" {
  type    = map(string)
  default = {}
}
