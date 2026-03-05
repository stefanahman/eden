#!/bin/bash
# Shared test infrastructure for Eden tests
# Provides: reporting helpers, sandbox lifecycle, assertion functions

# --- Reporting ---
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

passed=0
failed=0

describe() {
    echo -en "${BLUE}Testing:${NC} $1 ... "
}

pass() {
    echo -e "${GREEN}✓${NC}"
    passed=$((passed + 1))
}

fail() {
    echo -e "${RED}✗${NC} ${1:-}"
    failed=$((failed + 1))
}

report() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "  Results: ${GREEN}${passed} passed${NC}, ${RED}${failed} failed${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    [[ $failed -eq 0 ]]
}

# --- Sandbox ---
SANDBOX=""
_ORIG_HOME=""
_ORIG_XDG=""
_ORIG_EDEN_ROOT=""

sandbox_setup() {
    SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/eden-test.XXXXXX")"

    # Save originals
    _ORIG_HOME="$HOME"
    _ORIG_XDG="${XDG_CONFIG_HOME:-}"
    _ORIG_EDEN_ROOT="${EDEN_ROOT:-}"

    # Redirect all grafter output to sandbox
    export HOME="$SANDBOX/home"
    export XDG_CONFIG_HOME="$HOME/.config"
    export EDEN_ROOT="$SANDBOX/eden-repo"

    mkdir -p "$HOME" "$XDG_CONFIG_HOME/eden" "$EDEN_ROOT"
}

sandbox_teardown() {
    if [[ -n "$SANDBOX" && -d "$SANDBOX" ]]; then
        rm -rf "$SANDBOX"
    fi

    # Restore originals
    [[ -n "$_ORIG_HOME" ]] && export HOME="$_ORIG_HOME"
    if [[ -n "$_ORIG_XDG" ]]; then
        export XDG_CONFIG_HOME="$_ORIG_XDG"
    else
        unset XDG_CONFIG_HOME
    fi
    if [[ -n "$_ORIG_EDEN_ROOT" ]]; then
        export EDEN_ROOT="$_ORIG_EDEN_ROOT"
    else
        unset EDEN_ROOT
    fi
}

trap 'sandbox_teardown' EXIT

# --- Fixtures ---

# Create a test branch directory, return its path
create_test_branch() {
    local name="$1"
    local branch_dir="$SANDBOX/branches/$name"
    mkdir -p "$branch_dir"
    echo "$branch_dir"
}

# Register a branch path in the branches file
register_branch() {
    echo "$1" >> "$XDG_CONFIG_HOME/eden/branches"
}

# --- Assertions ---

assert_symlink() {
    local path="$1" expected_target="$2"
    if [[ -L "$path" ]]; then
        local actual
        actual=$(readlink "$path")
        if [[ "$actual" == "$expected_target" ]]; then
            pass
        else
            fail "symlink $path -> $actual (expected $expected_target)"
        fi
    else
        fail "$path is not a symlink"
    fi
}

assert_is_symlink() {
    local path="$1"
    if [[ -L "$path" ]]; then
        pass
    else
        fail "$path is not a symlink"
    fi
}

assert_not_exists() {
    if [[ ! -e "$1" && ! -L "$1" ]]; then
        pass
    else
        fail "$1 exists (expected absent)"
    fi
}

assert_file_exists() {
    if [[ -e "$1" ]]; then
        pass
    else
        fail "$1 does not exist"
    fi
}

assert_output_contains() {
    local output="$1" pattern="$2"
    if echo "$output" | grep -q "$pattern"; then
        pass
    else
        fail "output missing: $pattern"
    fi
}

assert_output_not_contains() {
    local output="$1" pattern="$2"
    if ! echo "$output" | grep -q "$pattern"; then
        pass
    else
        fail "output unexpectedly contains: $pattern"
    fi
}
