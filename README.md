# Fresh - Linux System Setup Tool

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25.svg)](https://www.gnu.org/software/bash/)

A comprehensive, interactive installation script for setting up new Linux systems and VPS instances with modern CLI tools and enhanced productivity workflows.

## 🚀 Features

- **Multiple Installation Tiers**: Choose from Minimal, Standard, Developer, or Full setups
- **Modern CLI Tools**: Includes the latest productivity tools like `fzf`, `ripgrep`, `bat`, `eza`, `atuin`
- **Enhanced Shell Configuration**: Advanced aliases and workflows for power users
- **PAI3 Integration**: Optional Personal AI Infrastructure setup with voice server and Claude integration
- **Interactive Menus**: User-friendly selection process with progress tracking
- **Smart Detection**: Automatically detects your system and installs appropriate packages

## 🛠️ Installation Tiers

### 📦 Minimal
Essential tools for any Linux system:
- `curl`, `wget`, `git`, `unzip`, `tree`, `tmux`, `htop`, `nano`, `jq`

### 🔧 Standard
Common CLI productivity tools:
- **Minimal** + `fzf`, `ripgrep`, `fd`, `bat`, `eza`, `btop`, `zoxide`, `atuin`

### 👨‍💻 Developer
Development tools and languages:
- **Standard** + `build-essential`, `cmake`, `nodejs`, `docker`, `python3-pip`

### 🎯 Full
Everything including security and multimedia:
- **Developer** + `keepassxc`, `lynis`, `ffmpeg`, `yt-dlp`, `taskwarrior`

### 🚀 Enhanced Shell
Advanced shell configuration with:
- **Context Manager (`cm`)**: Navigate and search knowledge bases with fzf
- **Smart File Operations**: Enhanced file browsing with syntax highlighting
- **Git Integration**: Visual git log browser and enhanced workflows
- **Process Management**: Interactive process browser and management
- **Smart History**: Atuin integration for intelligent command history

### 🤖 PAI3 Setup
Complete Personal AI Infrastructure including:
- Voice server with ElevenLabs integration
- Enhanced Claude Code configuration
- AI workflow automation tools
- **Enhanced Shell** configuration included

## 📋 Quick Start

```bash
# Clone the repository
git clone https://github.com/rpriven/fresh.git
cd fresh

# Make executable and run
chmod +x fresh.sh
./fresh.sh
```

## 🎛️ Menu Options

```
┌─────────────────────────────────────────────────────────────────────┐
│                        FRESH - Linux Setup                         │
├─────────────────────────────────────────────────────────────────────┤
│  1. Minimal    - Essential CLI tools for any Linux system          │
│  2. Standard   - Minimal + modern productivity tools               │
│  3. Developer  - Standard + development tools (docker, nodejs)     │
│  4. Full       - All tools + security, multimedia, system utils    │
│  5. Custom     - Choose specific tool categories                   │
│  6. Show Tools - Display available tools by category              │
│  7. PAI3       - Install Personal AI Infrastructure               │
│  8. Enhanced Shell - Install enhanced shell commands only         │
│  0. Exit                                                          │
└─────────────────────────────────────────────────────────────────────┘
```

## 💡 Enhanced Shell Commands

After installing Enhanced Shell configuration, you'll have access to:

### 📂 Context Management
```bash
cm          # Browse all contexts with fzf preview
cms         # Search content across all contexts
cmr         # Show recently modified contexts
cmn         # Create new context file
cmt         # Display context directory tree
```

### 🔍 Advanced File Operations
```bash
fzfg        # Grep with ripgrep + jump to line in editor
fzfd        # Directory browser with tree preview
vp          # File browser with bat syntax highlighting
gfzf        # Git log browser with commit preview
psg         # Process browser with fzf selection
```

### 📚 Smart Tools
```bash
h           # Smart history search with atuin
findcmd     # Search available commands
```

## 🔧 Requirements

- **OS**: Ubuntu/Debian-based Linux distributions
- **Package Manager**: `apt` (dpkg-based systems)
- **Privileges**: `sudo` access for package installation
- **Shell**: Bash 4.0+ (Enhanced Shell features work with bash/zsh)

## 📁 What Gets Installed

### Core Tools
- **File Management**: `bat` (syntax highlighting), `eza` (modern ls), `fd` (fast find)
- **Search**: `fzf` (fuzzy finder), `ripgrep` (fast grep), `ag` (silver searcher)
- **Navigation**: `zoxide` (smart cd), `atuin` (smart history)
- **System**: `btop` (system monitor), `dust` (disk usage), `procs` (process viewer)

### Development
- **Languages**: Node.js, Python 3, build tools
- **Containers**: Docker, Docker Compose
- **Version Control**: Git, tig (git browser)
- **Editors**: Micro, Nano

### Security & Utilities
- **Security**: Lynis, AIDE, KeePassXC
- **Multimedia**: FFmpeg, yt-dlp
- **Productivity**: TaskWarrior, NCurses Disk Usage

## 🎯 Usage Examples

### Quick Productivity Setup
```bash
./fresh.sh
# Select option 2: Standard
# Gets you modern CLI tools for daily use
```

### Developer Workstation
```bash
./fresh.sh
# Select option 3: Developer
# Includes all productivity tools + development environment
```

### Enhanced Workflow Setup
```bash
./fresh.sh
# Select option 8: Enhanced Shell
# Adds advanced shell commands and workflows
```

### Complete AI Infrastructure
```bash
./fresh.sh
# Select option 7: PAI3
# Installs complete AI infrastructure + enhanced shell
```

## 🔗 Integration

Fresh integrates seamlessly with:
- **Dotfiles**: Install your personal configurations after Fresh setup
- **Shell Frameworks**: Works with Oh My Zsh, Prezto, or standalone configs
- **Package Managers**: Complements Homebrew, Nix, or other package managers
- **CI/CD**: Use in automation scripts for consistent environment setup

## 🤝 Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for:
- Additional tool suggestions
- New installation tiers
- Platform support (CentOS, Arch, etc.)
- Bug fixes and improvements

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built for modern Linux productivity workflows
- Inspired by the need for consistent, reproducible development environments
- Integrates the best modern CLI tools available

---

**Fresh** - Because every new system deserves a fresh start with the right tools. 🚀