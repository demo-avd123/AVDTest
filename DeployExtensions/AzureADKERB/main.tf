
# # # # resource "azurerm_virtual_machine_extension" "avd_agent" {
# # # #   count                      = var.sh_count_I
# # # #   name                       = "avd-agent"
# # # #   virtual_machine_id         = var.sessionHost_ID_I[count.index]
# # # #   publisher                  = "Microsoft.Compute"
# # # #   type                       = "CustomScriptExtension"
# # # #   type_handler_version       = "1.10"
# # # #   auto_upgrade_minor_version = true

# # # #   protected_settings = jsonencode({
# # # #     commandToExecute = "powershell -ExecutionPolicy Bypass -File install-avd-agent.ps1 -RegistrationToken '${var.registration_token_I}'"
# # # #     fileUris = [
# # # #       var.avd_agent_script_url_I,
# # # #       var.avd_agent_msi_url_I,
# # # #       var.avd_boot_loader_msi_url_I
# # # #     ]
# # # #     storageAccountName = var.avd_storage_account_name_I
# # # #     storageAccountKey  = var.avd_storage_account_key_I
# # # #   })

# # # #   depends_on = [
# # # #     azurerm_virtual_machine_extension.aad_login
# # # #   ]
# # # # }


# # # # resource "azurerm_virtual_machine_extension" "aad_login" {
# # # #   count                      = var.sh_count_I
# # # #   name                       = "AADLoginForWindows"
# # # #   virtual_machine_id         = var.sessionHost_ID_I[count.index]
# # # #   publisher                  = "Microsoft.Azure.ActiveDirectory"
# # # #   type                       = "AADLoginForWindows"
# # # #   type_handler_version       = "2.0"
# # # #   auto_upgrade_minor_version = true
# # # # }
