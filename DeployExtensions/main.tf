# ===================================================================
# Extensions module supporting UC1 and UC2 (ADDS-joined session hosts)
# ===================================================================
# UC1: ADDS domain join, FSLogix via CustomScriptExtension, OnPrem AD storage
# UC2: ADDS domain join, FSLogix + Kerberos via az vm run-command, AADKERB storage
#
# Key resources:
#   - ADDS domain join extension
#   - DSC extension for AVD agent registration
#   - FSLogix registry config (UC1 via CustomScriptExtension, UC2 via run-command + Kerberos)
# ===================================================================

locals {
  use_adds_join = true
}

# ===================================================================
# 1. ADDS DOMAIN JOIN (UC 1, 2)
# ===================================================================

resource "azurerm_virtual_machine_extension" "adds_domain_join" {
  count                      = local.use_adds_join ? var.sh_count_I : 0
  name                       = "${var.prefix_I}-${count.index + 1}-domainJoin"
  virtual_machine_id         = var.sessionHost_ID_I[count.index]
  publisher                  = "Microsoft.Compute"
  type                       = "JsonADDomainExtension"
  type_handler_version       = "1.3"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
      "Name": "${var.domain_name_I}",
      "OUPath": "${var.OUPath_I}",
      "User": "${var.ad_admin_user_name_I}",
      "Restart": "true",
      "Options": "3"
    }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {
      "Password": "${var.ad_admin_user_password_I}"
    }
PROTECTED_SETTINGS

  lifecycle {
    ignore_changes = [settings, protected_settings]
  }
}

# ===================================================================
# 2. AVD AGENT REGISTRATION via DSC extension (UC1 and UC2)
#    Uses the Microsoft-hosted DSC configuration zip for reliable
#    session host registration with the host pool.
# ===================================================================

resource "azurerm_virtual_machine_extension" "vmext_dsc" {
  count                      = var.sh_count_I
  name                       = "${var.prefix_I}-${count.index + 1}-avd_dsc"
  virtual_machine_id         = var.sessionHost_ID_I[count.index]
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.80"
  auto_upgrade_minor_version = true

  settings = <<-SETTINGS
    {
      "modulesUrl": "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_1.0.02714.342.zip",
      "configurationFunction": "Configuration.ps1\\AddSessionHost",
      "properties": {
        "HostPoolName": "${var.hostpool_name_I}",
        "AadJoin": false,
        "UseAgentDownloadEndpoint": true
      }
    }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
  {
    "properties": {
      "registrationInfoToken": "${var.registration_token_I}"
    }
  }
PROTECTED_SETTINGS

  depends_on = [
    azurerm_virtual_machine_extension.adds_domain_join
  ]
}

# ===================================================================
# 6a. FSLOGIX CONFIG via CustomScriptExtension (UC 1 only - ADDS + OnPremAD)
#     UC1: on-prem AD storage auth — VM uses Kerberos via domain membership.
#     UC2: AADKERB storage — handled by configure_fslogix_kerberos (6b) below.
# ===================================================================

resource "azurerm_virtual_machine_extension" "fslogix_config_adds" {
  count                      = local.use_adds_join && var.enable_fslogix_I && var.use_case_I == 1 ? var.sh_count_I : 0
  name                       = "${var.prefix_I}-${count.index + 1}-FSLogixConfig"
  virtual_machine_id         = var.sessionHost_ID_I[count.index]
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true

  protected_settings = jsonencode({
    commandToExecute = "powershell.exe -ExecutionPolicy Bypass -Command \"$fileServer='${var.storage_account_name_I}.file.core.windows.net'; $profileShare=\\\"\\\\$fileServer\\${var.file_share_name_I}\\\"; $regPath='HKLM:\\SOFTWARE\\FSLogix\\Profiles'; if(!(Test-Path $regPath)){New-Item -Path $regPath -Force}; Set-ItemProperty -Path $regPath -Name ClearCacheOnLogoff -Value 1 -Type DWord -Force; Set-ItemProperty -Path $regPath -Name Enabled -Value 1 -Type DWord -Force; Set-ItemProperty -Path $regPath -Name DeleteLocalProfileWhenVHDShouldApply -Value 1 -Type DWord -Force; Set-ItemProperty -Path $regPath -Name FlipFlopProfileDirectoryName -Value 1 -Type DWord -Force; Set-ItemProperty -Path $regPath -Name HealthyProvidersRequiredForRegister -Value 1 -Type DWord -Force; Set-ItemProperty -Path $regPath -Name LockedRetryCount -Value 3 -Type DWord -Force; Set-ItemProperty -Path $regPath -Name LockedRetryInterval -Value 15 -Type DWord -Force; Set-ItemProperty -Path $regPath -Name ProfileType -Value 0 -Type DWord -Force; Set-ItemProperty -Path $regPath -Name ReAttachRetryCount -Value 3 -Type DWord -Force; Set-ItemProperty -Path $regPath -Name ReAttachIntervalSeconds -Value 15 -Type DWord -Force; Set-ItemProperty -Path $regPath -Name SizeInMBs -Value 30000 -Type DWord -Force; Set-ItemProperty -Path $regPath -Name VolumeType -Value 'vhdx' -Type String -Force; Set-ItemProperty -Path $regPath -Name VHDLocations -Value $profileShare -Type String -Force; Write-Host 'FSLogix configured successfully'; Write-Host \\\"Storage: $fileServer\\\"; Write-Host \\\"Share: $profileShare\\\"\""
  })

  depends_on = [
    azurerm_virtual_machine_extension.adds_domain_join,
    azurerm_virtual_machine_extension.vmext_dsc
  ]
}

