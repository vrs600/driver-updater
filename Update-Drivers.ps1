param(
    [switch]$Scan,
    [switch]$Install,
    [switch]$Rollback,
    [switch]$NoRestorePoint,
    [switch]$Help
)

# ===============================
# Elevation
# ===============================
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)

if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Administrator privileges required." -ForegroundColor Yellow
    Write-Host "UAC prompt will appear. Click YES." -ForegroundColor Yellow
    Start-Process powershell.exe -Verb RunAs `
        -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

# ===============================
# Header
# ===============================
Clear-Host
Write-Host "======================================" -ForegroundColor Cyan
Write-Host " Driver Updater CLI v1.0" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

if ($Help) {
    Write-Host "USAGE:"
    Write-Host "  .\Update-Drivers.ps1 -Scan"
    Write-Host "  .\Update-Drivers.ps1 -Install"
    Write-Host "  .\Update-Drivers.ps1 -Rollback"
    exit
}

# ===============================
# Dependency
# ===============================
if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    Write-Host "Installing PSWindowsUpdate module..." -ForegroundColor Cyan
    Install-Module PSWindowsUpdate -Force -Scope AllUsers
}
Import-Module PSWindowsUpdate

# ===============================
# Restore Point
# ===============================
if (-not $NoRestorePoint) {
    Write-Host "Creating restore point (if enabled)..." -ForegroundColor Cyan
    Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
    Checkpoint-Computer -Description "Before Driver Update" `
        -RestorePointType MODIFY_SETTINGS `
        -ErrorAction SilentlyContinue
}

# ===============================
# Rollback
# ===============================
if ($Rollback) {
    Write-Host ""
    Write-Host "Rollback Options" -ForegroundColor Yellow
    Write-Host "1. Open System Restore"
    Write-Host "2. View installed driver updates"
    Write-Host "3. Exit"

    $choice = Read-Host "Select option"

    if ($choice -eq "1") {
        rstrui.exe
    }
    elseif ($choice -eq "2") {
        Get-WindowsUpdate -MicrosoftUpdate -UpdateType Driver -IsInstalled |
        Format-Table Title, KB, InstalledOn -AutoSize
    }
    exit
}

# ===============================
# Scan
# ===============================
Write-Host "Scanning for driver updates..." -ForegroundColor Cyan
Write-Progress -Activity "Scanning Drivers" -Status "Checking Microsoft Update" -PercentComplete 50

$updates = Get-WindowsUpdate -MicrosoftUpdate -UpdateType Driver -ErrorAction SilentlyContinue

Write-Progress -Completed -Activity "Scanning Drivers"

if (-not $updates) {
    Write-Host "All drivers are already up to date." -ForegroundColor Green
    Write-Host ""
    Write-Host "Press ENTER to exit..." -ForegroundColor Yellow
    Read-Host
    return
}


Write-Host "Found $($updates.Count) driver update(s):" -ForegroundColor Green
$updates | Select Title, KB, Size | Format-Table -AutoSize

if ($Scan) {
    exit
}

# ===============================
# Install
# ===============================
if ($Install) {
    $total = $updates.Count
    $index = 0

    foreach ($u in $updates) {
        $index++
        Write-Progress `
            -Activity "Installing Drivers" `
            -Status $u.Title `
            -PercentComplete (($index / $total) * 100)

        Install-WindowsUpdate `
            -KBArticleID $u.KB `
            -AcceptAll `
            -IgnoreReboot `
            -Confirm:$false | Out-Null

        Write-Host "Installed: $($u.Title)" -ForegroundColor Green
    }

    Write-Progress -Completed -Activity "Installing Drivers"

    Write-Host ""
    $reboot = Read-Host "Reboot now? (Y/N)"
    if ($reboot -eq "Y") {
        Restart-Computer -Force
    }
}

