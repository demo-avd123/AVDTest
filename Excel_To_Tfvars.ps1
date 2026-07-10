<#
.SYNOPSIS
    Converts AVD_Input_Variables.xlsx  ->  terraform.tfvars

.DESCRIPTION
    Reads the "Customer Value" column (col 8) from AVD_Input_Variables.xlsx.
    If a cell in that column is blank, the "Sample Value" (col 7) is used as
    the default so the file is always complete.

    Type-aware formatting:
        string       ->  "value"  or  null
        number       ->  123      or  null
        bool         ->  true / false / null
        list(string) ->  ["a", "b", ...]   (comma-separated input accepted)
        map(string)  ->  { Key = "Val" }   (key=val pairs accepted)

    A timestamped backup of any existing terraform.tfvars is created before
    overwriting.

.PARAMETER ExcelPath
    Path to the Excel workbook.  Default: .\AVD_Input_Variables.xlsx

.PARAMETER TfvarsPath
    Path for the output tfvars file.  Default: .\terraform.tfvars

.EXAMPLE
    .\Excel_To_Tfvars.ps1

.EXAMPLE
    .\Excel_To_Tfvars.ps1 -ExcelPath "C:\my\path\AVD_Input_Variables.xlsx" `
                          -TfvarsPath "C:\my\path\terraform.tfvars"
#>

param(
    [string]$ExcelPath  = "$PSScriptRoot\AVD_Input_Variables.xlsx",
    [string]$TfvarsPath = "$PSScriptRoot\terraform.tfvars"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# 1.  VALIDATE INPUTS
# ---------------------------------------------------------------------------
if (-not (Test-Path $ExcelPath)) {
    Write-Error "Excel file not found: $ExcelPath"
    exit 1
}

# ---------------------------------------------------------------------------
# 2.  READ EXCEL  (COM automation -- no extra modules required)
# ---------------------------------------------------------------------------
Write-Host "Reading Excel: $ExcelPath" -ForegroundColor Cyan

$excel = New-Object -ComObject Excel.Application
$excel.Visible       = $false
$excel.DisplayAlerts = $false

try {
    $wb   = $excel.Workbooks.Open($ExcelPath)
    $ws   = $wb.Worksheets.Item(1)
    $last = $ws.UsedRange.Rows.Count

    # Build lookup: varName -> hashtable with Type, SampleValue, CustomerValue
    $vars = @{}
    for ($r = 2; $r -le $last; $r++) {
        $name   = [string]$ws.Cells.Item($r, 1).Value2
        $type   = ([string]$ws.Cells.Item($r, 3).Value2).Trim().ToLower()
        $sample = ([string]$ws.Cells.Item($r, 6).Value2).Trim()
        $cust   = ([string]$ws.Cells.Item($r, 5).Value2).Trim()
        $name   = $name.Trim()
        if ($name -ne '') {
            $vars[$name] = @{ Type = $type; SampleValue = $sample; CustomerValue = $cust }
        }
    }

    $wb.Close($false)
}
finally {
    $excel.Quit()
    [void][System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel)
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
}

Write-Host "  Loaded $($vars.Count) variables from Excel." -ForegroundColor Green

# ---------------------------------------------------------------------------
# 3.  TYPE-AWARE FORMATTER
# ---------------------------------------------------------------------------
function Get-TFValue {
    param(
        [string]$VarName,
        [string]$Type,
        [string]$Raw
    )

    $v = $Raw.Trim()

    # ---- bool ---------------------------------------------------------------
    if ($Type -eq 'bool') {
        # Check for null or empty
        if (-not $v) { return 'false' }
        if ($v -ieq 'null')                 { return 'null'  }
        if ($v -ieq 'true')                 { return 'true'  }
        if ($v -ieq 'false')                { return 'false' }
        Write-Warning "  [$VarName] Unexpected bool value '$v' -- defaulting to false"
        return 'false'
    }

    # ---- number -------------------------------------------------------------
    if ($Type -eq 'number') {
        if (-not $v -or $v -ieq 'null') { return 'null' }
        if ($v -match '^\d+$')           { return $v     }
        Write-Warning "  [$VarName] '$v' is not a valid number -- writing null"
        return 'null'
    }

    # ---- list(string) -------------------------------------------------------
    if ($Type -like 'list*') {
        if (-not $v -or $v -ieq 'null') { return 'null' }
        # Already formatted  ["a", "b"]
        if ($v -match '^\[.*\]$') { return $v }
        # Bare value(s) -- split on comma and quote each item
        $items = @($v -split ',' | ForEach-Object {
            $item = $_.Trim().Trim('"').Trim("'")
            if ($item) { '"' + $item + '"' }
        } | Where-Object { $null -ne $_ })
        $joined = $items -join ', '
        return '[' + $joined + ']'
    }

    # ---- map(string) --------------------------------------------------------
    if ($Type -like 'map*') {
        if (-not $v -or $v -ieq 'null' -or $v -eq '{}') { return '{}' }
        # Strip outer braces if present
        $inner = $v -replace '^\{', '' -replace '\}$', ''
        $pairs = $inner -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
        $lines = New-Object System.Collections.Generic.List[string]
        foreach ($pair in $pairs) {
            if ($pair -match '^([^=]+?)\s*=\s*"?([^"]*)"?$') {
                $k  = $matches[1].Trim()
                $kv = $matches[2].Trim()
                $lines.Add('  ' + $k + ' = "' + $kv + '"')
            }
            else {
                $lines.Add('  ' + $pair)
            }
        }
        $nl     = [System.Environment]::NewLine
        $body   = [string]::Join($nl, $lines.ToArray())
        return '{' + $nl + $body + $nl + '}'
    }

    # ---- string (default) ---------------------------------------------------
    if (-not $v -or $v -ieq 'null') { return 'null' }
    # Already quoted
    if ($v -match '^".*"$') { return $v }
    return '"' + $v + '"'
}

# Resolve a single variable: prefer CustomerValue, fall back to SampleValue
function Resolve-Var {
    param([string]$Name)
    if (-not $vars.ContainsKey($Name)) {
        Write-Warning "  Variable '$Name' not found in Excel -- writing null"
        return 'null'
    }
    $entry = $vars[$Name]
    $raw   = if ($entry.CustomerValue -ne '') { $entry.CustomerValue } else { $entry.SampleValue }
    return Get-TFValue -VarName $Name -Type $entry.Type -Raw $raw
}

# ---------------------------------------------------------------------------
# 4.  BACKUP EXISTING TFVARS
# ---------------------------------------------------------------------------
if (Test-Path $TfvarsPath) {
    $ts     = Get-Date -Format 'yyyyMMdd_HHmmss'
    $backup = $TfvarsPath + '.backup_' + $ts
    Copy-Item $TfvarsPath $backup
    Write-Host "  Backup created: $backup" -ForegroundColor Yellow
}

# ---------------------------------------------------------------------------
# 5.  RESOLVE ALL VARIABLE VALUES
# ---------------------------------------------------------------------------
Write-Host 'Resolving values...' -ForegroundColor Cyan

$v_use_case                        = Resolve-Var 'use_case'
$v_existing_RGname                 = Resolve-Var 'existing_RGname'
$v_existing_vNet_name              = Resolve-Var 'existing_vNet_name'
$v_existing_vNet_address           = Resolve-Var 'existing_vNet_address'
$v_existing_subnet                 = Resolve-Var 'existing_subnet'
$v_existing_storage_account_name   = Resolve-Var 'existing_storage_account_name'
$v_azure_subscription_id_E         = Resolve-Var 'azure_subscription_id_E'
$v_folllowNomenclature_E           = Resolve-Var 'folllowNomenclature_E'
$v_env_E                           = Resolve-Var 'env_E'
$v_location_E                      = Resolve-Var 'location_E'
$v_newRGname_E                     = Resolve-Var 'newRGname_E'
$v_vnet_name_E                     = Resolve-Var 'vnet_name_E'
$v_subnet_names                    = Resolve-Var 'subnet_names'
$v_vnet_cidr_E                     = Resolve-Var 'vnet_cidr_E'
$v_subnet_cidrs_E                  = Resolve-Var 'subnet_cidrs_E'
$v_enable_vnet_peering_E           = Resolve-Var 'enable_vnet_peering_E'
$v_peer_vnet_name_E                = Resolve-Var 'peer_vnet_name_E'
$v_peer_vnet_id_E                  = Resolve-Var 'peer_vnet_id_E'
$v_peer_vnet_rg_E                  = Resolve-Var 'peer_vnet_rg_E'
$v_peer_allow_forwarded_traffic_E  = Resolve-Var 'peer_allow_forwarded_traffic_E'
$v_peer_allow_gateway_transit_E    = Resolve-Var 'peer_allow_gateway_transit_E'
$v_peer_use_remote_gateways_E      = Resolve-Var 'peer_use_remote_gateways_E'
$v_dns_servers_E                   = Resolve-Var 'dns_servers_E'
$v_storage_name_E                  = Resolve-Var 'storage_name_E'
$v_account_tier_E                  = Resolve-Var 'account_tier_E'
$v_replication_type_E              = Resolve-Var 'replication_type_E'
$v_share_level_permission_E        = Resolve-Var 'share_level_permission_E'
$v_domain_name_E                   = Resolve-Var 'domain_name_E'
$v_domain_guid_E                   = Resolve-Var 'domain_guid_E'
$v_domain_sid_E                    = Resolve-Var 'domain_sid_E'
$v_forest_name_E                   = Resolve-Var 'forest_name_E'
$v_netbios_domain_name_E           = Resolve-Var 'netbios_domain_name_E'
$v_storage_sid_E                   = Resolve-Var 'storage_sid_E'
$v_OUPath_E                        = Resolve-Var 'OUPath_E'
$v_ad_admin_user_name_E            = Resolve-Var 'ad_admin_user_name_E'
$v_ad_admin_user_password_E        = Resolve-Var 'ad_admin_user_password_E'
$v_aadds_domain_name_E             = Resolve-Var 'aadds_domain_name_E'
$v_aadds_ou_path_E                 = Resolve-Var 'aadds_ou_path_E'
$v_aadds_admin_user_name_E         = Resolve-Var 'aadds_admin_user_name_E'
$v_aadds_admin_user_password_E     = Resolve-Var 'aadds_admin_user_password_E'
$v_fileshare_name_E                = Resolve-Var 'fileshare_name_E'
$v_quota_E                         = Resolve-Var 'quota_E'
$v_sessionHost_name_E              = Resolve-Var 'sessionHost_name_E'
$v_sh_count_E                      = Resolve-Var 'sh_count_E'
$v_sku_E                           = Resolve-Var 'sku_E'
$v_admin_username_E                = Resolve-Var 'admin_username_E'
$v_admin_password_E                = Resolve-Var 'admin_password_E'
$v_os_disk_st_acc_type_E           = Resolve-Var 'os_disk_st_acc_type_E'
$v_zone_E                          = Resolve-Var 'zone_E'
$v_encryption_E                    = Resolve-Var 'encryption_E'
$v_secure_boot_E                   = Resolve-Var 'secure_boot_E'
$v_vtpm_E                          = Resolve-Var 'vtpm_E'
$v_image_publisher_E               = Resolve-Var 'image_publisher_E'
$v_image_offer_E                   = Resolve-Var 'image_offer_E'
$v_image_sku_E                     = Resolve-Var 'image_sku_E'
$v_image_version_E                 = Resolve-Var 'image_version_E'
$v_use_custom_image_E              = Resolve-Var 'use_custom_image_E'
$v_image_gallery_name_E            = Resolve-Var 'image_gallery_name_E'
$v_image_gallery_rg_E              = Resolve-Var 'image_gallery_rg_E'
$v_image_definition_name_E         = Resolve-Var 'image_definition_name_E'
$v_image_gallery_version_E         = Resolve-Var 'image_gallery_version_E'
$v_auto_shutdown_enabled_E         = Resolve-Var 'auto_shutdown_enabled_E'
$v_auto_shutdown_time_E            = Resolve-Var 'auto_shutdown_time_E'
$v_auto_shutdown_timezone_E        = Resolve-Var 'auto_shutdown_timezone_E'
$v_hostpool_name_E                 = Resolve-Var 'hostpool_name_E'
$v_hostpool_type_E                 = Resolve-Var 'hostpool_type_E'
$v_personal_desktop_assignment_type_E = Resolve-Var 'personal_desktop_assignment_type_E'
$v_load_balancer_type_E            = Resolve-Var 'load_balancer_type_E'
$v_max_sessions_E                  = Resolve-Var 'max_sessions_E'
$v_app_group_type_E                = Resolve-Var 'app_group_type_E'
$v_start_vm_on_connect_E           = Resolve-Var 'start_vm_on_connect_E'
$v_validate_env_E                  = Resolve-Var 'validate_env_E'
$v_app_group_name_E                = Resolve-Var 'app_group_name_E'
$v_app_group_friendly_name_E       = Resolve-Var 'app_group_friendly_name_E'
$v_workspace_name_E                = Resolve-Var 'workspace_name_E'
$v_workspace_name_friendly_name_E  = Resolve-Var 'workspace_name_friendly_name_E'
$v_expiration_date_E               = Resolve-Var 'expiration_date_E'
$v_custom_rdp_properties_E         = Resolve-Var 'custom_rdp_properties_E'

# custom_tags_E -- map type; build the block string
$tagsRaw = Resolve-Var 'custom_tags_E'
if ($tagsRaw -eq 'null' -or $tagsRaw -eq '{}') {
    $v_custom_tags_E = 'custom_tags_E = {}'
}
else {
    $v_custom_tags_E = 'custom_tags_E = ' + $tagsRaw
}

# ---------------------------------------------------------------------------
# 6.  BUILD TFVARS CONTENT LINE BY LINE  (avoids here-string variable issues)
# ---------------------------------------------------------------------------
$nl   = [System.Environment]::NewLine
$sep  = '# ==================================================================='
$lines = New-Object System.Collections.Generic.List[string]

$lines.Add($sep)
$lines.Add('# USE CASE SELECTION (1-9)')
$lines.Add($sep)
$lines.Add('# UC1: Hybrid (ADDS+EntraID), ADDS-joined SH, FSLogix=yes, OnPrem AD storage, GPO config')
$lines.Add('# UC2: Hybrid (ADDS+EntraID), ADDS-joined SH, FSLogix=yes, AADKERB storage, Registry Key')
$lines.Add('# UC3: Hybrid (ADDS+EntraID), EntraID-joined SH, FSLogix=yes, AADKERB storage, Registry Key')
$lines.Add('# UC4: Hybrid (ADDS+EntraID), EntraID-joined SH, FSLogix=no')
$lines.Add('# UC5: Entra ID only, EntraID-joined SH, FSLogix=yes, AADKERB storage, Registry Key')
$lines.Add('# UC6: Entra ID only, EntraID-joined SH, FSLogix=no')
$lines.Add('# UC7: EntraID+AADDS, AADDS-joined SH, FSLogix=yes, AADKERB storage, GPO (external)')
$lines.Add('# UC8: EntraID+AADDS, EntraID-joined SH, FSLogix=yes, AADKERB storage, Registry Key')
$lines.Add('# UC9: EntraID+AADDS, AADDS/EntraID-joined SH, FSLogix=no')
$lines.Add($sep)
$lines.Add('')
$lines.Add('use_case = ' + $v_use_case)
$lines.Add('')
$lines.Add($sep)
$lines.Add('# GENERAL')
$lines.Add($sep)
$lines.Add('azure_subscription_id_E = ' + $v_azure_subscription_id_E)
$lines.Add('folllowNomenclature_E   = ' + $v_folllowNomenclature_E)
$lines.Add('env_E                   = ' + $v_env_E)
$lines.Add('location_E              = ' + $v_location_E)
$lines.Add('')
$lines.Add($sep)
$lines.Add('# EXISTING RESOURCES  (set to null to create new ones)')
$lines.Add($sep)
$lines.Add('existing_RGname               = ' + $v_existing_RGname)
$lines.Add('existing_vNet_name            = ' + $v_existing_vNet_name)
$lines.Add('existing_vNet_address         = ' + $v_existing_vNet_address)
$lines.Add('existing_subnet               = ' + $v_existing_subnet)
$lines.Add('existing_storage_account_name = ' + $v_existing_storage_account_name)
$lines.Add('')
$lines.Add($sep)
$lines.Add('# RESOURCE GROUP')
$lines.Add($sep)
$lines.Add('newRGname_E = ' + $v_newRGname_E)
$lines.Add('')
$lines.Add($sep)
$lines.Add('# VIRTUAL NETWORK')
$lines.Add($sep)
$lines.Add('vnet_name_E  = ' + $v_vnet_name_E)
$lines.Add('subnet_names = ' + $v_subnet_names)
$lines.Add('')
$lines.Add('# vnet_cidr_E    -- address space of the new VNet  (e.g. ["10.10.0.0/16"])')
$lines.Add('# subnet_cidrs_E -- one CIDR per subnet, must match count in subnet_names')
$lines.Add('vnet_cidr_E    = ' + $v_vnet_cidr_E)
$lines.Add('subnet_cidrs_E = ' + $v_subnet_cidrs_E)
$lines.Add('')
$lines.Add($sep)
$lines.Add('# VNET PEERING (UC 1,2,3,4 only -- set enable_vnet_peering_E = true to activate)')
$lines.Add('# peer_vnet_id_E format:')
$lines.Add('#   /subscriptions/{subscriptionId}/resourceGroups/{rg}/providers/Microsoft.Network/virtualNetworks/{vnetName}')
$lines.Add($sep)
$lines.Add('enable_vnet_peering_E          = ' + $v_enable_vnet_peering_E)
$lines.Add('peer_vnet_name_E               = ' + $v_peer_vnet_name_E)
$lines.Add('peer_vnet_id_E                 = ' + $v_peer_vnet_id_E)
$lines.Add('peer_vnet_rg_E                 = ' + $v_peer_vnet_rg_E)
$lines.Add('peer_allow_forwarded_traffic_E = ' + $v_peer_allow_forwarded_traffic_E)
$lines.Add('peer_allow_gateway_transit_E   = ' + $v_peer_allow_gateway_transit_E)
$lines.Add('peer_use_remote_gateways_E     = ' + $v_peer_use_remote_gateways_E)
$lines.Add('')
$lines.Add('# Custom DNS -- set to your AD Domain Controller IP so VMs can find the domain')
$lines.Add('dns_servers_E = ' + $v_dns_servers_E)
$lines.Add('')
$lines.Add($sep)
$lines.Add('# STORAGE ACCOUNT (required for UC 1,2,3,5,7,8 -- ignored for UC 4,6,9)')
$lines.Add($sep)
$lines.Add('storage_name_E           = ' + $v_storage_name_E)
$lines.Add('account_tier_E           = ' + $v_account_tier_E)
$lines.Add('replication_type_E       = ' + $v_replication_type_E)
$lines.Add('share_level_permission_E = ' + $v_share_level_permission_E)
$lines.Add('')
$lines.Add($sep)
$lines.Add('# ON-PREM AD FIELDS (required for UC1 storage + UC1/2 domain join)')
$lines.Add($sep)
$lines.Add('domain_name_E         = ' + $v_domain_name_E)
$lines.Add('domain_guid_E         = ' + $v_domain_guid_E)
$lines.Add('domain_sid_E          = ' + $v_domain_sid_E)
$lines.Add('forest_name_E         = ' + $v_forest_name_E)
$lines.Add('netbios_domain_name_E = ' + $v_netbios_domain_name_E)
$lines.Add('storage_sid_E         = ' + $v_storage_sid_E)
$lines.Add('')
$lines.Add('# AD domain join credentials (for UC 1, 2)')
$lines.Add('OUPath_E                 = ' + $v_OUPath_E)
$lines.Add('ad_admin_user_name_E     = ' + $v_ad_admin_user_name_E)
$lines.Add('ad_admin_user_password_E = ' + $v_ad_admin_user_password_E)
$lines.Add('')
$lines.Add($sep)
$lines.Add('# AADDS FIELDS (required for UC 7, 9 with AADDS join -- null otherwise)')
$lines.Add($sep)
$lines.Add('aadds_domain_name_E         = ' + $v_aadds_domain_name_E)
$lines.Add('aadds_ou_path_E             = ' + $v_aadds_ou_path_E)
$lines.Add('aadds_admin_user_name_E     = ' + $v_aadds_admin_user_name_E)
$lines.Add('aadds_admin_user_password_E = ' + $v_aadds_admin_user_password_E)
$lines.Add('')
$lines.Add($sep)
$lines.Add('# FILE SHARE (required for UC 1,2,3,5,7,8)')
$lines.Add($sep)
$lines.Add('fileshare_name_E = ' + $v_fileshare_name_E)
$lines.Add('quota_E          = ' + $v_quota_E)
$lines.Add('')
$lines.Add($sep)
$lines.Add('# SESSION HOST VMs')
$lines.Add($sep)
$lines.Add('sessionHost_name_E    = ' + $v_sessionHost_name_E)
$lines.Add('sh_count_E            = ' + $v_sh_count_E)
$lines.Add('sku_E                 = ' + $v_sku_E)
$lines.Add('admin_username_E      = ' + $v_admin_username_E)
$lines.Add('admin_password_E      = ' + $v_admin_password_E)
$lines.Add('os_disk_st_acc_type_E = ' + $v_os_disk_st_acc_type_E)
$lines.Add('zone_E                = ' + $v_zone_E)
$lines.Add('encryption_E          = ' + $v_encryption_E)
$lines.Add('secure_boot_E         = ' + $v_secure_boot_E)
$lines.Add('vtpm_E                = ' + $v_vtpm_E)
$lines.Add('image_publisher_E     = ' + $v_image_publisher_E)
$lines.Add('image_offer_E         = ' + $v_image_offer_E)
$lines.Add('image_sku_E           = ' + $v_image_sku_E)
$lines.Add('image_version_E       = ' + $v_image_version_E)
$lines.Add('')
$lines.Add($sep)
$lines.Add('# CUSTOM IMAGE FROM AZURE COMPUTE GALLERY')
$lines.Add('# Set use_custom_image_E = true to use gallery image instead of marketplace.')
$lines.Add('# When true:  image_gallery_name_E, image_gallery_rg_E, image_definition_name_E required.')
$lines.Add('# When false: marketplace image (image_publisher_E / image_offer_E / image_sku_E) used.')
$lines.Add($sep)
$lines.Add('use_custom_image_E      = ' + $v_use_custom_image_E)
$lines.Add('image_gallery_name_E    = ' + $v_image_gallery_name_E)
$lines.Add('image_gallery_rg_E      = ' + $v_image_gallery_rg_E)
$lines.Add('image_definition_name_E = ' + $v_image_definition_name_E)
$lines.Add('image_gallery_version_E = ' + $v_image_gallery_version_E)
$lines.Add('')
$lines.Add('# Auto-shutdown -- set auto_shutdown_enabled_E = true to activate')
$lines.Add('# Time format: HHMM in 24-hour clock (e.g. "1900" = 7:00 PM)')
$lines.Add('# Timezone: Windows timezone name (e.g. "India Standard Time", "UTC")')
$lines.Add('auto_shutdown_enabled_E  = ' + $v_auto_shutdown_enabled_E)
$lines.Add('auto_shutdown_time_E     = ' + $v_auto_shutdown_time_E)
$lines.Add('auto_shutdown_timezone_E = ' + $v_auto_shutdown_timezone_E)
$lines.Add('')
$lines.Add($sep)
$lines.Add('# HOST POOL')
$lines.Add($sep)
$lines.Add('hostpool_name_E                    = ' + $v_hostpool_name_E)
$lines.Add('hostpool_type_E                    = ' + $v_hostpool_type_E)
$lines.Add('personal_desktop_assignment_type_E = ' + $v_personal_desktop_assignment_type_E)
$lines.Add('load_balancer_type_E               = ' + $v_load_balancer_type_E)
$lines.Add('max_sessions_E                     = ' + $v_max_sessions_E)
$lines.Add('app_group_type_E                   = ' + $v_app_group_type_E)
$lines.Add('start_vm_on_connect_E              = ' + $v_start_vm_on_connect_E)
$lines.Add('validate_env_E                     = ' + $v_validate_env_E)
$lines.Add('')
$lines.Add($sep)
$lines.Add('# APPLICATION GROUP & WORKSPACE')
$lines.Add($sep)
$lines.Add('app_group_name_E               = ' + $v_app_group_name_E)
$lines.Add('app_group_friendly_name_E      = ' + $v_app_group_friendly_name_E)
$lines.Add('workspace_name_E               = ' + $v_workspace_name_E)
$lines.Add('workspace_name_friendly_name_E = ' + $v_workspace_name_friendly_name_E)
$lines.Add('')
$lines.Add($sep)
$lines.Add('# CUSTOM TAGS (optional -- merged with mandatory tags CreationTimeUTC, Environment, ServiceWorkload)')
$lines.Add($sep)
$lines.Add($v_custom_tags_E)
$lines.Add('')
$lines.Add($sep)
$lines.Add('# REGISTRATION')
$lines.Add($sep)
$lines.Add('expiration_date_E = ' + $v_expiration_date_E)
$lines.Add('')
$lines.Add($sep)
$lines.Add('# HOST POOL RDP PROPERTIES (Advanced Tab)')
$lines.Add('# Semicolon-separated RDP property strings.')
$lines.Add('# Required for Entra ID joined session hosts (UC 3,4,5,6,8).')
$lines.Add('# targetisaadjoined:i:1  -- marks host pool as Entra ID (AAD) joined')
$lines.Add('# enablerdsaadauth:i:1   -- enables Entra ID authentication for RDP connections')
$lines.Add($sep)
$lines.Add('custom_rdp_properties_E = ' + $v_custom_rdp_properties_E)

# ---------------------------------------------------------------------------
# 7.  WRITE OUTPUT FILE
# ---------------------------------------------------------------------------
$content = [string]::Join($nl, $lines.ToArray()) + $nl

[System.IO.File]::WriteAllText($TfvarsPath, $content, [System.Text.Encoding]::UTF8)

Write-Host ''
Write-Host 'terraform.tfvars written successfully:' -ForegroundColor Green
Write-Host "  $TfvarsPath" -ForegroundColor White
Write-Host ''
Write-Host 'Next steps:' -ForegroundColor Cyan
Write-Host '  1.  terraform init    (if first run or modules changed)'
Write-Host '  2.  terraform plan    (review changes)'
Write-Host '  3.  terraform apply   (deploy)'