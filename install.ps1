# install.ps1 - One-line installer for Driver Updater CLI
# Usage: irm https://raw.githubusercontent.com/vrs600/driver-updater/main/install.ps1 | iex

$ErrorActionPreference = 'Stop'

Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Driver Updater CLI - Quick Installer" -ForegroundColor Green
Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Check admin rights
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "⚠ Administrator privileges required!" -ForegroundColor Yellow
    Write-Host "Rerun this command in an elevated PowerShell window." -ForegroundColor Yellow
    exit 1
}

# Set execution policy
Write-Host "[1/3] Configuring PowerShell..." -ForegroundColor Cyan
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
Write-Host "✓ Execution policy set" -ForegroundColor Green

# Download script
Write-Host "[2/3] Downloading Driver Updater..." -ForegroundColor Cyan
$scriptUrl = "https://raw.githubusercontent.com/vrs600/driver-updater/main/Update-Drivers.ps1"
$installPath = "$env:ProgramFiles\DriverUpdater"
$scriptPath = "$installPath\Update-Drivers.ps1"

try {
    # Create directory
    if (-not (Test-Path $installPath)) {
        New-Item -ItemType Directory -Path $installPath -Force | Out-Null
    }
    
    # Download script
    Invoke-WebRequest -Uri $scriptUrl -OutFile $scriptPath -UseBasicParsing
    Write-Host "✓ Script downloaded to: $scriptPath" -ForegroundColor Green
} catch {
    Write-Host "✗ Download failed: $_" -ForegroundColor Red
    exit 1
}

# Add to PATH
Write-Host "[3/3] Adding to system PATH..." -ForegroundColor Cyan
$currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
if ($currentPath -notlike "*$installPath*") {
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$installPath", "Machine")
    $env:Path = "$env:Path;$installPath"
    Write-Host "✓ Added to PATH" -ForegroundColor Green
} else {
    Write-Host "✓ Already in PATH" -ForegroundColor Green
}

# Create alias script
$aliasScript = @"
# Run Driver Updater
& "$scriptPath" `$args
"@
Set-Content -Path "$installPath\driver-updater.ps1" -Value $aliasScript -Force

Write-Host ""
Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Installation Complete!" -ForegroundColor Green
Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Usage:" -ForegroundColor Yellow
Write-Host "  powershell -File `"$scriptPath`" -Scan"
Write-Host "  powershell -File `"$scriptPath`" -Install"
Write-Host "  powershell -File `"$scriptPath`" -Help"
Write-Host ""
Write-Host "Or create a shortcut command in your PowerShell profile." -ForegroundColor Gray
Write-Host ""

# Offer to run now
$run = Read-Host "Run driver scan now? (Y/N)"
if ($run -eq 'Y') {
    & $scriptPath -Scan
}
