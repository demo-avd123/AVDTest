# Fix FSLogix Azure AD Kerberos Access
# Run this on the SESSION HOST via Azure Portal > Run Command

Write-Host "=== FSLogix Azure AD Kerberos Fix ===" -ForegroundColor Green

# 1. Enable Cloud Kerberos Ticket Retrieval
Write-Host "`n[Step 1] Enabling Cloud Kerberos Ticket Retrieval..." -ForegroundColor Yellow
$kerberosPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\Parameters"
if (!(Test-Path $kerberosPath)) {
    New-Item -Path $kerberosPath -Force | Out-Null
}
Set-ItemProperty -Path $kerberosPath -Name "CloudKerberosTicketRetrievalEnabled" -Value 1 -Type DWord -Force
Write-Host "[OK] Cloud Kerberos enabled" -ForegroundColor Green

# 2. Verify FSLogix Configuration
Write-Host "`n[Step 2] Verifying FSLogix Configuration..." -ForegroundColor Yellow
$fslogixPath = "HKLM:\SOFTWARE\FSLogix\Profiles"
if (Test-Path $fslogixPath) {
    $vhdLocation = (Get-ItemProperty -Path $fslogixPath -Name "VHDLocations" -ErrorAction SilentlyContinue).VHDLocations
    $enabled = (Get-ItemProperty -Path $fslogixPath -Name "Enabled" -ErrorAction SilentlyContinue).Enabled
    
    Write-Host "VHDLocations: $vhdLocation" -ForegroundColor Cyan
    Write-Host "Enabled: $enabled" -ForegroundColor Cyan
    
    if ($enabled -ne 1) {
        Set-ItemProperty -Path $fslogixPath -Name "Enabled" -Value 1 -Type DWord -Force
        Write-Host "[FIXED] FSLogix now enabled" -ForegroundColor Green
    }
} else {
    Write-Host "[ERROR] FSLogix not configured!" -ForegroundColor Red
    exit 1
}

# 3. Clear cached Kerberos tickets
Write-Host "`n[Step 3] Clearing cached Kerberos tickets..." -ForegroundColor Yellow
klist purge
Write-Host "[OK] Kerberos ticket cache cleared" -ForegroundColor Green

# 4. Test Azure AD authentication
Write-Host "`n[Step 4] Testing Azure AD authentication..." -ForegroundColor Yellow
$token = az account get-access-token --resource https://storage.azure.com/ --query accessToken -o tsv 2>$null
if ($token) {
    Write-Host "[OK] Azure AD authentication working" -ForegroundColor Green
} else {
    Write-Host "[WARNING] Azure CLI not authenticated - this is OK if you're testing as end user" -ForegroundColor Yellow
}

# 5. Get new Kerberos ticket for storage
Write-Host "`n[Step 5] Requesting Kerberos ticket for Azure Files..." -ForegroundColor Yellow
if ($vhdLocation) {
    try {
        # Extract storage account FQDN
        if ($vhdLocation -match '\\\\(.+?)\\') {
            $storageFqdn = $matches[1]
            Write-Host "Storage FQDN: $storageFqdn" -ForegroundColor Cyan
            
            # Request Kerberos ticket
            $output = cmdkey /generic:"$storageFqdn" /user:"Azure\$env:COMPUTERNAME$" /pass:"" 2>&1
            Write-Host "[OK] Kerberos ticket requested" -ForegroundColor Green
        }
    } catch {
        Write-Host "[ERROR] Failed to request Kerberos ticket: $_" -ForegroundColor Red
    }
}

# 6. Test file share access using current machine context
Write-Host "`n[Step 6] Testing file share access..." -ForegroundColor Yellow
if ($vhdLocation) {
    try {
        # Use PSDrive to test access with current credentials
        $testPath = $vhdLocation
        $testResult = Test-Path $testPath -ErrorAction Stop
        
        if ($testResult) {
            Write-Host "[OK] File share is accessible!" -ForegroundColor Green
            
            # Try to create a test file
            $testFile = Join-Path $testPath "test_$(Get-Date -Format 'yyyyMMddHHmmss').txt"
            "Test" | Out-File $testFile -ErrorAction SilentlyContinue
            
            if (Test-Path $testFile) {
                Remove-Item $testFile -Force
                Write-Host "[OK] Write access confirmed!" -ForegroundColor Green
            } else {
                Write-Host "[WARNING] Read-only access (check RBAC permissions)" -ForegroundColor Yellow
            }
        } else {
            Write-Host "[ERROR] Cannot access file share" -ForegroundColor Red
        }
    } catch {
        Write-Host "[ERROR] Access failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "`nPossible causes:" -ForegroundColor Yellow
        Write-Host "1. VM system identity missing RBAC role on storage account" -ForegroundColor Yellow
        Write-Host "2. Storage account not configured for Azure AD Kerberos" -ForegroundColor Yellow
        Write-Host "3. Network connectivity issue (port 445 blocked)" -ForegroundColor Yellow
    }
}

# 7. Check if AADLoginForWindows extension is installed
Write-Host "`n[Step 7] Checking Azure AD Login extension..." -ForegroundColor Yellow
$aadExtension = Get-Service "AzureADAuthenticationForWindowsService" -ErrorAction SilentlyContinue
if ($aadExtension) {
    Write-Host "[OK] AADLoginForWindows extension installed: $($aadExtension.Status)" -ForegroundColor Green
    
    if ($aadExtension.Status -ne 'Running') {
        Start-Service "AzureADAuthenticationForWindowsService"
        Write-Host "[FIXED] Service started" -ForegroundColor Green
    }
} else {
    Write-Host "[WARNING] AADLoginForWindows extension not found" -ForegroundColor Yellow
}

# 8. Show current Kerberos tickets
Write-Host "`n[Step 8] Current Kerberos Tickets..." -ForegroundColor Yellow
klist

Write-Host "`n=== IMPORTANT NOTES ===" -ForegroundColor Cyan
Write-Host "1. For Azure AD Kerberos, you should NOT enter username/password" -ForegroundColor Yellow
Write-Host "2. Authentication happens automatically using the VM's Azure AD identity" -ForegroundColor Yellow
Write-Host "3. The VM must be Azure AD joined (AADLoginForWindows extension)" -ForegroundColor Yellow
Write-Host "4. The VM's system-assigned identity needs RBAC role on storage account" -ForegroundColor Yellow
Write-Host "`n5. If using File Explorer to access share:" -ForegroundColor Yellow
Write-Host "   - Enter UNC path: $vhdLocation" -ForegroundColor Cyan
Write-Host "   - Do NOT click 'Enter network credentials'" -ForegroundColor Red
Write-Host "   - Let it authenticate automatically" -ForegroundColor Green
Write-Host "`n6. If prompted for credentials:" -ForegroundColor Yellow
Write-Host "   - Close the dialog" -ForegroundColor Cyan
Write-Host "   - Restart the computer" -ForegroundColor Cyan
Write-Host "   - Try again after restart" -ForegroundColor Cyan

Write-Host "`n=== Next Steps ===" -ForegroundColor Green
Write-Host "1. Restart this VM to apply Kerberos settings" -ForegroundColor Yellow
Write-Host "2. After restart, file share should be accessible without credentials" -ForegroundColor Yellow
Write-Host "3. Log in as an Azure AD user via AVD" -ForegroundColor Yellow
Write-Host "4. FSLogix profile will be created automatically" -ForegroundColor Yellow
