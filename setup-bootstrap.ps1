# Cross-platform bootstrap script for setting up development environment
# Native PowerShell version for Windows 10/11

[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$SkipAuth
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Check execution policy and warn if restrictive
$executionPolicy = Get-ExecutionPolicy
if ($executionPolicy -eq "Restricted" -or $executionPolicy -eq "AllSigned") {
    Write-Warning "PowerShell execution policy is restrictive ($executionPolicy)."
    Write-Info "You may need to run: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser"
    Write-Info "Or run this script with: powershell -ExecutionPolicy Bypass -File setup-bootstrap.ps1"
}

# Colors for output
$Colors = @{
    Info = "Cyan"
    Success = "Green"
    Warning = "Yellow"
    Error = "Red"
}

# Function to print colored output
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor $Colors.Info
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor $Colors.Success
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor $Colors.Warning
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor $Colors.Error
}

# Function to check if command exists
function Test-Command {
    param([string]$Command)
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

# Function to check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to install winget if not available
function Install-Winget {
    if (Test-Command "winget") {
        Write-Info "winget already installed"
        return
    }
    
    Write-Info "Installing winget (App Installer)..."
    try {
        # Try to install from Microsoft Store
        $progressPreference = 'silentlyContinue'
        Invoke-WebRequest -Uri "https://aka.ms/getwinget" -OutFile "$env:TEMP\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
        Add-AppxPackage -Path "$env:TEMP\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
        Remove-Item "$env:TEMP\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -Force
        Write-Success "winget installed successfully"
    }
    catch {
        Write-Error "Failed to install winget: $_"
        Write-Info "Please install winget manually from the Microsoft Store or GitHub"
        exit 1
    }
}

# Function to install GitHub CLI
function Install-GitHubCLI {
    if (Test-Command "gh") {
        Write-Info "GitHub CLI already installed"
        return
    }
    
    Write-Info "Installing GitHub CLI..."
    try {
        winget install --id GitHub.cli --scope machine --accept-source-agreements --accept-package-agreements --silent
        
        # Refresh environment variables
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
        
        if (Test-Command "gh") {
            Write-Success "GitHub CLI installed successfully"
        } else {
            Write-Warning "GitHub CLI installed but not in PATH. You may need to restart your terminal."
        }
    }
    catch {
        Write-Error "Failed to install GitHub CLI: $_"
        Write-Info "Please install manually with: winget install GitHub.cli"
        exit 1
    }
}

# Function to install Git
function Install-Git {
    if (Test-Command "git") {
        Write-Info "Git already installed"
        return
    }
    
    Write-Info "Installing Git..."
    try {
        winget install --id Git.Git --scope machine --accept-source-agreements --accept-package-agreements --silent
        
        # Refresh environment variables
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
        
        if (Test-Command "git") {
            Write-Success "Git installed successfully"
        } else {
            Write-Warning "Git installed but not in PATH. You may need to restart your terminal."
        }
    }
    catch {
        Write-Error "Failed to install Git: $_"
        Write-Info "Please install manually with: winget install Git.Git"
        exit 1
    }
}

# Function to install yadm
function Install-Yadm {
    if (Test-Command "yadm") {
        Write-Info "yadm already installed"
        return
    }
    
    Write-Info "Installing yadm..."
    try {
        # Create local bin directory
        $localBin = "$env:USERPROFILE\.local\bin"
        if (!(Test-Path $localBin)) {
            New-Item -ItemType Directory -Path $localBin -Force | Out-Null
        }
        
        # Download yadm
        $yadmPath = "$localBin\yadm"
        $progressPreference = 'silentlyContinue'
        Invoke-WebRequest -Uri "https://github.com/yadm-dev/yadm/raw/master/yadm" -OutFile $yadmPath
        
        # Add to PATH if not already there
        $userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
        if ($userPath -notlike "*$localBin*") {
            [System.Environment]::SetEnvironmentVariable("PATH", "$userPath;$localBin", "User")
            $env:PATH += ";$localBin"
        }
        
        Write-Success "yadm installed successfully"
    }
    catch {
        Write-Error "Failed to install yadm: $_"
        exit 1
    }
}

# Function to authenticate with GitHub
function Invoke-GitHubAuth {
    if ($SkipAuth) {
        Write-Info "Skipping GitHub authentication"
        return
    }
    
    Write-Info "Checking GitHub authentication..."
    
    try {
        # Check if already authenticated
        $authStatus = gh auth status 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Info "Already authenticated with GitHub"
            return
        }
    }
    catch {
        # Continue with authentication
    }
    
    Write-Info "Starting GitHub authentication..."
    Write-Info "Please follow the prompts to authenticate with GitHub"
    
    try {
        gh auth login
        Write-Success "GitHub authentication completed"
    }
    catch {
        Write-Error "GitHub authentication failed: $_"
        exit 1
    }
}

# Function to setup yadm repository
function Set-YadmRepository {
    Write-Info "Setting up yadm repository..."
    
    $repoUrl = "https://github.com/chbota/setup-internal.git"
    
    try {
        # Check if yadm repo is already cloned
        $yadmStatus = yadm status 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Warning "yadm repository already exists. Pulling latest changes..."
            yadm pull
        } else {
            Write-Info "Cloning yadm repository..."
            yadm clone $repoUrl
        }
        
        Write-Success "yadm repository setup completed"
    }
    catch {
        Write-Error "Failed to setup yadm repository: $_"
        exit 1
    }
}

# Function to run bootstrap scripts
function Invoke-Bootstrap {
    Write-Info "Running platform-specific bootstrap scripts..."
    
    try {
        yadm bootstrap
    }
    catch {
        Write-Error "Bootstrap script failed: $_"
        Write-Warning "You may need to run the bootstrap script manually"
    }
}

# Main execution
function Main {
    Write-Info "Starting Windows bootstrap setup..."
    
    # Check if running on Windows
    if ($PSVersionTable.Platform -and $PSVersionTable.Platform -ne "Win32NT") {
        Write-Error "This script is designed for Windows. Use the bash version for Linux/macOS."
        exit 1
    }
    
    # Check for administrator privileges for some operations
    if (!(Test-Administrator)) {
        Write-Warning "Not running as administrator. Some features may not work properly."
        Write-Info "Consider running as administrator for best results."
    }
    
    # Install winget if needed
    Install-Winget
    
    # Install Git
    Install-Git
    
    # Install GitHub CLI
    Install-GitHubCLI
    
    # Install yadm
    Install-Yadm
    
    # Authenticate with GitHub
    Invoke-GitHubAuth
    
    # Setup yadm repository
    Set-YadmRepository
    
    # Run bootstrap scripts
    Invoke-Bootstrap
    
    Write-Success "Bootstrap setup completed successfully!"
    Write-Info "Your development environment is now ready."
    Write-Info "You may need to restart your terminal to reload environment variables."
    
    # Offer to restart terminal
    $restart = Read-Host "Would you like to restart your terminal now? (y/N)"
    if ($restart -eq 'y' -or $restart -eq 'Y') {
        Write-Info "Restarting terminal..."
        Start-Process -FilePath "powershell" -ArgumentList "-NoExit", "-Command", "cd '$PWD'"
        exit 0
    }
}

# Run main function only if script is executed directly (not dot-sourced)
if ($MyInvocation.InvocationName -ne '.') {
    try {
        Main
    }
    catch {
        Write-Error "Script failed: $_"
        exit 1
    }
} 
