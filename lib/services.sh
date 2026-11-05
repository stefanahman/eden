# shellcheck shell=bash
# services.sh — the macOS services a branch sets up, and whether they run.
#
#   eden_karabiner_running   exit 0 when Karabiner-Elements' core service
#                            runs, which is what does the remapping.
#
# eden grow and eden doctor both ask here, so they cannot disagree about
# whether Karabiner runs.

# 16 renamed karabiner_grabber to Karabiner-Core-Service. Its DriverKit
# extension, its user server and its Settings app carry "Karabiner" in
# their paths too, and run without it: the driver stays loaded whenever
# Karabiner is installed.
eden_karabiner_running() {
    pgrep -f 'Karabiner-Core-Service|karabiner_grabber' >/dev/null 2>&1
}
