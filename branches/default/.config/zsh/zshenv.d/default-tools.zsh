# Editor and tooling configuration

# Editor
export EDITOR="nvim"

# Docker
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# Bat (better cat) theme
export BAT_THEME="Everforest Dark Medium"

# Volta (Node.js version manager)
export VOLTA_HOME="$HOME/.volta"
if [[ -d "$VOLTA_HOME/bin" ]] && [[ ":$PATH:" != *":$VOLTA_HOME/bin:"* ]]; then
    path=("$VOLTA_HOME/bin" $path)
    export PATH
fi

