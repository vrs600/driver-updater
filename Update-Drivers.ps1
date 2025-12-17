# ===============================
# Driver Updater CLI v1.0
# ===============================

param(
    [switch]$Help,
    [switch]$Scan,
    [switch]$Install,
    [switch]$Rollback,
    [switch]$NoRestorePoint
)

# ---- Display Help ----
function Show-Help {
    Write-Host @"
Driver Updater CLI - Automated Windows Driver Management

USAGE:
    .\Update-Drivers.ps1 [OPTIONS]

OPTIONS:
    -Scan              Scan for available driver updates
    -Install           Install all available driver updates
    -Rollback          Launch rollback options
    -NoRestorePoint    Skip creating system restore point
    -Help              Display this help message

EXAMPLES:
    .\Update-Drivers.ps1 -Scan
    .\Update-Drivers.ps1 -Install
    .\Update-Drivers.ps1 -Install -NoRestorePoint

REMOTE INSTALLATION:
    irm https://raw.githubusercontent.com/YOUR_USERNAME/driver-updater/main/install.ps1 | iex

"@ -ForegroundColor Cyan
}

# ---- Auto Elevation ----
function Test-Admin {
    ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Admin)) {
    Write-Host "Requesting administrator privileges..." -ForegroundColor Yellow
    $args = "-ExecutionPolicy Bypass -File `"$PSCommandPath`" " + ($PSBoundParameters.Keys | ForEach-Object { "-$_ " }) -join " "
    Start-Process powershell -ArgumentList $args -Verb RunAs
    exit
}

# ---- Main Header ----
Clear-Host
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "    Driver Updater CLI v1.0" -ForegroundColor Green
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Show help if requested
if ($Help) {
    Show-Help
    exit
}

# ---- Install Module ----
function Install-UpdateModule {
    Write-Host "[1/4] Checking dependencies..." -ForegroundColor Cyan
    if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        Write-Progress -Activity "Setup" -Status "Installing PSWindowsUpdate module" -PercentComplete 25
        try {
            Install-Module PSWindowsUpdate -Force -Scope AllUsers -ErrorAction Stop
            Write-Host "✓ PSWindowsUpdate module installed" -ForegroundColor Green
        } catch {
            Write-Host "✗ Failed to install module: $_" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "✓ PSWindowsUpdate module found" -ForegroundColor Green
    }
    Import-Module PSWindowsUpdate -ErrorAction Stop
}

# ---- Create Restore Point ----
function New-DriverRestorePoint {
    if ($NoRestorePoint) {
        Write-Host "[2/4] Skipping restore point creation" -ForegroundColor Yellow
        return
    }
    
    Write-Host "[2/4] Creating system restore point..." -ForegroundColor Cyan
    try {
        Checkpoint-Computer -Description "Before Driver Update $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-Host "✓ Restore point created successfully" -ForegroundColor Green
    } catch {
        Write-Host "⚠ Could not create restore point: $_" -ForegroundColor Yellow
        $continue = Read-Host "Continue anyway? (Y/N)"
        if ($continue -ne 'Y') { exit }
    }
}

# ---- Scan Drivers ----
function Get-DriverUpdates {
    Write-Host "[3/4] Scanning for driver updates..." -ForegroundColor Cyan
    Write-Progress -Activity "Scanning" -Status "Checking Windows Update catalog" -PercentComplete 50
    
    try {
        $updates = Get-WindowsUpdate -MicrosoftUpdate -UpdateType Driver -ErrorAction Stop
        Write-Progress -Completed -Activity "Scanning"
        
        if ($updates.Count -eq 0) {
            Write-Host "✓ All drivers are up to date!" -ForegroundColor Green
            return $null
        }
        
        Write-Host "✓ Found $($updates.Count) driver update(s)" -ForegroundColor Green
        Write-Host ""
        Write-Host "Available Updates:" -ForegroundColor Cyan
        Write-Host "─────────────────────────────────────" -ForegroundColor Gray
        $updates | Select-Object @{N='Driver';E={$_.Title}}, @{N='KB';E={$_.KB}}, @{N='Size';E={"{0:N2} MB" -f ($_.Size/1MB)}} | Format-Table -AutoSize
        
        return $updates
    } catch {
        Write-Host "✗ Error scanning for updates: $_" -ForegroundColor Red
        exit 1
    }
}

# ---- Install Drivers ----
function Install-DriverUpdates {
    param($Updates)
    
    if (-not $Updates) {
        Write-Host "No updates to install." -ForegroundColor Yellow
        return
    }
    
    Write-Host "[4/4] Installing driver updates..." -ForegroundColor Cyan
    $progress = 0
    $increment = 100 / $Updates.Count
    
    foreach ($update in $Updates) {
        $progress += $increment
        Write-Progress -Activity "Installing Drivers" -Status "Installing: $($update.Title)" -PercentComplete $progress
        
        try {
            Install-WindowsUpdate -KBArticleID $update.KB -AcceptAll -IgnoreReboot -Confirm:$false -ErrorAction Stop | Out-Null
            Write-Host "✓ Installed: $($update.Title)" -ForegroundColor Green
        } catch {
            Write-Host "✗ Failed: $($update.Title)" -ForegroundColor Red
        }
    }
    
    Write-Progress -Completed -Activity "Installing Drivers"
    Write-Host ""
    Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  Installation completed!" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
}

# ---- Rollback Menu ----
function Show-RollbackMenu {
    Write-Host ""
    Write-Host "Rollback Options:" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────" -ForegroundColor Gray
    Write-Host "1. Launch System Restore"
    Write-Host "2. Uninstall last driver update"
    Write-Host "3. View installed updates"
    Write-Host "4. Exit"
    Write-Host ""
    
    $choice = Read-Host "Select option (1-4)"
    
    switch ($choice) {
        "1" {
            Write-Host "Launching System Restore..." -ForegroundColor Cyan
            rstrui.exe
        }
        "2" {
            Write-Host "Fetching recent updates..." -ForegroundColor Cyan
            $recent = Get-WindowsUpdate -MicrosoftUpdate -UpdateType Driver -IsInstalled
            if ($recent) {
                $recent | Select-Object Title, KB, InstalledOn | Format-Table -AutoSize
                $kb = Read-Host "Enter KB number to uninstall"
                Write-Host "Uninstalling KB$kb..." -ForegroundColor Cyan
                Get-WindowsUpdate -KBArticleID $kb -Uninstall -Confirm:$false
            } else {
                Write-Host "No recent driver updates found." -ForegroundColor Yellow
            }
        }
        "3" {
            Write-Host "Installed driver updates:" -ForegroundColor Cyan
            Get-WindowsUpdate -MicrosoftUpdate -UpdateType Driver -IsInstalled | Select-Object Title, KB, InstalledOn | Format-Table -AutoSize
        }
        default {
            Write-Host "Exiting..." -ForegroundColor Green
        }
    }
}

# ---- Main Execution ----
try {
    if ($Rollback) {
        Install-UpdateModule
        Show-RollbackMenu
        exit
    }
    
    Install-UpdateModule
    
    if (-not $NoRestorePoint) {
        New-DriverRestorePoint
    }
    
    $updates = Get-DriverUpdates
    
    if ($Scan) {
        # Scan only mode
        exit
    }
    
    if ($Install -and $updates) {
        Install-DriverUpdates -Updates $updates
        
        Write-Host ""
        $reboot = Read-Host "Reboot now to apply changes? (Y/N)"
        if ($reboot -eq 'Y') {
            Restart-Computer -Force
        }
    } elseif (-not $Install -and $updates) {
        Write-Host ""
        $proceed = Read-Host "Install these updates? (Y/N)"
        if ($proceed -eq 'Y') {
            Install-DriverUpdates -Updates $updates
            
            Write-Host ""
            $reboot = Read-Host "Reboot now to apply changes? (Y/N)"
            if ($reboot -eq 'Y') {
                Restart-Computer -Force
            }
        }
    }
    
} catch {
    Write-Host ""
    Write-Host "✗ An error occurred: $_" -ForegroundColor Red
    exit 1
}
