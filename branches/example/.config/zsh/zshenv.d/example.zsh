# Eden example branch — zsh env file
#
# graft-zsh symlinks this into ~/.config/zsh/zshenv.d/, which is sourced
# by ~/.config/zsh/.zshenv on shell startup. Use for env vars and PATH
# adjustments that should apply to all shells (login + non-login).

export EDEN_EXAMPLE_BRANCH="loaded"
