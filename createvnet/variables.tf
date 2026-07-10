variable "env_I" {
  type = string
}

variable "prefix_I" {
  type = string
}

variable "folllowNomenclature_I" {
  type = bool
}

variable "vnet_name_I" {
  type = string
}

variable "location_I" {
  type = string
}

variable "rg_name_I" {
  type = string

}
variable "vnet_address_space_I" {
  type = list(string)
}

variable "subnet_names_I" {
  type = list(string)
}

variable "subnet_prefixes_I" {
  type = list(string)
}

variable "dns_servers_I" {
  type    = list(string)
  default = []
}

variable "subscription_id_I" {
  type = string
}

variable "tags_I" {
  type    = map(string)
  default = {}
}

// ---- VNet Peering ----
variable "enable_vnet_peering_I" {
  type        = bool
  description = "Set to true to create VNet peering between the new VNet and an existing VNet."
  default     = false
}

variable "peer_vnet_name_I" {
  type        = string
  description = "Name of the existing remote VNet to peer with."
  default     = null
}

variable "peer_vnet_id_I" {
  type        = string
  description = "Resource ID of the existing remote VNet to peer with."
  default     = null
}

variable "peer_vnet_rg_I" {
  type        = string
  description = "Resource group of the existing remote VNet."
  default     = null
}

variable "peer_allow_forwarded_traffic_I" {
  type        = bool
  description = "Allow forwarded traffic from the remote VNet."
  default     = true
}

variable "peer_allow_gateway_transit_I" {
  type        = bool
  description = "Allow gateway transit (set true if remote VNet has a VPN/ExpressRoute gateway)."
  default     = false
}

variable "peer_use_remote_gateways_I" {
  type        = bool
  description = "Use remote VNet's gateway (set true if this VNet should route through the remote gateway)."
  default     = false
}
