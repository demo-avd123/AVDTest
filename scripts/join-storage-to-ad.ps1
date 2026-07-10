<#
.SYNOPSIS
    Joins an Azure Storage Account to on-premises Active Directory and outputs the storage SID.
.DESCRIPTION
    Called by Terraform null_resource local-exec provisioner.
    Requires: domain-joined machine, RSAT AD tools, Az PowerShell, AzFilesHybrid module.
.PARAMETER ResourceGroupName
    The resource group containing the storage account.
.PARAMETER StorageAccountName
    The name of the storage account to join.
.PARAMETER SubscriptionId
    The Azure subscription ID.
.PARAMETER OUDistinguishedName
    The OU where the computer account will be created (e.g. "OU=superavd_devices,DC=superavd,DC=com").
#>
param(
    [Parameter(Mandatory)] [string] $ResourceGroupName,
    [Parameter(Mandatory)] [string] $StorageAccountName,
    [Parameter(Mandatory)] [string] $SubscriptionId,
    [Parameter(Mandatory)] [string] $OUDistinguishedName
)

$ErrorActionPreference = "Stop"

Write-Host "=== Joining Storage Account '$StorageAccountName' to Active Directory ==="

# Ensure Az PowerShell is authenticated — always bootstrap fresh from Azure CLI
Write-Host "Setting Azure subscription context..."
Write-Host "Bootstrapping Az PowerShell session from Azure CLI..."
try {
    # Clear any stale Az context to avoid expired token issues
    Disconnect-AzAccount -ErrorAction SilentlyContinue | Out-Null
    $tokenJson = az account get-access-token --subscription $SubscriptionId 2>&1
    $tokenObj  = $tokenJson | ConvertFrom-Json
    $acctJson  = az account show --subscription $SubscriptionId 2>&1
    $acctObj   = $acctJson | ConvertFrom-Json
    Connect-AzAccount -AccessToken $tokenObj.accessToken `
                      -AccountId $acctObj.user.name `
                      -TenantId $acctObj.tenantId `
                      -SubscriptionId $SubscriptionId | Out-Null
    Write-Host "Authenticated Az PowerShell via Azure CLI token."
} catch {
    Write-Error "Failed to authenticate Az PowerShell. Please run 'az login' before terraform apply. Error: $_"
    exit 1
}

# Install AzFilesHybrid if not present (requires Windows PowerShell 5.1)
if ($PSVersionTable.PSVersion.Major -ge 7) {
    Write-Error "AzFilesHybrid is incompatible with PowerShell 7+. This script must run under Windows PowerShell 5.1 (powershell.exe)."
    exit 1
}
if (-not (Get-Module -ListAvailable -Name AzFilesHybrid)) {
    Write-Host "Installing AzFilesHybrid module..."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    if (-not (Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue)) {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser | Out-Null
    }
    Install-Module -Name AzFilesHybrid -Force -AllowClobber -Scope CurrentUser -Repository PSGallery
}
Import-Module AzFilesHybrid

# Join the storage account to AD
Write-Host "Running Join-AzStorageAccount..."
Join-AzStorageAccount `
    -ResourceGroupName $ResourceGroupName `
    -StorageAccountName $StorageAccountName `
    -DomainAccountType "ComputerAccount" `
    -OrganizationalUnitDistinguishedName $OUDistinguishedName `
    -OverwriteExistingADObject

# Verify and output the SID
$sa = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
$storageSid = $sa.AzureFilesIdentityBasedAuth.ActiveDirectoryProperties.AzureStorageSid
$dirType = $sa.AzureFilesIdentityBasedAuth.DirectoryServiceOptions

Write-Host "=== AD Join Complete ==="
Write-Host "Directory Type : $dirType"
Write-Host "Storage SID    : $storageSid"

if ([string]::IsNullOrWhiteSpace($storageSid)) {
    Write-Error "Storage SID is empty after join. AD join may have failed."
    exit 1
}

Write-Host "Storage account '$StorageAccountName' successfully joined to AD."
