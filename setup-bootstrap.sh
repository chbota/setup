#!/bin/bash

# Cross-platform bootstrap script for setting up development environment
# Works on Linux, macOS, and Windows (via Git Bash/WSL)

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to detect operating system
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install GitHub CLI on Linux/macOS
install_gh_unix() {
    print_info "Installing GitHub CLI via webi.sh..."
    if command_exists curl; then
        curl -sS https://webi.sh/gh | sh
        # Add to PATH for current session
        export PATH="$HOME/.local/bin:$PATH"
    else
        print_error "curl is not installed. Please install curl first."
        exit 1
    fi
}

# Function to install GitHub CLI on Windows
install_gh_windows() {
    print_info "Installing GitHub CLI on Windows..."
    print_warning "This script assumes you're running in Git Bash or WSL."
    print_warning "If you're in Command Prompt or PowerShell, please run these commands manually:"
    print_warning "  winget install --id Git.Git --scope machine"
    print_warning "  winget install --id GitHub.cli --scope machine --interactive -e"
    
    # Check if we're in a Windows environment that supports winget
    if command_exists winget.exe; then
        print_info "Found winget, attempting to install..."
        winget.exe install --id Git.Git --scope machine --accept-source-agreements --accept-package-agreements
        winget.exe install --id GitHub.cli --scope machine --accept-source-agreements --accept-package-agreements
    elif command_exists gh; then
        print_info "GitHub CLI already installed"
    else
        print_error "Cannot install GitHub CLI automatically on this Windows environment."
        print_error "Please install manually using winget or download from https://cli.github.com/"
        exit 1
    fi
}

# Function to install yadm
install_yadm() {
    print_info "Installing yadm..."
    
    local os=$(detect_os)
    
    if command_exists yadm; then
        print_info "yadm already installed"
        return 0
    fi
    
    case $os in
        "linux")
            if command_exists apt-get; then
                sudo apt-get update && sudo apt-get install -y yadm
            elif command_exists yum; then
                sudo yum install -y yadm
            elif command_exists dnf; then
                sudo dnf install -y yadm
            elif command_exists pacman; then
                sudo pacman -S --noconfirm yadm
            else
                # Fallback to curl install
                print_info "Installing yadm via curl..."
                curl -fLo ~/.local/bin/yadm https://github.com/yadm-dev/yadm/raw/master/yadm
                chmod +x ~/.local/bin/yadm
            fi
            ;;
        "macos")
            if command_exists brew; then
                brew install yadm
            else
                print_info "Installing yadm via curl..."
                mkdir -p ~/.local/bin
                curl -fLo ~/.local/bin/yadm https://github.com/yadm-dev/yadm/raw/master/yadm
                chmod +x ~/.local/bin/yadm
                export PATH="$HOME/.local/bin:$PATH"
            fi
            ;;
        "windows")
            print_info "Installing yadm via curl..."
            mkdir -p ~/.local/bin
            curl -fLo ~/.local/bin/yadm https://github.com/yadm-dev/yadm/raw/master/yadm
            chmod +x ~/.local/bin/yadm
            export PATH="$HOME/.local/bin:$PATH"
            ;;
        *)
            print_error "Unsupported operating system for yadm installation"
            exit 1
            ;;
    esac
    
    if command_exists yadm; then
        print_success "yadm installed successfully"
    else
        print_error "Failed to install yadm"
        exit 1
    fi
}

# Function to authenticate with GitHub
authenticate_github() {
    print_info "Authenticating with GitHub..."
    
    if ! command_exists gh; then
        print_error "GitHub CLI (gh) is not installed or not in PATH"
        exit 1
    fi
    
    # Check if already authenticated
    if gh auth status >/dev/null 2>&1; then
        print_info "Already authenticated with GitHub"
    else
        print_info "Starting GitHub authentication..."
        gh auth login
    fi

    print_info "Configuring git to use GH auth helper"
    gh auth setup-git
    
    print_success "GitHub authentication completed"
}

# Function to clone and setup yadm repository
setup_yadm_repo() {
    print_info "Setting up yadm repository..."
    
    local repo_url="https://github.com/chbota/setup-internal.git"
    
    # Check if yadm repo is already cloned
    if yadm status >/dev/null 2>&1; then
        print_warning "yadm repository already exists. Pulling latest changes..."
        yadm pull
        yadm bootstrap
    else
        print_info "Cloning yadm repository..."
        yadm clone "$repo_url"
    fi    

    yadm gitconfig alias.restoreSettings '!git diff --stat @~1'
    yadm gitconfig alias.backupSettings '!git diff --stat @~1'
    yadm checkout .gitconfig
    
    print_success "yadm repository setup completed"
}

# Main execution
main() {
    print_info "Starting cross-platform bootstrap setup..."
    
    local os=$(detect_os)
    print_info "Detected operating system: $os"
    
    # Install GitHub CLI based on OS
    if command_exists gh; then
        print_info "GitHub CLI already installed"
    else
        case $os in
            "linux"|"macos")
                install_gh_unix
                ;;
            "windows")
                install_gh_windows
                ;;
            *)
                print_error "Unsupported operating system: $os"
                exit 1
                ;;
        esac
    fi
    
    # Verify gh is available
    if command_exists gh; then
        print_success "GitHub CLI is available"
    else
        print_error "GitHub CLI installation failed or not in PATH"
        exit 1
    fi
    
    # Install yadm
    install_yadm
    
    # Authenticate with GitHub
    authenticate_github
    
    # Setup yadm repository
    setup_yadm_repo
    
    print_success "Bootstrap setup completed successfully!"
    print_info "Your development environment is now ready."
    print_info "You may need to restart your shell or run 'source ~/.bashrc' (or equivalent) to reload environment variables."
}

# Run main function
main "$@"
