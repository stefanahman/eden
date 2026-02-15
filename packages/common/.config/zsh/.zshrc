# Eden ZSH Configuration

# Set XDG base directories
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# Add Eden bin directory to PATH
export PATH="$HOME/.eden/bin:$PATH"

# Platform-specific configuration (Homebrew PATH, etc.) — must come before tool inits
[ -f "$XDG_CONFIG_HOME/zsh/platform.zsh" ] && source "$XDG_CONFIG_HOME/zsh/platform.zsh"

# fnm (Fast Node Manager) - per-project Node version management
if command -v fnm >/dev/null 2>&1; then
    eval "$(fnm env --use-on-cd)"
fi

# fzf fuzzy finder
if command -v fzf >/dev/null 2>&1; then
    eval "$(fzf --zsh)"
fi

# zoxide smart directory jumper (use: z <partial-path>)
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# Starship prompt
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

# Shell history
HISTFILE="$XDG_DATA_HOME/zsh/history"
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
mkdir -p "$(dirname "$HISTFILE")"

# Local machine overrides (git-ignored, for secrets and machine-specific settings)
[ -f "$XDG_CONFIG_HOME/eden/local/zshrc.local" ] && source "$XDG_CONFIG_HOME/eden/local/zshrc.local"
