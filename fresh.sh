#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# FRESH - Linux System Setup Tool
# ==============================================================================
# Interactive installation script for new Linux systems and VPS instances
# Supports multiple tiers: Minimal, Standard, Developer, Full
# ==============================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOGFILE="$HOME/fresh-install.log"
readonly VERSION="2.0.0"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# ==============================================================================
# Logging Functions
# ==============================================================================

log() {
    echo -e "${GREEN}[INFO]${NC}  $(date '+%F %T') $*" | tee -a "$LOGFILE"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC}  $(date '+%F %T') $*" | tee -a "$LOGFILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%F %T') $*" | tee -a "$LOGFILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*" | tee -a "$LOGFILE"
}

# ==============================================================================
# Tool Categories
# ==============================================================================

# Minimal - Essential tools for any Linux system
declare -A MINIMAL_TOOLS=(
    [curl]="curl"
    [wget]="wget"
    [git]="git"
    [unzip]="unzip"
    [tree]="tree"
    [tmux]="tmux"
    [htop]="htop"
    [nano]="nano"
    [less]="less"
    [grep]="grep"
    [sed]="sed"
    [jq]="jq"
)

# Standard - Common CLI tools for productivity
declare -A STANDARD_TOOLS=(
    [fzf]="fzf"
    [ripgrep]="ripgrep"
    [fd-find]="fd-find"
    [bat]="bat"
    [eza]="eza"
    [ncdu]="ncdu"
    [gdu]="gdu"
    [btop]="btop"
    [zoxide]="zoxide"
    [most]="most"
    [silversearcher-ag]="silversearcher-ag"
    [gawk]="gawk"
    [fastfetch]="fastfetch"
    [stow]="stow"
    [tealdeer]="tealdeer"
    [rsync]="rsync"
    [zsh]="zsh"
)

# Developer - Development tools and languages
declare -A DEVELOPER_TOOLS=(
    [build-essential]="build-essential"
    [cmake]="cmake"
    [python3-pip]="python3-pip"
    [nodejs]="nodejs"
    [npm]="npm"
    [docker.io]="docker.io"
    [docker-compose]="docker-compose"
    [tig]="tig"
    [micro]="micro"
    [entr]="entr"
    [libssl-dev]="libssl-dev"
    [pkg-config]="pkg-config"
    [gh]="gh"
    [lazygit]="lazygit"
    [git-delta]="git-delta"
)

# Full - Advanced tools, security, multimedia
declare -A FULL_TOOLS=(
    [keepassxc]="keepassxc"
    [lynis]="lynis"
    [aide]="aide"
    [cmatrix]="cmatrix"
    [ffmpeg]="ffmpeg"
    [yt-dlp]="yt-dlp"
    [bleachbit]="bleachbit"
    [nnn]="nnn"
    [taskwarrior]="taskwarrior"
    [neovim]="neovim"
    [mosh]="mosh"
    [fail2ban]="fail2ban"
    [ufw]="ufw"
    [flameshot]="flameshot"
    [bandwhich]="bandwhich"
)

# ==============================================================================
# System Detection
# ==============================================================================

detect_system() {
    log "Detecting system information..."

    if [[ -f /etc/os-release ]]; then
        # Read OS info safely without sourcing to avoid readonly variable conflicts
        local os_name=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d'"' -f2)
        local os_version=$(grep '^VERSION_ID=' /etc/os-release | cut -d'"' -f2)
        echo "OS: ${os_name:-Unknown}"
        echo "Version: ${os_version:-Unknown}"
    fi

    echo "Architecture: $(uname -m)"
    echo "Kernel: $(uname -r)"

    # Check if we have sudo
    if ! command -v sudo &>/dev/null; then
        log_error "sudo is required but not installed"
        exit 1
    fi

    # Check package manager
    if ! command -v apt &>/dev/null; then
        log_error "This script currently only supports apt-based systems"
        exit 1
    fi
}

# ==============================================================================
# Tool Installation Functions
# ==============================================================================

is_tool_installed() {
    local tool="$1"
    command -v "$tool" &>/dev/null
}

