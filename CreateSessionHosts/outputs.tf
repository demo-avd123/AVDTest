output "SessionHostVMs_Details_I" {
  value = [
    for sessionHost in azurerm_windows_virtual_machine.session_host : {
      id   = sessionHost.id
      name = sessionHost.name
    }
  ]
}
