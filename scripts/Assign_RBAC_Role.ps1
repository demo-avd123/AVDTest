# Quick Fix: Assign RBAC Role to VM Identity for Storage Access
# Run this from your LOCAL machine (where you have az cli logged in)

$subscriptionId = "a7b3fd46-ed11-4d0b-a19e-ed3daca48a66"
$rgName = "cac-factoryprfs-sach"
$vmName = "cac-sh-0-sach"
$storageAccountName = "cacstavdadpefslogixsach"

Write-Host "=== Assigning RBAC Role to VM Identity ===" -ForegroundColor Green

# Set subscription
az account set --subscription $subscriptionId

# Get VM's system-assigned managed identity
Write-Host "`nGetting VM identity..." -ForegroundColor Yellow
$vmIdentity = az vm show --resource-group $rgName --name $vmName --query "identity.principalId" -o tsv

if (!$vmIdentity) {
    Write-Host "[ERROR] VM has no system-assigned managed identity!" -ForegroundColor Red
    Write-Host "Enabling system-assigned identity now..." -ForegroundColor Yellow
    
    az vm identity assign --resource-group $rgName --name $vmName
    Start-Sleep -Seconds 10
    
    $vmIdentity = az vm show --resource-group $rgName --name $vmName --query "identity.principalId" -o tsv
    Write-Host "[OK] System-assigned identity enabled: $vmIdentity" -ForegroundColor Green
} else {
    Write-Host "[OK] VM Identity: $vmIdentity" -ForegroundColor Green
}

# Get storage account resource ID
Write-Host "`nGetting storage account ID..." -ForegroundColor Yellow
$storageId = az storage account show --name $storageAccountName --resource-group $rgName --query id -o tsv
Write-Host "[OK] Storage Account ID: $storageId" -ForegroundColor Green

# Check existing role assignments
Write-Host "`nChecking existing role assignments..." -ForegroundColor Yellow
$existingRoles = az role assignment list --assignee $vmIdentity --scope $storageId --query "[].roleDefinitionName" -o tsv

if ($existingRoles) {
    Write-Host "Existing roles:" -ForegroundColor Cyan
    $existingRoles | ForEach-Object { Write-Host "  - $_" -ForegroundColor Cyan }
} else {
    Write-Host "No existing roles found" -ForegroundColor Yellow
}

# Assign Storage File Data SMB Share Elevated Contributor role
Write-Host "`nAssigning 'Storage File Data SMB Share Elevated Contributor' role..." -ForegroundColor Yellow

try {
    az role assignment create `
        --assignee $vmIdentity `
        --role "Storage File Data SMB Share Elevated Contributor" `
        --scope $storageId
    
    Write-Host "[SUCCESS] Role assigned!" -ForegroundColor Green
} catch {
    if ($_.Exception.Message -like "*already exists*") {
        Write-Host "[OK] Role already assigned" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] Failed to assign role: $_" -ForegroundColor Red
    }
}

# Verify role assignment
Write-Host "`nVerifying role assignment..." -ForegroundColor Yellow
Start-Sleep -Seconds 5
$verifyRoles = az role assignment list --assignee $vmIdentity --scope $storageId --query "[].roleDefinitionName" -o tsv

Write-Host "`nFinal role assignments:" -ForegroundColor Green
$verifyRoles | ForEach-Object { Write-Host "  ✓ $_" -ForegroundColor Green }

Write-Host "`n=== NEXT STEPS ===" -ForegroundColor Cyan
Write-Host "1. Go to Azure Portal > VM > Restart" -ForegroundColor Yellow
Write-Host "2. After restart, run Fix_FSLogix_Access.ps1 on the VM via Run Command" -ForegroundColor Yellow
Write-Host "3. Do NOT enter credentials when accessing the file share" -ForegroundColor Yellow
Write-Host "4. Authentication happens automatically via Azure AD + Kerberos" -ForegroundColor Yellow
