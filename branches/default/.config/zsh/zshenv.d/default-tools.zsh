# Editor and tooling configuration

# Editor
export EDITOR="nvim"

# Bat (better cat) theme
export BAT_THEME="Everforest Dark Medium"

# Volta (Node.js version manager)
export VOLTA_HOME="$HOME/.volta"
if [[ -d "$VOLTA_HOME/bin" ]] && [[ ":$PATH:" != *":$VOLTA_HOME/bin:"* ]]; then
    path=("$VOLTA_HOME/bin" $path)
    export PATH
fi

