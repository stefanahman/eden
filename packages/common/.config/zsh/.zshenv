# .zshenv - Environment variables for zsh (loaded for all shells)
# This file is sourced on all invocations of the shell

# XDG Base Directory specification
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# PATH configuration
# Add user binaries to PATH if not already present
typeset -U path  # Keep unique entries in path array

# Add ~/.local/bin (where stowed binaries go)
if [[ -d "$HOME/.local/bin" ]] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    path=("$HOME/.local/bin" $path)
fi

# Add ~/.eden/bin (where eden-* helper scripts go)
if [[ -d "$HOME/.eden/bin" ]] && [[ ":$PATH:" != *":$HOME/.eden/bin:"* ]]; then
    path=("$HOME/.eden/bin" $path)
fi

# Export PATH
export PATH

# Load additional environment configuration from zshenv.d/
# This allows branches and user customizations to extend base config
if [[ -d "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/zshenv.d" ]]; then
    for file in "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/zshenv.d"/*.zsh(N); do
        source "$file"
    done
fi
