# Claude AFK mode — when active, use a standalone SSH key and skip commit signing
# so Claude can push unattended (no 1Password biometrics required)
#
# Toggle with: claude-afk / claude-back

_claude_mode_file="${XDG_STATE_HOME:-$HOME/.local/state}/claude/mode"

if [[ -f "$_claude_mode_file" ]] && [[ "$(< "$_claude_mode_file")" == "afk" ]]; then
    export GIT_SSH_COMMAND="ssh -i $HOME/.ssh/id_ed25519_claude_afk -o IdentitiesOnly=yes -o IdentityAgent=none"
    export GIT_CONFIG_COUNT=1
    export GIT_CONFIG_KEY_0="commit.gpgsign"
    export GIT_CONFIG_VALUE_0="false"
fi

claude-afk() {
    local mode_file="${XDG_STATE_HOME:-$HOME/.local/state}/claude/mode"
    mkdir -p "$(dirname "$mode_file")"
    echo "afk" > "$mode_file"
    echo "Claude AFK mode ON — new Claude sessions will use standalone SSH key, no commit signing"
}

claude-back() {
    local mode_file="${XDG_STATE_HOME:-$HOME/.local/state}/claude/mode"
    rm -f "$mode_file"
    echo "Claude AFK mode OFF — new Claude sessions will use 1Password as normal"
}

unset _claude_mode_file
