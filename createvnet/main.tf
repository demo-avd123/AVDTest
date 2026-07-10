resource "azurerm_virtual_network" "avd-vNet" {
  name                = var.vnet_name_I
  location            = var.location_I
  resource_group_name = var.rg_name_I
  address_space       = var.vnet_address_space_I
  dns_servers         = var.dns_servers_I
  tags = merge(var.tags_I, {
    cm-resource-parent = "/subscriptions/${var.subscription_id_I}/resourceGroups/${var.rg_name_I}/providers/Microsoft.Network/virtualNetworks/${var.vnet_name_I}"
  })
}


resource "azurerm_subnet" "subnets" {
  count                = length(var.subnet_names_I)
  name                 = var.folllowNomenclature_I == true ? "${var.prefix_I}-${var.subnet_names_I[count.index]}-${var.env_I}" : var.subnet_names_I[count.index]
  resource_group_name  = var.rg_name_I
  virtual_network_name = azurerm_virtual_network.avd-vNet.name
  address_prefixes     = [var.subnet_prefixes_I[count.index]]
}

// ---- VNet Peering: new AVD VNet → existing remote VNet ----
resource "azurerm_virtual_network_peering" "avd_to_remote" {
  count                        = var.enable_vnet_peering_I ? 1 : 0
  name                         = "${azurerm_virtual_network.avd-vNet.name}-to-${var.peer_vnet_name_I}"
  resource_group_name          = var.rg_name_I
  virtual_network_name         = azurerm_virtual_network.avd-vNet.name
  remote_virtual_network_id    = var.peer_vnet_id_I
  allow_forwarded_traffic      = var.peer_allow_forwarded_traffic_I
  allow_gateway_transit        = var.peer_allow_gateway_transit_I
  use_remote_gateways          = var.peer_use_remote_gateways_I
  allow_virtual_network_access = true
}

// ---- VNet Peering: existing remote VNet → new AVD VNet ----
resource "azurerm_virtual_network_peering" "remote_to_avd" {
  count                        = var.enable_vnet_peering_I ? 1 : 0
  name                         = "${var.peer_vnet_name_I}-to-${azurerm_virtual_network.avd-vNet.name}"
  resource_group_name          = var.peer_vnet_rg_I
  virtual_network_name         = var.peer_vnet_name_I
  remote_virtual_network_id    = azurerm_virtual_network.avd-vNet.id
  allow_forwarded_traffic      = var.peer_allow_forwarded_traffic_I
  allow_gateway_transit        = false
  use_remote_gateways          = false
  allow_virtual_network_access = true
}
