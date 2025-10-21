# Eden Platform Configuration - macOS
# This file is sourced by .zshrc for macOS-specific settings

# Homebrew setup
if [[ -d "/opt/homebrew" ]]; then
    # Apple Silicon
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -d "/usr/local/Homebrew" ]]; then
    # Intel Mac
    eval "$(/usr/local/bin/brew shellenv)"
fi

# macOS-specific aliases
alias brew-clean='brew cleanup && brew autoremove'
alias brew-update='brew update && brew upgrade'

# macOS-specific environment variables
# (Add as needed)

