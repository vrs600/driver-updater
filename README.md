# 🚀 Driver Updater CLI

A powerful PowerShell CLI tool for automated Windows driver management with built-in rollback support.

## ✨ Features

- 🔍 **Smart Scanning** - Detect outdated drivers from Windows Update catalog
- ⚡ **Automated Installation** - Install all driver updates with progress tracking
- 🛡️ **Safety First** - Automatic system restore points before updates
- ↩️ **Easy Rollback** - Quick rollback options if something goes wrong
- 📊 **Progress Tracking** - Real-time progress indicators during installation
- 🎯 **CLI-First** - Simple command-line interface for power users

## 📦 Quick Install

### One-Line Installation (Recommended)

Open PowerShell as **Administrator** and run:

```powershell
irm https://raw.githubusercontent.com/YOUR_USERNAME/driver-updater/main/install.ps1 | iex
```

### Manual Installation

1. Download `Update-Drivers.ps1`
2. Place it in a directory of your choice
3. Run from PowerShell as Administrator

## 🎮 Usage

### Scan for Updates
```powershell
.\Update-Drivers.ps1 -Scan
```

### Install All Updates
```powershell
.\Update-Drivers.ps1 -Install
```

### Install Without Restore Point
```powershell
.\Update-Drivers.ps1 -Install -NoRestorePoint
```

### Rollback Options
```powershell
.\Update-Drivers.ps1 -Rollback
```

### Show Help
```powershell
.\Update-Drivers.ps1 -Help
```

## 📋 Requirements

- Windows 10/11
- PowerShell 5.1 or later
- Administrator privileges
- Internet connection

## 🔒 Safety Features

- **Automatic Restore Points**: Creates a system restore point before any changes
- **Rollback Support**: Easy options to undo changes if needed
- **Error Handling**: Comprehensive error handling for safe operation
- **Progress Tracking**: Know exactly what's happening at each step

## 🛠️ How It Works

1. **Auto-Elevation**: Automatically requests admin rights if needed
2. **Dependency Check**: Installs PSWindowsUpdate module if missing
3. **Restore Point**: Creates a safety net before making changes
4. **Driver Scan**: Checks Windows Update for driver updates
5. **Installation**: Installs updates with real-time progress
6. **Rollback**: Provides options to undo changes if needed

## 🎯 Command Options

| Option | Description |
|--------|-------------|
| `-Scan` | Scan for available driver updates without installing |
| `-Install` | Install all available driver updates |
| `-Rollback` | Show rollback and uninstall options |
| `-NoRestorePoint` | Skip creating a system restore point |
| `-Help` | Display help information |

## 📸 Screenshots

```
═══════════════════════════════════════
    Driver Updater CLI v1.0
═══════════════════════════════════════

[1/4] Checking dependencies...
✓ PSWindowsUpdate module found
[2/4] Creating system restore point...
✓ Restore point created successfully
[3/4] Scanning for driver updates...
✓ Found 3 driver update(s)

Available Updates:
─────────────────────────────────────
Driver                           KB        Size
Intel Graphics Driver           KB5123456  125.50 MB
Realtek Audio Driver            KB5123457  45.20 MB
```

## ⚠️ Important Notes

- Always run as Administrator
- Creates system restore points by default (can be skipped with `-NoRestorePoint`)
- Requires reboot after installation for changes to take effect
- Only installs drivers from official Windows Update catalog

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🐛 Issues

Found a bug or have a feature request? Please open an issue on GitHub.

## ⭐ Support

If you find this tool helpful, please consider giving it a star on GitHub!

## 📧 Contact

- GitHub: [@YOUR_USERNAME](https://github.com/YOUR_USERNAME)
- Issues: [GitHub Issues](https://github.com/YOUR_USERNAME/driver-updater/issues)

## 🔄 Changelog

### v1.0.0 (Initial Release)
- Initial release with core functionality
- Driver scanning and installation
- System restore point creation
- Rollback support
- Progress tracking
- Error handling

---

**⚠️ Disclaimer**: Use at your own risk. Always create backups before updating drivers. This tool uses the official Windows Update catalog.
