# Grant Admin Consent for Storage Account Service Principal
# This script grants Microsoft Graph API permissions for Azure AD Kerberos authentication

param(
    [Parameter(Mandatory=$true)]
    [string]$StorageAccountName,
    
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId = "91730980-e77a-4529-aea1-3466efc66aa3"
)

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Grant Admin Consent for Storage Account" -ForegroundColor Cyan
Write-Host "================================`n" -ForegroundColor Cyan

# Set subscription context
Write-Host "Setting subscription context..." -ForegroundColor Yellow
az account set --subscription $SubscriptionId

# Get the storage account's service principal
Write-Host "Searching for storage account service principal: $StorageAccountName" -ForegroundColor Yellow
$appId = az ad sp list --filter "displayName eq '$StorageAccountName'" --query "[0].appId" -o tsv 2>$null

if ([string]::IsNullOrEmpty($appId)) {
    Write-Host "[ERROR] Storage account service principal not found!" -ForegroundColor Red
    Write-Host "This might be because:" -ForegroundColor Yellow
    Write-Host "  1. The storage account doesn't have a service principal (check if AADKERB is enabled)" -ForegroundColor Yellow
    Write-Host "  2. You need to wait a few minutes after enabling AADKERB" -ForegroundColor Yellow
    Write-Host "  3. You don't have permissions to view service principals" -ForegroundColor Yellow
    exit 1
}

Write-Host "[SUCCESS] Found service principal with App ID: $appId" -ForegroundColor Green

# Get Microsoft Graph service principal ID
$graphSpId = az ad sp list --filter "appId eq '00000003-0000-0000-c000-000000000000'" --query "[0].id" -o tsv

Write-Host "`nMicrosoft Graph Service Principal ID: $graphSpId" -ForegroundColor Gray

# Permission IDs for Microsoft Graph
$permissions = @{
    "User.Read" = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
    "openid"    = "37f7f235-527c-4136-accd-4a02d197296e"
    "profile"   = "14dad69e-099b-42c9-810b-d002981feec1"
}

Write-Host "`nAdding Microsoft Graph API permissions..." -ForegroundColor Yellow

# Add permissions
$permString = ($permissions.Values | ForEach-Object { "$_=Scope" }) -join " "
try {
    az ad app permission add --id $appId --api 00000003-0000-0000-c000-000000000000 --api-permissions $permString 2>&1 | Out-Null
    Write-Host "[SUCCESS] Permissions added" -ForegroundColor Green
} catch {
    Write-Host "[INFO] Permissions may already exist, continuing..." -ForegroundColor Yellow
}

Start-Sleep -Seconds 3

# Grant admin consent
Write-Host "`nGranting admin consent..." -ForegroundColor Yellow
try {
    $result = az ad app permission admin-consent --id $appId 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[SUCCESS] Admin consent granted successfully!" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] Admin consent command completed with warnings" -ForegroundColor Yellow
        Write-Host "Please verify in Azure Portal: Enterprise Applications > $StorageAccountName > Permissions" -ForegroundColor Yellow
    }
} catch {
    Write-Host "[ERROR] Failed to grant admin consent: $_" -ForegroundColor Red
    Write-Host "You may need to grant consent manually in the Azure Portal" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "Verification Steps:" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host "1. Go to Azure Portal > Microsoft Entra ID > App registrations" -ForegroundColor White
Write-Host "2. Search for: $StorageAccountName" -ForegroundColor White
Write-Host "3. Click 'API permissions'" -ForegroundColor White
Write-Host "4. Verify 'Status' column shows 'Granted for Default Directory'" -ForegroundColor White
Write-Host "`nOr via CLI:" -ForegroundColor Cyan
Write-Host "az ad app permission list --id $appId" -ForegroundColor Gray
Write-Host "`n[COMPLETE] Script finished!" -ForegroundColor Green
