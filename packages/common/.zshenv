# Eden ZSH Environment
# This file is sourced by zsh for all invocations (login, interactive, scripts)
# Keep it minimal - only essential environment variables

# XDG Base Directory specification
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# Point zsh to use XDG-compliant directory
export ZDOTDIR="${XDG_CONFIG_HOME}/zsh"

