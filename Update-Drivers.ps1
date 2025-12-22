param(
    [switch]$Scan,
    [switch]$Install,
    [switch]$Rollback,
    [switch]$Preview,
    [switch]$Silent,
    [switch]$NoRestorePoint,
    [switch]$Help
)

# ===============================
# Detect CMD host
# ===============================
$IsCMD = $env:ComSpec -and ($env:ComSpec -match "cmd.exe")

function Pause-CMD {
    if ($IsCMD -and -not $Silent) {
        Write-Host ""
        Write-Host "Press ENTER to return to CMD..." -ForegroundColor Yellow
        Read-Host | Out-Null
    }
}

function Safe-Exit {
    param([string]$Message)

    Write-Host ""
    if ($Message) {
        Write-Host $Message -ForegroundColor Cyan
    }

    Pause-CMD
    Stop-Transcript | Out-Null
    exit
}

# ===============================
# Globals
# ===============================
$ScriptVersion = "1.2.0"
$LogFile = "$env:TEMP\DriverUpdater.log"
$ProgressPreference = if ($Silent) { 'SilentlyContinue' } else { 'Continue' }

Start-Transcript -Path $LogFile -Append | Out-Null

# ===============================
# Elevation
# ===============================
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)

if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Administrator privileges required." -ForegroundColor Yellow
    Write-Host "UAC prompt will appear. Please approve." -ForegroundColor Yellow

    Start-Process powershell.exe -Verb RunAs `
        -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`""

    Pause-CMD
    Stop-Transcript | Out-Null
    exit
}

# ===============================
# Header
# ===============================
Clear-Host
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Driver Updater CLI v$ScriptVersion" -ForegroundColor Green
Write-Host " CMD Compatible Mode Enabled" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ===============================
# Help
# ===============================
if ($Help) {
    Write-Host "USAGE:"
    Write-Host "  powershell -File Update-Drivers.ps1 -Scan"
    Write-Host "  powershell -File Update-Drivers.ps1 -Install"
    Write-Host "  powershell -File Update-Drivers.ps1 -Preview"
    Write-Host "  powershell -File Update-Drivers.ps1 -Rollback"
    Safe-Exit "Help displayed."
}

# ===============================
# Interactive Menu
# ===============================
if (-not ($Scan -or $Install -or $Rollback -or $Preview)) {
    Write-Host "Select an option:" -ForegroundColor Cyan
    Write-Host "1. Scan drivers"
    Write-Host "2. Install driver updates"
    Write-Host "3. Preview updates (dry run)"
    Write-Host "4. Rollback options"
    Write-Host "5. Exit"

    switch (Read-Host "Enter choice") {
        "1" { $Scan = $true }
        "2" { $Install = $true }
        "3" { $Preview = $true }
        "4" { $Rollback = $true }
        default { Safe-Exit "Exited by user." }
    }
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
if (-not $NoRestorePoint -and $Install) {
    Write-Host "Creating restore point..." -ForegroundColor Cyan
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction Stop
        Checkpoint-Computer -Description "Before Driver Update" `
            -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
        Write-Host "Restore point created successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "Restore point could not be created." -ForegroundColor Yellow
    }
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

    Safe-Exit "Rollback operation finished."
}

# ===============================
# Scan
# ===============================
Write-Host "Scanning for driver updates..." -ForegroundColor Cyan
Write-Progress -Activity "Scanning Drivers" -Status "Querying Microsoft Update..."

$updates = Get-WindowsUpdate -MicrosoftUpdate -UpdateType Driver -ErrorAction SilentlyContinue

Write-Progress -Completed -Activity "Scanning Drivers"

if (-not $updates) {
    Write-Host "All drivers are already up to date." -ForegroundColor Green
    Safe-Exit "No updates available."
}

Write-Host ""
Write-Host "Found $($updates.Count) driver update(s):" -ForegroundColor Green
$updates | Select Title, KB, Size | Format-Table -AutoSize

if ($Scan) {
    Safe-Exit "Scan completed."
}

# ===============================
# Preview
# ===============================
if ($Preview) {
    Write-Host ""
    Write-Host "Preview mode (no changes will be made)" -ForegroundColor Yellow
    $updates | Select Title, KB, Size, DriverModel | Format-Table -AutoSize
    Safe-Exit "Preview completed."
}

# ===============================
# Install
# ===============================
if ($Install) {
    $total = $updates.Count
    $index = 0

    foreach ($u in $updates) {
        if ($u.Title -match "BIOS") {
            Write-Host "Skipping BIOS update: $($u.Title)" -ForegroundColor Yellow
            continue
        }

        if (-not $Silent) {
            $confirm = Read-Host "Install '$($u.Title)'? (Y/N/All)"
            if ($confirm -eq "All") { $Silent = $true }
            elseif ($confirm -ne "Y") { continue }
        }

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

    if (Get-WindowsUpdateRebootStatus) {
        Write-Host ""
        Write-Host "System reboot is required." -ForegroundColor Yellow
        if (-not $Silent) {
            if ((Read-Host "Reboot now? (Y/N)") -eq "Y") {
                Restart-Computer -Force
            }
        }
    }
}

Safe-Exit "Driver update process finished. Log saved at $LogFile"
