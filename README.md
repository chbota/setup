# Setup Bootstrap Script

This directory contains a cross-platform bootstrap script for setting up a development environment with yadm (Yet Another Dotfiles Manager) and essential tools.

## Quick Start

### Execute from GitHub (Recommended)

You can run the setup script directly from GitHub without cloning the repository:

#### Linux/macOS/WSL:
```bash
curl -fsSL https://raw.githubusercontent.com/chbota/setup/main/setup-bootstrap.sh | bash
```

#### Windows (PowerShell) - Native Windows 11 Solution:
```powershell
# Download and execute the native PowerShell script (Works out of the box on Windows 11)
irm https://raw.githubusercontent.com/chbota/setup/main/setup-bootstrap.ps1 | iex
```


### Local Execution

If you've already cloned the repository:

#### Windows (PowerShell):
```powershell
cd setup
.\setup-bootstrap.ps1
```

#### Linux/macOS/WSL:
```bash
cd setup
chmod +x setup-bootstrap.sh
./setup-bootstrap.sh
```

## What the Script Does

The bootstrap script will:

1. **Detect your operating system** (Linux, macOS, Windows)
2. **Install required tools**:
   - **Windows**: winget (if missing), Git, GitHub CLI, yadm
   - **Linux/macOS**: GitHub CLI, yadm
3. **Authenticate with GitHub** (interactive login)
4. **Clone the setup-internal repository** via yadm
5. **Run platform-specific bootstrap scripts** from the yadm repository

## Prerequisites

### All Platforms
- Internet connection
- `curl` (usually pre-installed)

### Windows
- PowerShell 5.1+ or PowerShell 7+ (pre-installed on Windows 11)
- Windows 10/11
- Administrator privileges (recommended for best results)
- Internet connection for downloading tools

### Linux
- `curl` or `wget`
- Package manager (`apt`, `yum`, `dnf`, or `pacman`)

### macOS
- `curl` (pre-installed)
- Homebrew (optional, will be used if available)

## Troubleshooting

### GitHub CLI Installation Issues
If GitHub CLI installation fails:
- **Windows**: Try installing manually with `winget install GitHub.cli` or run PowerShell as Administrator
- **Linux/macOS**: Check if your package manager is supported or install manually

### yadm Installation Issues
If yadm installation fails:
- The script will fall back to downloading directly from GitHub
- Ensure `~/.local/bin` is in your PATH

### Authentication Issues
If GitHub authentication fails:
- Ensure you have a GitHub account
- Check your internet connection
- Try running `gh auth login` manually after the script completes

### Permission Issues
- **Windows**: Run PowerShell as Administrator
- **Linux/macOS**: Some operations may require `sudo`

### PowerShell Execution Policy Issues (Windows)
If you get an execution policy error:
```powershell
# Temporarily allow script execution for current session
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

# Or permanently allow for current user
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Manual Installation

If the automated script doesn't work, you can install components manually:

1. **Install GitHub CLI**: https://cli.github.com/
2. **Install yadm**: https://yadm.io/docs/install
3. **Authenticate**: `gh auth login`
4. **Clone dotfiles**: `yadm clone https://github.com/chbota/setup-internal.git`

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review the script output for error messages
3. Ensure all prerequisites are met
4. Check your internet connection and GitHub access
