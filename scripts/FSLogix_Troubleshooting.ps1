# FSLogix Profile Troubleshooting Script
# Run this on your session host VM via Azure Portal > Run Command

Write-Host "=== FSLogix Configuration Check ===" -ForegroundColor Green

# 1. Check if FSLogix is installed
$fslogixPath = "C:\Program Files\FSLogix\Apps"
if (Test-Path $fslogixPath) {
    Write-Host "[OK] FSLogix is installed at: $fslogixPath" -ForegroundColor Green
    $version = (Get-Item "$fslogixPath\frx.exe").VersionInfo.FileVersion
    Write-Host "    Version: $version" -ForegroundColor Cyan
} else {
    Write-Host "[ERROR] FSLogix is NOT installed!" -ForegroundColor Red
    Write-Host "        Download from: https://aka.ms/fslogix_download" -ForegroundColor Yellow
}

# 2. Check Registry Configuration
Write-Host "`n=== Registry Configuration ===" -ForegroundColor Green
$regPath = "HKLM:\SOFTWARE\FSLogix\Profiles"
if (Test-Path $regPath) {
    Write-Host "[OK] FSLogix registry key exists" -ForegroundColor Green
    
    $enabled = (Get-ItemProperty -Path $regPath -Name "Enabled" -ErrorAction SilentlyContinue).Enabled
    $vhdLocations = (Get-ItemProperty -Path $regPath -Name "VHDLocations" -ErrorAction SilentlyContinue).VHDLocations
    
    Write-Host "    Enabled: $enabled $(if($enabled -eq 1){'[OK]'}else{'[DISABLED]'})" -ForegroundColor $(if($enabled -eq 1){'Green'}else{'Red'})
    Write-Host "    VHDLocations: $vhdLocations" -ForegroundColor Cyan
    
    # Show all settings
    Write-Host "`n    All FSLogix Settings:" -ForegroundColor Yellow
    Get-ItemProperty -Path $regPath | Format-List
} else {
    Write-Host "[ERROR] FSLogix registry key NOT found!" -ForegroundColor Red
}

# 3. Test Storage Connectivity
Write-Host "`n=== Storage Connectivity Test ===" -ForegroundColor Green
$storageAccount = (Get-ItemProperty -Path $regPath -Name "VHDLocations" -ErrorAction SilentlyContinue).VHDLocations
if ($storageAccount) {
    # Extract storage account name from UNC path
    if ($storageAccount -match '\\\\(.+?)\.file\.core\.windows\.net') {
        $storageName = $matches[1]
        $fqdn = "$storageName.file.core.windows.net"
        
        Write-Host "Testing connection to: $fqdn" -ForegroundColor Cyan
        
        # DNS Resolution
        try {
            $dnsResult = Resolve-DnsName -Name $fqdn -ErrorAction Stop
            Write-Host "[OK] DNS Resolution: $($dnsResult[0].IPAddress)" -ForegroundColor Green
        } catch {
            Write-Host "[ERROR] DNS Resolution failed: $_" -ForegroundColor Red
        }
        
        # Port 445 (SMB)
        $tcpTest = Test-NetConnection -ComputerName $fqdn -Port 445 -WarningAction SilentlyContinue
        if ($tcpTest.TcpTestSucceeded) {
            Write-Host "[OK] Port 445 (SMB) is reachable" -ForegroundColor Green
        } else {
            Write-Host "[ERROR] Port 445 (SMB) is NOT reachable!" -ForegroundColor Red
            Write-Host "        Check NSG rules and firewall settings" -ForegroundColor Yellow
        }
        
        # Test UNC path access
        Write-Host "`nTesting UNC path: $storageAccount" -ForegroundColor Cyan
        if (Test-Path $storageAccount) {
            Write-Host "[OK] Can access file share!" -ForegroundColor Green
            $items = Get-ChildItem $storageAccount -ErrorAction SilentlyContinue
            Write-Host "    Files/Folders in share: $($items.Count)" -ForegroundColor Cyan
        } else {
            Write-Host "[ERROR] Cannot access file share!" -ForegroundColor Red
            Write-Host "        Possible causes:" -ForegroundColor Yellow
            Write-Host "        - Missing RBAC permissions (Storage File Data SMB Share Contributor)" -ForegroundColor Yellow
            Write-Host "        - Kerberos authentication not configured" -ForegroundColor Yellow
            Write-Host "        - VM identity not assigned proper roles" -ForegroundColor Yellow
        }
    }
}

