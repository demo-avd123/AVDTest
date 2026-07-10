# # # # resource "azurerm_virtual_machine_extension" "domain_join" {
# # # #   count                      = var.sh_count_I
# # # #   name                       = "${var.prefix_I}-${count.index + 1}-domainJoin"
# # # #   virtual_machine_id         = var.sessionHost_ID_I[count.index]
# # # #   publisher                  = "Microsoft.Compute"
# # # #   type                       = "JsonADDomainExtension"
# # # #   type_handler_version       = "1.3"
# # # #   auto_upgrade_minor_version = true

# # # #   settings = <<SETTINGS
# # # #     {
# # # #       "Name": "${var.domain_name_I}",
# # # #       "OUPath": "${var.OUPath_I}",
# # # #       "User": "${var.ad_admin_user_name_I}",
# # # #       "Restart": "true",
# # # #       "Options": "3"
# # # #     }
# # # # SETTINGS

# # # #   protected_settings = <<PROTECTED_SETTINGS
# # # #     {
# # # #       "Password": "${var.ad_admin_user_password_I}"
# # # #     }
# # # # PROTECTED_SETTINGS

# # # #   lifecycle {
# # # #     ignore_changes = [settings, protected_settings]
# # # #   }


# # # # }

# # # # resource "azurerm_virtual_machine_extension" "avd_agent" {
# # # #   count                      = var.sh_count_I
# # # #   name                       = "${var.prefix_I}${count.index + 1}-avd-agent"
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
# # # #     azurerm_virtual_machine_extension.domain_join
# # # #   ]


# # # # }