install_tools() {
    local -n tools_ref=$1
    local category_name="$2"
    local tools_to_install=()

    log "Checking $category_name tools..."

    # Check which tools need installation
    for tool in "${!tools_ref[@]}"; do
        local package="${tools_ref[$tool]}"
        if ! is_tool_installed "$tool"; then
            tools_to_install+=("$package")
        else
            echo "  ✓ $tool already installed"
        fi
    done

    if [[ ${#tools_to_install[@]} -eq 0 ]]; then
        log_success "All $category_name tools already installed"
        return 0
    fi

    echo
    echo -e "${PURPLE}$category_name Tools to Install:${NC}"
    printf '  %s\n' "${tools_to_install[@]}"
    echo

    read -p "Install these tools? [Y/n] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ -n $REPLY ]]; then
        log_warn "Skipping $category_name tools installation"
        return 0
    fi

    log "Installing $category_name tools..."
    sudo apt update

    # Install packages individually to handle failures gracefully
    local failed_packages=()
    for package in "${tools_to_install[@]}"; do
        if sudo apt install -y "$package" 2>&1 | grep -q "Unable to locate package"; then
            log_warn "Package '$package' not available in repositories - skipping"
            failed_packages+=("$package")
        elif ! sudo apt install -y "$package"; then
            log_warn "Failed to install '$package' - skipping"
            failed_packages+=("$package")
        else
            echo "  ✓ $package installed successfully"
        fi
    done

    if [[ ${#failed_packages[@]} -gt 0 ]]; then
        log_warn "Some packages were skipped: ${failed_packages[*]}"
    fi

    log_success "$category_name tools installation completed (with ${#failed_packages[@]} skipped)"
}

# ==============================================================================
# Installation Tiers
# ==============================================================================

install_minimal() {
    echo -e "${CYAN}=== MINIMAL INSTALLATION ===${NC}"
    echo "Essential tools for any Linux system"
    echo
    install_tools MINIMAL_TOOLS "Minimal"
}

install_standard() {
    install_minimal
    echo
    echo -e "${CYAN}=== STANDARD INSTALLATION ===${NC}"
    echo "Minimal + productivity CLI tools"
    echo
    install_tools STANDARD_TOOLS "Standard"
}

install_developer() {
    install_standard
    echo
    echo -e "${CYAN}=== DEVELOPER INSTALLATION ===${NC}"
    echo "Standard + development tools and languages"
    echo
    install_tools DEVELOPER_TOOLS "Developer"
}

install_full() {
    install_developer
    echo
    echo -e "${CYAN}=== FULL INSTALLATION ===${NC}"
    echo "Everything + security tools, multimedia, advanced utilities"
    echo
    install_tools FULL_TOOLS "Full"
}

# ==============================================================================
# Interactive Menu
# ==============================================================================

show_menu() {
    clear
    echo -e "${WHITE}"
    echo "┌─────────────────────────────────────────────────────────┐"
    echo "│                    🚀 FRESH v$VERSION                    │"
    echo "│              Linux System Setup Tool                   │"
    echo "└─────────────────────────────────────────────────────────┘"
    echo -e "${NC}"
    echo
    echo -e "${BLUE}Choose your installation tier:${NC}"
    echo
    echo -e "${GREEN}1)${NC} ${WHITE}Minimal${NC}    - Essential tools only (curl, git, tmux, etc.)"
    echo -e "${GREEN}2)${NC} ${WHITE}Standard${NC}   - Minimal + productivity CLI tools (fzf, ripgrep, bat, etc.)"
    echo -e "${GREEN}3)${NC} ${WHITE}Developer${NC}  - Standard + development tools (docker, nodejs, python, etc.)"
    echo -e "${GREEN}4)${NC} ${WHITE}Full${NC}       - Everything + security tools, multimedia, advanced utils"
    echo
    echo -e "${GREEN}5)${NC} ${WHITE}Custom${NC}     - Select individual categories"
    echo -e "${GREEN}6)${NC} ${WHITE}Show Tools${NC} - Preview what each tier installs"
    echo -e "${GREEN}7)${NC} ${WHITE}Manual Tools${NC} - Install helix, yazi, glow, lazydocker, nerd-fonts, gitleaks, atuin (from GitHub)"
    echo -e "${GREEN}8)${NC} ${WHITE}PAI Setup${NC} - Install Personal AI Infrastructure v3"
    echo -e "${GREEN}9)${NC} ${WHITE}Enhanced Shell${NC} - Install enhanced shell commands only"
    echo
    echo -e "${YELLOW}i)${NC} Security Research Info"
    echo -e "${RED}0)${NC} Exit"
    echo
}

show_tools() {
    clear
    echo -e "${WHITE}=== TOOL PREVIEW ===${NC}"
    echo

    echo -e "${CYAN}MINIMAL TOOLS:${NC}"
    printf '  %s\n' "${!MINIMAL_TOOLS[@]}" | sort
    echo

    echo -e "${CYAN}STANDARD TOOLS (additional):${NC}"
    printf '  %s\n' "${!STANDARD_TOOLS[@]}" | sort
    echo

    echo -e "${CYAN}DEVELOPER TOOLS (additional):${NC}"
    printf '  %s\n' "${!DEVELOPER_TOOLS[@]}" | sort
    echo

    echo -e "${CYAN}FULL TOOLS (additional):${NC}"
    printf '  %s\n' "${!FULL_TOOLS[@]}" | sort
    echo

    read -p "Press Enter to continue..." -r
}

custom_install() {
    echo -e "${CYAN}=== CUSTOM INSTALLATION ===${NC}"
    echo "Select which categories to install:"
    echo

    local install_minimal install_standard install_developer install_full

    read -p "Install Minimal tools? [Y/n] " -n 1 -r install_minimal
    echo
    [[ $install_minimal =~ ^[Yy]$ ]] || [[ -z $install_minimal ]] && install_tools MINIMAL_TOOLS "Minimal"

    read -p "Install Standard tools? [Y/n] " -n 1 -r install_standard
    echo
    [[ $install_standard =~ ^[Yy]$ ]] || [[ -z $install_standard ]] && install_tools STANDARD_TOOLS "Standard"

    read -p "Install Developer tools? [Y/n] " -n 1 -r install_developer
    echo
    [[ $install_developer =~ ^[Yy]$ ]] || [[ -z $install_developer ]] && install_tools DEVELOPER_TOOLS "Developer"

    read -p "Install Full tools? [Y/n] " -n 1 -r install_full
    echo
    [[ $install_full =~ ^[Yy]$ ]] || [[ -z $install_full ]] && install_tools FULL_TOOLS "Full"
}

install_enhanced_shell() {
    echo -e "${CYAN}=== ENHANCED SHELL CONFIGURATION ===${NC}"
    echo "Setting up enhanced shell commands and aliases"
    echo "This includes context manager, improved fzf integration, and modern CLI tools"
    echo

    # Ensure enhanced aliases are available
    if [[ -f "$HOME/.aliases" ]]; then
        echo -e "${YELLOW}Updating enhanced shell aliases...${NC}"

        # Add PAI Context Manager aliases if not present
        if ! grep -q "PAI Context Manager" "$HOME/.aliases" 2>/dev/null; then
            cat >> "$HOME/.aliases" << 'EOF'

# PAI Context Manager
alias cm="~/.claude/commands/context-manager.sh"
alias cms="~/.claude/commands/context-manager.sh search"
alias cmr="~/.claude/commands/context-manager.sh recent"
alias cmn="~/.claude/commands/context-manager.sh new"
alias cmt="~/.claude/commands/context-manager.sh tree"

# Enhanced fzf file operations with better previews
alias fzfg='rg --line-number --color=always . | fzf --ansi --delimiter ":" --preview "bat --color=always --highlight-line {2} {1}" --bind "enter:execute(hx +{2} {1})"'
alias fzfd='fd --type d | fzf --preview "eza --tree --level=2 --color=always {} 2>/dev/null || tree -L 2 -C {}"'

# Better process management
alias psg='ps aux | fzf --header-lines=1 --preview "echo {}" --preview-window=up:1'

# Enhanced git fzf integration
alias gfzf='git log --oneline --color=always | fzf --ansi --preview "git show --color=always {1}" --bind "enter:execute(git show {1} | less -R)"'
EOF
        fi

        echo -e "${GREEN}✓ Enhanced shell aliases configured${NC}"
    else
        echo -e "${YELLOW}Creating ~/.aliases file with enhanced commands...${NC}"
        cat > "$HOME/.aliases" << 'EOF'
# Enhanced Shell Configuration - Generated by Fresh

# PAI Context Manager
alias cm="~/.claude/commands/context-manager.sh"
alias cms="~/.claude/commands/context-manager.sh search"
alias cmr="~/.claude/commands/context-manager.sh recent"
alias cmn="~/.claude/commands/context-manager.sh new"
alias cmt="~/.claude/commands/context-manager.sh tree"

# Enhanced fzf file operations with better previews
alias fzfg='rg --line-number --color=always . | fzf --ansi --delimiter ":" --preview "bat --color=always --highlight-line {2} {1}" --bind "enter:execute(hx +{2} {1})"'
alias fzfd='fd --type d | fzf --preview "eza --tree --level=2 --color=always {} 2>/dev/null || tree -L 2 -C {}"'

# Better process management
alias psg='ps aux | fzf --header-lines=1 --preview "echo {}" --preview-window=up:1'

# Enhanced git fzf integration
alias gfzf='git log --oneline --color=always | fzf --ansi --preview "git show --color=always {1}" --bind "enter:execute(git show {1} | less -R)"'

# Enhanced file operations with previews
alias vp='fd --type f --hidden --exclude .git | fzf --preview "bat {} --color=always --style=numbers" | xargs hx'
alias ff='find * -type f | fzf --preview "bat --color=always {}"'
alias rgl='rg --files | fzf --preview "bat --color=always {}"'

# Smart history with atuin (fallback to fzf if not available)
if command -v atuin &> /dev/null; then
    alias h='atuin search --interactive'
else
    alias h='history | fzf --preview "echo {}" --preview-window="up:3:wrap"'
fi

# Smart command search (zsh compatible)
if [[ -n "$ZSH_VERSION" ]]; then
    alias findcmd='print -l ${(k)commands} | fzf --prompt="Search command: "'
elif [[ -n "$BASH_VERSION" ]]; then
    alias findcmd='compgen -c | sort -u | fzf --prompt="Search command: "'
fi
EOF
        echo -e "${GREEN}✓ ~/.aliases file created with enhanced commands${NC}"
    fi

    # Setup atuin if available
    if command -v atuin &>/dev/null; then
        echo -e "${YELLOW}Configuring atuin smart history...${NC}"
        if [[ ! -f "$HOME/.config/atuin/config.toml" ]]; then
            mkdir -p "$HOME/.config/atuin"
            atuin init zsh --disable-up-arrow &>/dev/null || true
            atuin import auto &>/dev/null || true
        fi
        echo -e "${GREEN}✓ Atuin smart history configured${NC}"
    fi

    # Enhanced exports for fzf
    if [[ -f "$HOME/.exports" ]]; then
        if ! grep -q "FZF_DEFAULT_COMMAND" "$HOME/.exports" 2>/dev/null; then
            cat >> "$HOME/.exports" << 'EOF'

# Enhanced fzf configuration
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='--height 60% --layout=reverse --border --inline-info --preview-window=right:60%'
EOF
            echo -e "${GREEN}✓ Enhanced fzf exports configured${NC}"
        fi
    fi

    echo -e "${GREEN}✓ Enhanced shell configuration complete${NC}"
    echo -e "${CYAN}Available commands:${NC}"
    echo "  cm     - Context manager"
    echo "  fzfg   - Grep with jump-to-line"
    echo "  fzfd   - Directory browser"
    echo "  gfzf   - Git log browser"
    echo "  h      - Smart history (atuin)"
}

install_pai3() {
    echo -e "${CYAN}=== PAI PERSONAL AI INFRASTRUCTURE ===${NC}"
    echo "Setting up Daniel Miessler's PAI system"
    echo "This includes voice server, enhanced Claude integration, and AI workflow tools"
    echo

    # Install prerequisites
    if ! command -v bun &>/dev/null; then
        echo -e "${YELLOW}Installing Bun (JavaScript runtime)...${NC}"
        curl -fsSL https://bun.sh/install | bash
        export PATH="$HOME/.bun/bin:$PATH"
    fi

    # Clone PAI if not exists
    if [[ ! -d "$HOME/PAI" ]]; then
        echo -e "${YELLOW}Cloning PAI repository...${NC}"
        git clone https://github.com/danielmiessler/PAI.git "$HOME/PAI"
    fi

    # Copy PAI components to Claude directory
    echo -e "${YELLOW}Setting up PAI components...${NC}"

    # Backup existing Claude config
    if [[ -d "$HOME/.claude" ]]; then
        echo -e "${YELLOW}Backing up existing Claude configuration...${NC}"
        cp -r "$HOME/.claude" "$HOME/.claude-backup-$(date +%Y%m%d-%H%M%S)"
    fi

    # Create Claude directory structure
    mkdir -p "$HOME/.claude"

    # Copy PAI components
    cp -r "$HOME/PAI/.claude/"* "$HOME/.claude/" 2>/dev/null || true

    # Fix paths in voice server
    sed -i 's|/Users/daniel/|~/.claude/|g' "$HOME/.claude/voice-server/start.sh" 2>/dev/null || true

    # Install enhanced shell configuration
    install_enhanced_shell

    echo -e "${GREEN}✓ PAI infrastructure installed${NC}"
    echo -e "${CYAN}Next steps:${NC}"
    echo "  1. Configure API keys in ~/.claude/.env"
    echo "  2. Start voice server: ~/.claude/voice-server/start.sh"
    echo "  3. Source your shell config: source ~/.zshrc && source ~/.aliases"
    echo "  4. Open Claude Code and enjoy your AI infrastructure!"
    echo
    echo -e "${PURPLE}📖 Learn more: https://github.com/danielmiessler/PAI${NC}"
}

show_security_info() {
    clear
    echo -e "${WHITE}"
    echo "┌─────────────────────────────────────────────────────────┐"
    echo "│            🔒 SECURITY RESEARCH TOOLS 🔒                │"
    echo "└─────────────────────────────────────────────────────────┘"
    echo -e "${NC}"
    echo
    echo -e "${CYAN}Fresh provides a foundation for security research environments.${NC}"
    echo -e "${CYAN}For advanced security tools, check out these complementary projects:${NC}"
    echo
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    echo -e "${GREEN}🛠️  toolbelt${NC} - Comprehensive Security Tool Installer"
    echo -e "   ${WHITE}https://github.com/rpriven/toolbelt${NC}"
    echo
    echo -e "   ${CYAN}What it provides:${NC}"
    echo "   • Full pentesting arsenal for Kali Linux"
    echo "   • Security tools for Debian/Ubuntu"
    echo "   • Interactive menu with pre-built profiles"
    echo "   • APT, Go, Python, Docker tools"
    echo "   • Scripts collection (linpeas, winpeas, etc.)"
    echo
    echo -e "   ${CYAN}Best for:${NC}"
    echo "   • Bug bounty hunting"
    echo "   • CTF competitions"
    echo "   • Penetration testing"
    echo "   • Security research & learning"
    echo
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    echo -e "${GREEN}🚀 tmux-recon${NC} - Pentesting Automation & Environment"
    echo -e "   ${WHITE}https://github.com/rpriven/tmux-recon${NC}"
    echo
    echo -e "   ${CYAN}What it provides:${NC}"
    echo "   • Advanced tmux configuration for pentesting workflows"
    echo "   • Zsh setup with security-focused plugins"
    echo "   • Automated reconnaissance scripts"
    echo "   • ProjectDiscovery tool integration"
    echo "   • Oh-my-tmux pentesting environment"
    echo
    echo -e "   ${CYAN}Best for:${NC}"
    echo "   • Setting up pentesting shell environment"
    echo "   • Automated recon workflows"
    echo "   • Security research productivity"
    echo
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    echo -e "${YELLOW}💡 Recommended Installation Flow:${NC}"
    echo
    echo -e "   ${WHITE}1.${NC} Install fresh (you're here!) - Modern CLI foundation"
    echo -e "   ${WHITE}2.${NC} Install toolbelt - Comprehensive security tools"
    echo -e "   ${WHITE}3.${NC} Install tmux-recon - Pentesting automation & environment"
    echo
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    echo -e "${CYAN}Quick Start:${NC}"
    echo
    echo -e "${WHITE}# Install toolbelt${NC}"
    echo "git clone https://github.com/rpriven/toolbelt.git && cd toolbelt"
    echo "python3 toolbelt.py"
    echo
    echo -e "${WHITE}# Install tmux-recon${NC}"
    echo "git clone https://github.com/rpriven/tmux-recon.git && cd tmux-recon"
    echo "python3 tmux-recon.py --all"
    echo
    read -p "Press Enter to continue..." -r
}

# ==============================================================================
# Post-Install Setup
# ==============================================================================

post_install_setup() {
    log "Running post-installation setup..."

    # Add user to docker group if docker was installed
    if command -v docker &>/dev/null; then
        if ! groups "$USER" | grep -q docker; then
            log "Adding $USER to docker group..."
            sudo usermod -aG docker "$USER"
            log_warn "You'll need to log out and back in for docker group changes to take effect"
        fi
    fi

    # Install eza if exa was installed but eza is available
    if command -v exa &>/dev/null && ! command -v eza &>/dev/null; then
        log "Installing eza (modern replacement for exa)..."
        if command -v cargo &>/dev/null; then
            cargo install eza
        fi
    fi

    # Create bat symlink if batcat exists but bat doesn't
    if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
        log "Creating bat symlink for batcat..."
        mkdir -p ~/.local/bin
        ln -sf /usr/bin/batcat ~/.local/bin/bat
        log_success "bat symlink created (~/.local/bin/bat -> /usr/bin/batcat)"
    fi

    # Create fd symlink if fdfind exists but fd doesn't (Debian naming issue)
    if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
        log "Creating fd symlink for fdfind (Debian naming fix)..."
        mkdir -p ~/.local/bin
        ln -sf /usr/bin/fdfind ~/.local/bin/fd
        log_success "fd symlink created (~/.local/bin/fd -> /usr/bin/fdfind)"
        log_warn "This fixes fzf integration issues on Debian"
    fi

    # Install tealdeer cache if available
    if command -v tldr &>/dev/null; then
        log "Updating tealdeer (tldr) cache..."
        tldr --update || log_warn "Failed to update tldr cache - run 'tldr --update' manually"
    fi

    log_success "Post-installation setup completed"
}

# ==============================================================================
# Manual Install Functions (tools not in apt)
# ==============================================================================

install_manual_tools() {
    echo -e "${CYAN}=== MANUAL TOOLS INSTALLATION ===${NC}"
    echo "Installing tools not available via apt"
    echo

    read -p "Install Helix editor? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        install_helix
    fi

    read -p "Install yazi (terminal file manager)? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        install_yazi
    fi

    read -p "Install glow (markdown viewer)? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        install_glow
    fi

    read -p "Install lazydocker? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        install_lazydocker
    fi

    read -p "Install Nerd Fonts (for terminal icons)? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        install_nerd_fonts
    fi

    read -p "Install gitleaks (secret scanner for git)? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        install_gitleaks
    fi

    read -p "Install atuin (smart shell history)? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        install_atuin
    fi
}

install_helix() {
    log "Installing Helix editor (AppImage)..."

    # Known working version (update periodically)
    local HELIX_VERSION="25.07.1"
    local HELIX_URL="https://github.com/helix-editor/helix/releases/download/${HELIX_VERSION}/helix-${HELIX_VERSION}-x86_64.AppImage"

    # Try to get latest from API first (may fail due to rate limits)
    local latest_url=$(curl -sf https://api.github.com/repos/helix-editor/helix/releases/latest 2>/dev/null | grep "browser_download_url.*x86_64.*\.AppImage\"" | grep -v zsync | cut -d '"' -f 4 | head -1)

    # Use API result if available, otherwise fall back to known version
    if [[ -n "$latest_url" ]]; then
        log "Found latest release via API"
        HELIX_URL="$latest_url"
    else
        log_warn "GitHub API unavailable, using known version ${HELIX_VERSION}"
    fi

    mkdir -p ~/.local/bin

    log "Downloading Helix AppImage from: $HELIX_URL"
    if ! curl -fL "$HELIX_URL" -o ~/.local/bin/helix.appimage; then
        log_error "Failed to download Helix AppImage"
        return 1
    fi

    log "Making executable..."
    chmod +x ~/.local/bin/helix.appimage

    log "Creating user symlink..."
    ln -sf ~/.local/bin/helix.appimage ~/.local/bin/hx

    # Offer to create system-wide symlink for sudo access
    echo
    read -p "Create system-wide symlink for sudo access? (requires sudo) [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        if sudo ln -sf "$HOME/.local/bin/hx" /usr/local/bin/hx 2>/dev/null; then
            log_success "System symlink created: /usr/local/bin/hx"
        else
            log_warn "Could not create system symlink. Run manually:"
            echo "  sudo ln -s ~/.local/bin/hx /usr/local/bin/hx"
        fi
    fi

    log_success "Helix AppImage installed successfully! Run 'hx' to start."
    log_warn "Make sure ~/.local/bin is in your PATH"
}

install_helix_tarball() {
    # Fallback to tarball if AppImage not available
    log "Installing Helix from tarball..."

    local latest_url=$(curl -s https://api.github.com/repos/helix-editor/helix/releases/latest | grep "browser_download_url.*x86_64.*linux.*tar" | cut -d '"' -f 4)

    if [[ -z "$latest_url" ]]; then
        log_error "Failed to find Helix release"
        return 1
    fi

    local temp_dir=$(mktemp -d)
    cd "$temp_dir"

    log "Downloading Helix tarball..."
    curl -L "$latest_url" -o helix.tar.gz

    log "Extracting..."
    tar xzf helix.tar.gz

    local helix_dir=$(find . -maxdepth 1 -type d -name "helix-*" | head -n1)

    log "Installing to ~/.local/bin..."
    mkdir -p ~/.local/bin
    cp "$helix_dir/hx" ~/.local/bin/
    chmod +x ~/.local/bin/hx

    log "Installing runtime files..."
    mkdir -p ~/.config/helix
    cp -r "$helix_dir/runtime" ~/.config/helix/

    cd - > /dev/null
    rm -rf "$temp_dir"

    log_success "Helix installed successfully!"
}

install_yazi() {
    log "Installing yazi (terminal file manager)..."

    mkdir -p ~/.local/bin
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"

    log "Downloading yazi v25.5.31..."
    wget -q https://github.com/sxyazi/yazi/releases/download/v25.5.31/yazi-x86_64-unknown-linux-gnu.zip -O yazi.zip

    log "Extracting..."
    unzip -q yazi.zip

    log "Installing to ~/.local/bin..."
    mv yazi-x86_64-unknown-linux-gnu/yazi ~/.local/bin/
    chmod +x ~/.local/bin/yazi

    cd - > /dev/null
    rm -rf "$temp_dir"

    log_success "yazi installed successfully! (~/.local/bin/yazi)"
    log_warn "Make sure ~/.local/bin is in your PATH"
}

install_glow() {
    log "Installing glow (markdown viewer)..."

    mkdir -p ~/.local/bin
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"

    log "Downloading glow v2.1.1..."
    wget -q https://github.com/charmbracelet/glow/releases/download/v2.1.1/glow_2.1.1_Linux_x86_64.tar.gz

    log "Extracting..."
    tar xzf glow_2.1.1_Linux_x86_64.tar.gz

    log "Installing to ~/.local/bin..."
    mv glow_2.1.1_Linux_x86_64/glow ~/.local/bin/
    chmod +x ~/.local/bin/glow

    cd - > /dev/null
    rm -rf "$temp_dir"

    log_success "glow installed successfully! (~/.local/bin/glow)"
    log_warn "Make sure ~/.local/bin is in your PATH"
}

install_lazydocker() {
    log "Installing lazydocker..."

    local temp_dir=$(mktemp -d)
    cd "$temp_dir"

    log "Downloading lazydocker install script..."
    curl -s https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash

    cd - > /dev/null
    rm -rf "$temp_dir"

    log_success "lazydocker installed successfully!"
}

install_nerd_fonts() {
    log "Installing Nerd Fonts for terminal icons..."

    local fonts_dir="$HOME/.local/share/fonts"
    local temp_dir=$(mktemp -d)
    mkdir -p "$fonts_dir"

    cd "$temp_dir"

    # Array of popular Nerd Fonts
    local fonts=(
        "JetBrainsMono"
        "FiraCode"
        "Hack"
        "Meslo"
        "UbuntuMono"
    )

    for font in "${fonts[@]}"; do
        log "Downloading $font Nerd Font..."
        local url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font}.zip"

        if curl -fsSL "$url" -o "${font}.zip"; then
            log "Extracting $font..."
            unzip -q "${font}.zip" -d "$font" || true

            log "Installing $font..."
            cp "$font"/*.ttf "$fonts_dir/" 2>/dev/null || true
            cp "$font"/*.otf "$fonts_dir/" 2>/dev/null || true
            echo "  ✓ $font installed"
        else
            log_warn "Failed to download $font (skipping)"
        fi
    done

    log "Updating font cache..."
    fc-cache -fv "$fonts_dir" &>/dev/null || true

    cd - > /dev/null
    rm -rf "$temp_dir"

    log_success "Nerd Fonts installed successfully!"
    echo
    echo "Configure your terminal to use a Nerd Font:"
    echo "  Konsole: Settings → Edit Profile → Appearance → Font"
    echo "  Ghostty: ~/.config/ghostty/config → font-family = JetBrainsMono Nerd Font"
    echo "  Verify: fc-list | grep -i nerd"
}

install_gitleaks() {
    log "Installing gitleaks (secret scanner for git)..."

    # Gitleaks version - update periodically
    local GITLEAKS_VERSION="8.21.2"
    local ARCH="x64"

    # Detect architecture
    case $(uname -m) in
        x86_64) ARCH="x64" ;;
        aarch64|arm64) ARCH="arm64" ;;
        armv7l) ARCH="armv7" ;;
        *) log_error "Unsupported architecture: $(uname -m)"; return 1 ;;
    esac

    local GITLEAKS_URL="https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_${ARCH}.tar.gz"

    mkdir -p ~/.local/bin

    local temp_dir=$(mktemp -d)
    cd "$temp_dir"

    log "Downloading gitleaks v${GITLEAKS_VERSION}..."
    if ! curl -fsSL "$GITLEAKS_URL" -o gitleaks.tar.gz; then
        log_error "Failed to download gitleaks"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi

    log "Extracting..."
    tar xzf gitleaks.tar.gz

    log "Installing to ~/.local/bin..."
    mv gitleaks ~/.local/bin/
    chmod +x ~/.local/bin/gitleaks

    cd - > /dev/null
    rm -rf "$temp_dir"

    # Set up global git template with pre-commit hook
    log "Setting up git pre-commit hook template..."
    mkdir -p ~/.git-templates/hooks
    mkdir -p ~/.config/gitleaks

    # Create the pre-commit hook
    cat > ~/.git-templates/hooks/pre-commit << 'HOOK'
#!/bin/bash
# Gitleaks pre-commit hook - scans for secrets before every commit

if ! command -v gitleaks &> /dev/null; then
    echo "⚠️  gitleaks not installed, skipping secret scan"
    exit 0
fi

CONFIG_ARG=""
if [ -f ".gitleaks.toml" ]; then
    CONFIG_ARG="-c .gitleaks.toml"
elif [ -f "${HOME}/.config/gitleaks/gitleaks.toml" ]; then
    CONFIG_ARG="-c ${HOME}/.config/gitleaks/gitleaks.toml"
fi

echo "🔍 Scanning staged changes for secrets..."
gitleaks git --staged --pre-commit --verbose $CONFIG_ARG

if [ $? -eq 1 ]; then
    echo ""
    echo "🚨 SECRETS DETECTED! Commit blocked."
    echo ""
    echo "Options:"
    echo "  1. Remove the secret from the file"
    echo "  2. Add to .gitleaksignore if false positive"
    echo "  3. Use --no-verify to bypass (NOT RECOMMENDED)"
    echo ""
    exit 1
fi
exit 0
HOOK

    chmod +x ~/.git-templates/hooks/pre-commit

    # Configure git to use template
    git config --global init.templateDir ~/.git-templates

    log_success "gitleaks installed successfully!"
    echo
    echo "Secret scanning is now active:"
    echo "  • New repos (git init) automatically get the pre-commit hook"
    echo "  • Existing repos: cp ~/.git-templates/hooks/pre-commit .git/hooks/"
    echo "  • Global config: ~/.config/gitleaks/gitleaks.toml"
    echo "  • Test: echo 'api_key=\"sk-test123\"' > test.txt && git add test.txt && git commit -m test"
}

install_atuin() {
    log "Installing atuin (smart shell history)..."

    # Check if already installed
    if command -v atuin &>/dev/null; then
        log_warn "atuin is already installed: $(atuin --version)"
        return 0
    fi

    # Use official installer (works on all distros)
    log "Downloading and running atuin installer..."
    if ! curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh; then
        log_error "Failed to install atuin"
        return 1
    fi

    # Source the env to get atuin in PATH for this session
    if [[ -f "$HOME/.atuin/bin/env" ]]; then
        source "$HOME/.atuin/bin/env"
    fi

    local ATUIN_BIN="$HOME/.atuin/bin/atuin"

    # Initialize for current shell
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        log "Initializing atuin for zsh..."
        mkdir -p ~/.config/atuin
        "$ATUIN_BIN" init zsh --disable-up-arrow > ~/.config/atuin/init.zsh 2>/dev/null || true
    elif [[ -n "${BASH_VERSION:-}" ]]; then
        log "Initializing atuin for bash..."
        mkdir -p ~/.config/atuin
        "$ATUIN_BIN" init bash --disable-up-arrow > ~/.config/atuin/init.bash 2>/dev/null || true
    fi

    # Import existing history
    log "Importing existing shell history..."
    "$ATUIN_BIN" import auto 2>/dev/null || true

    log_success "atuin installed successfully!"
    echo
    echo "Add to your shell config (.zshrc, .bashrc, or .exports):"
    echo
    echo "  # Atuin PATH"
    echo "  export PATH=\"\$HOME/.atuin/bin:\$PATH\""
    echo "  eval \"\$(atuin init zsh --disable-up-arrow)\"  # or bash"
    echo
    echo "Or source the env file:"
    echo "  source \"\$HOME/.atuin/bin/env\""
    echo
    echo "Usage: Press Ctrl+R for smart history search"
}

# ==============================================================================
# Main Function
# ==============================================================================

main() {
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        log_error "Don't run this script as root. It will ask for sudo when needed."
        exit 1
    fi

    # Initialize log file
    echo "=== FRESH Installation Started $(date) ===" > "$LOGFILE"

    detect_system
    echo

    while true; do
        show_menu
        read -p "Select option [1-9, i, 0 to exit]: " -r choice
        echo
        echo

        case $choice in
            1) install_minimal; break ;;
            2) install_standard; break ;;
            3) install_developer; break ;;
            4) install_full; break ;;
            5) custom_install; break ;;
            6) show_tools ;;
            7) install_manual_tools; break ;;
            8) install_pai3; break ;;
            9) install_enhanced_shell; break ;;
            i|I) show_security_info ;;
            0)
                echo "Goodbye! 👋"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                sleep 1
                ;;
        esac
    done

    echo
    post_install_setup

    echo
    echo -e "${GREEN}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${GREEN}│                    🎉 INSTALLATION COMPLETE! 🎉         │${NC}"
    echo -e "${GREEN}└─────────────────────────────────────────────────────────┘${NC}"
    echo
    log_success "Fresh installation completed successfully!"
    echo "Log file: $LOGFILE"
    echo
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${PURPLE}🔒 Security Researchers:${NC} Check out these complementary tools:"
    echo
    echo -e "  ${GREEN}•${NC} ${WHITE}toolbelt${NC} - Comprehensive security tool installer"
    echo -e "    ${CYAN}https://github.com/rpriven/toolbelt${NC}"
    echo
    echo -e "  ${GREEN}•${NC} ${WHITE}tmux-recon${NC} - Pentesting automation & shell environment"
    echo -e "    ${CYAN}https://github.com/rpriven/tmux-recon${NC}"
    echo
    echo -e "  ${YELLOW}💡 Run fresh again and choose option 9 for more details${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    echo "Recommended next steps:"
    echo "  1. Install your dotfiles: git clone <your-dotfiles-repo>"
    echo "  2. Set up shell configuration (zsh, bash, etc.)"
    echo "  3. Configure git: git config --global user.name/user.email"
    if command -v docker &>/dev/null; then
        echo "  4. Log out and back in for docker group changes"
    fi
    echo
}

# ==============================================================================
# Script Entry Point
# ==============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
