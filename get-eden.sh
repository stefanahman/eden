#!/bin/bash
# get-eden.sh — Remote installer for Eden.
#
# Designed to be run via curl|bash:
#   curl -fsSL https://raw.githubusercontent.com/stefanahman/eden/main/get-eden.sh | bash
#
# Or with overrides:
#   curl -fsSL .../get-eden.sh | bash -s -- --target ~/code/eden --ref v0.1.0
#
# Clones Eden into the target directory, then invokes ./install.sh with the
# chosen ref (default: latest release tag).
set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}▸${NC} $1"; }
err()  { echo -e "${RED}✗${NC} $1" >&2; exit 1; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }

REPO_URL="https://github.com/stefanahman/eden.git"
TARGET="$HOME/eden"
REF=""   # passed through to install.sh; empty = install.sh's default (latest)

while [ $# -gt 0 ]; do
    case "$1" in
        --target) TARGET="$2"; shift 2 ;;
        --ref)    REF="$2"; shift 2 ;;
        --main)   REF="--main"; shift ;;
        --latest) REF="--latest"; shift ;;
        v[0-9]*)  REF="$1"; shift ;;
        -h|--help)
            sed -n '2,11p' "$0" | sed -E 's/^# ?//'
            exit 0
            ;;
        *) err "Unknown arg: $1" ;;
    esac
done

command -v git >/dev/null 2>&1 || err "git is required but not installed."

if [ -d "$TARGET/.git" ]; then
    warn "Eden already exists at $TARGET. Use 'eden update' to update."
    exit 1
fi

if [ -e "$TARGET" ]; then
    err "Target $TARGET exists but is not an Eden clone. Move it aside or pass --target."
fi

log "Cloning Eden into $TARGET…"
git clone --quiet "$REPO_URL" "$TARGET" || err "Clone failed."

log "Running installer…"
cd "$TARGET"
if [ -n "$REF" ]; then
    ./install.sh "$REF"
else
    ./install.sh
fi
