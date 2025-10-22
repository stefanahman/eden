# .zshenv - Entry point for zsh configuration
# Source the XDG-compliant configuration if it exists

if [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/.zshenv" ]]; then
    source "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/.zshenv"
fi
