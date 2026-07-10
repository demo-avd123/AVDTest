output "vnet_name" {
  value = azurerm_virtual_network.avd-vNet.name
}

output "vnet_address_space" {
  value = azurerm_virtual_network.avd-vNet.address_space
}
output "subnet_details" {
  value = [
    for subnet in azurerm_subnet.subnets : {
      id      = subnet.id
      name    = subnet.name
      address = subnet.address_prefixes
    }
  ]
}