# 4. Check Kerberos Configuration (for Azure AD Kerberos)
Write-Host "`n=== Kerberos Configuration ===" -ForegroundColor Green
$kerberosPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\Parameters"
if (Test-Path $kerberosPath) {
    $cloudKerb = (Get-ItemProperty-Path $kerberosPath -Name "CloudKerberosTicketRetrievalEnabled" -ErrorAction SilentlyContinue).CloudKerberosTicketRetrievalEnabled
    Write-Host "Cloud Kerberos Ticket Retrieval: $cloudKerb $(if($cloudKerb -eq 1){'[ENABLED]'}else{'[DISABLED]'})" -ForegroundColor $(if($cloudKerb -eq 1){'Green'}else{'Yellow'})
} else {
    Write-Host "[WARNING] Kerberos configuration not found" -ForegroundColor Yellow
}

# 5. Check FSLogix Services
Write-Host "`n=== FSLogix Services ===" -ForegroundColor Green
$services = @("frxsvc", "frxccds", "frxdrv")
foreach ($svc in $services) {
    $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($service) {
        $status = if($service.Status -eq 'Running'){'[RUNNING]'}else{"[$($service.Status)]"}
        $color = if($service.Status -eq 'Running'){'Green'}else{'Yellow'}
        Write-Host "    $($service.DisplayName): $status" -ForegroundColor $color
    }
}

# 6. Check Windows Event Logs for FSLogix errors
Write-Host "`n=== Recent FSLogix Events ===" -ForegroundColor Green
$events = Get-WinEvent -LogName "Microsoft-FSLogix-Apps/Operational" -MaxEvents 10 -ErrorAction SilentlyContinue
if ($events) {
    foreach ($event in $events) {
        $levelColor = switch ($event.LevelDisplayName) {
            "Error" { "Red" }
            "Warning" { "Yellow" }
            default { "White" }
        }
        Write-Host "[$($event.TimeCreated)] $($event.LevelDisplayName): $($event.Message)" -ForegroundColor $levelColor
    }
} else {
    Write-Host "[INFO] No FSLogix events found (normal if no users logged in yet)" -ForegroundColor Cyan
}

# 7. Current User Profile Type
Write-Host "`n=== Current User Profile ===" -ForegroundColor Green
$currentUser = $env:USERNAME
$profilePath = $env:USERPROFILE
Write-Host "Current User: $currentUser" -ForegroundColor Cyan
Write-Host "Profile Path: $profilePath" -ForegroundColor Cyan

if ($profilePath -like "*FSLogix*" -or $profilePath -like "*VHD*") {
    Write-Host "[OK] User is using FSLogix profile!" -ForegroundColor Green
} else {
    Write-Host "[INFO] User appears to be using local profile" -ForegroundColor Yellow
    Write-Host "       FSLogix profiles only activate on next login" -ForegroundColor Yellow
}

Write-Host "`n=== Summary ===" -ForegroundColor Green
Write-Host "1. If all checks pass but no profiles in share:" -ForegroundColor Yellow
Write-Host "   -> No users have logged in yet. Profiles create on first login." -ForegroundColor Cyan
Write-Host "`n2. If storage connectivity fails:" -ForegroundColor Yellow
Write-Host "   -> Assign 'Storage File Data SMB Share Contributor' role to VM identity" -ForegroundColor Cyan
Write-Host "`n3. If Kerberos disabled:" -ForegroundColor Yellow
Write-Host "   -> Run: New-ItemProperty -Path '$kerberosPath' -Name CloudKerberosTicketRetrievalEnabled -Value 1 -Force" -ForegroundColor Cyan
