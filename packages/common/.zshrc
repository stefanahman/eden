# .zshrc - Entry point for zsh interactive configuration
# Source the XDG-compliant configuration if it exists

if [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/.zshrc" ]]; then
    source "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/.zshrc"
fi