# ===================================================================
# 3. FSLOGIX + KERBEROS CONFIG via az vm run-command (UC2)
#     UC2: ADDS-joined but uses AADKERB storage — needs Kerberos registry key
#     Configures full FSLogix registry settings AND enables Cloud
#     Kerberos Ticket Retrieval.
# ===================================================================

resource "null_resource" "configure_fslogix_kerberos" {
  count = var.use_case_I == 2 ? var.sh_count_I : 0

  triggers = {
    vm_id           = var.sessionHost_ID_I[count.index]
    storage_account = var.storage_account_name_I
    file_share      = var.file_share_name_I
  }

  provisioner "local-exec" {
    command     = <<-EOT
      Write-Host "Waiting for AVD agent to complete installation..."
      Start-Sleep -Seconds 120
      
      $vmName = "${var.sessionHost_names_I[count.index]}"
      $rgName = "${var.rg_name_I}"
      $storageAccount = "${var.storage_account_name_I}"
      $fileShare = "${var.file_share_name_I}"
      
      Write-Host "Configuring FSLogix and Kerberos on $vmName..."
      
      $scriptFile = Join-Path $env:TEMP "fslogix_kerberos_config_$($vmName).ps1"
      
      $scriptContent = @"
`$fileServer = "$($storageAccount).file.core.windows.net"
`$profileShare = "\\`$(`$fileServer)\$($fileShare)"
`$registryPath = "HKLM:\SOFTWARE\FSLogix\Profiles"

Write-Host "=== Configuring FSLogix Profile Containers ===" -ForegroundColor Green

if (!(Test-Path `$registryPath)) {
  New-Item -Path `$registryPath -Force | Out-Null
  Write-Host "Created FSLogix registry path" -ForegroundColor Cyan
}

New-ItemProperty -Path `$registryPath -Name ClearCacheOnLogoff              -PropertyType DWord  -Value 1      -Force | Out-Null
New-ItemProperty -Path `$registryPath -Name Enabled                          -PropertyType DWord  -Value 1      -Force | Out-Null
New-ItemProperty -Path `$registryPath -Name DeleteLocalProfileWhenVHDShouldApply -PropertyType DWord  -Value 1  -Force | Out-Null
New-ItemProperty -Path `$registryPath -Name FlipFlopProfileDirectoryName     -PropertyType DWord  -Value 1      -Force | Out-Null
New-ItemProperty -Path `$registryPath -Name HealthyProvidersRequiredForRegister -PropertyType DWord  -Value 1   -Force | Out-Null
New-ItemProperty -Path `$registryPath -Name LockedRetryCount                 -PropertyType DWord  -Value 3      -Force | Out-Null
New-ItemProperty -Path `$registryPath -Name LockedRetryInterval              -PropertyType DWord  -Value 15     -Force | Out-Null
New-ItemProperty -Path `$registryPath -Name ProfileType                      -PropertyType DWord  -Value 0      -Force | Out-Null
New-ItemProperty -Path `$registryPath -Name ReAttachRetryCount               -PropertyType DWord  -Value 3      -Force | Out-Null
New-ItemProperty -Path `$registryPath -Name ReAttachIntervalSeconds          -PropertyType DWord  -Value 15     -Force | Out-Null
New-ItemProperty -Path `$registryPath -Name SizeInMBs                        -PropertyType DWord  -Value 30000  -Force | Out-Null
New-ItemProperty -Path `$registryPath -Name VHDLocations                     -PropertyType String -Value `$profileShare -Force | Out-Null
New-ItemProperty -Path `$registryPath -Name VolumeType                       -PropertyType String -Value "vhdx" -Force | Out-Null

Write-Host "[OK] FSLogix configured" -ForegroundColor Green
Write-Host "VHDLocations: `$profileShare" -ForegroundColor Cyan

Write-Host "`n=== Enabling Cloud Kerberos Ticket Retrieval ===" -ForegroundColor Green
`$kerberosPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\Parameters"
if (!(Test-Path `$kerberosPath)) {
  New-Item -Path `$kerberosPath -Force | Out-Null
}
New-ItemProperty -Path `$kerberosPath -Name CloudKerberosTicketRetrievalEnabled -PropertyType DWord -Value 1 -Force | Out-Null

Write-Host "[OK] Cloud Kerberos enabled" -ForegroundColor Green

Write-Host "`n=== Testing Storage Connectivity ===" -ForegroundColor Green
`$testConn = Test-NetConnection -ComputerName `$fileServer -Port 445 -WarningAction SilentlyContinue
if (`$testConn.TcpTestSucceeded) {
    Write-Host "[OK] Port 445 is reachable to `$fileServer" -ForegroundColor Green
} else {
    Write-Host "[WARNING] Cannot reach storage on port 445" -ForegroundColor Yellow
}

Write-Host "`n[SUCCESS] Configuration complete! VM will need a restart for all settings to take effect." -ForegroundColor Green
"@

      Set-Content -Path $scriptFile -Value $scriptContent -Encoding UTF8
      
      az vm run-command invoke --resource-group $rgName --name $vmName --command-id RunPowerShellScript --scripts "@$scriptFile" --no-wait
      
      Remove-Item $scriptFile -Force
      Write-Host "FSLogix and Kerberos configuration applied to $vmName"
    EOT
    interpreter = ["pwsh", "-Command"]
  }

  depends_on = [
    azurerm_virtual_machine_extension.adds_domain_join,
    azurerm_virtual_machine_extension.vmext_dsc
  ]
}
