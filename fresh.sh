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
    [btop]="btop"
    [zoxide]="zoxide"
    [atuin]="atuin"
    [most]="most"
    [silversearcher-ag]="silversearcher-ag"
    [neofetch]="neofetch"
    [gawk]="gawk"
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
    [dust]="dust"
    [duf]="duf"
    [procs]="procs"
    [nnn]="nnn"
    [taskwarrior]="taskwarrior"
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
    if sudo apt update && sudo apt install -y "${tools_to_install[@]}"; then
        log_success "$category_name tools installed successfully"
    else
        log_error "Failed to install some $category_name tools"
        return 1
    fi
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
    echo -e "${CYAN}=== STANDARD INSTALLATION ===${NC}"
    echo "Minimal + productivity CLI tools"
    echo
    install_minimal
    install_tools STANDARD_TOOLS "Standard"
}

install_developer() {
    echo -e "${CYAN}=== DEVELOPER INSTALLATION ===${NC}"
    echo "Standard + development tools and languages"
    echo
    install_standard
    install_tools DEVELOPER_TOOLS "Developer"
}

install_full() {
    echo -e "${CYAN}=== FULL INSTALLATION ===${NC}"
    echo "Everything + security tools, multimedia, advanced utilities"
    echo
    install_developer
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
    echo -e "${GREEN}7)${NC} ${WHITE}PAI Setup${NC} - Install Personal AI Infrastructure v3"
    echo -e "${GREEN}8)${NC} ${WHITE}Enhanced Shell${NC} - Install enhanced shell commands only"
    echo -e "${GREEN}9)${NC} ${WHITE}Security Research${NC} - Info about pentesting & security tools"
    echo
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

    log_success "Post-installation setup completed"
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
        read -p "Select option [1-9, 0 to exit]: " -n 1 -r choice
        echo
        echo

        case $choice in
            1) install_minimal; break ;;
            2) install_standard; break ;;
            3) install_developer; break ;;
            4) install_full; break ;;
            5) custom_install; break ;;
            6) show_tools ;;
            7) install_pai3; break ;;
            8) install_enhanced_shell; break ;;
            9) show_security_info ;;
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
