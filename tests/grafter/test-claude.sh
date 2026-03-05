#!/bin/bash
# Integration tests for graft-claude
# Runs in a temp directory sandbox — safe against real $HOME

# Capture real repo root before sandbox overrides EDEN_ROOT
REAL_EDEN_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GRAFTER="$REAL_EDEN_ROOT/packages/eden/.eden/libexec/grafters/graft-claude"

source "$(dirname "$0")/../helpers.sh"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  graft-claude tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# =============================================================================
# Test 1: No branches file
# =============================================================================
sandbox_setup

# Remove branches file (sandbox_setup creates the dir but not the file)
rm -f "$XDG_CONFIG_HOME/eden/branches"

describe "no branches file exits 0 with skip message"
output=$("$GRAFTER" 2>&1) || true
assert_output_contains "$output" "No branches registered"

sandbox_teardown

# =============================================================================
# Test 2: Empty branches file
# =============================================================================
sandbox_setup

touch "$XDG_CONFIG_HOME/eden/branches"

describe "empty branches file exits 0 with no-configs message"
output=$("$GRAFTER" 2>&1) || true
assert_output_contains "$output" "No Claude configs found"

sandbox_teardown

# =============================================================================
# Test 3: Global rules grafting
# =============================================================================
sandbox_setup

branch=$(create_test_branch "test-branch")
mkdir -p "$branch/.claude/rules"
echo "# Test rule" > "$branch/.claude/rules/test-rule.md"
register_branch "$branch"

describe "global rules create symlink"
output=$("$GRAFTER" 2>&1)
assert_symlink "$HOME/.claude/rules/test-rule.md" "$branch/.claude/rules/test-rule.md"

sandbox_teardown

# =============================================================================
# Test 4: Global agents grafting
# =============================================================================
sandbox_setup

branch=$(create_test_branch "test-branch")
mkdir -p "$branch/.claude/agents"
echo "# Test agent" > "$branch/.claude/agents/test-agent.md"
register_branch "$branch"

describe "global agents create symlink"
output=$("$GRAFTER" 2>&1)
assert_symlink "$HOME/.claude/agents/test-agent.md" "$branch/.claude/agents/test-agent.md"

sandbox_teardown

# =============================================================================
# Test 5: Global skills grafting (directory symlink)
# =============================================================================
sandbox_setup

branch=$(create_test_branch "test-branch")
mkdir -p "$branch/.claude/skills/my-skill"
echo "# My Skill" > "$branch/.claude/skills/my-skill/SKILL.md"
register_branch "$branch"

describe "global skills create directory symlink"
output=$("$GRAFTER" 2>&1)
assert_symlink "$HOME/.claude/skills/my-skill" "$branch/.claude/skills/my-skill"

sandbox_teardown

# =============================================================================
# Test 6: Idempotency
# =============================================================================
sandbox_setup

branch=$(create_test_branch "test-branch")
mkdir -p "$branch/.claude/rules"
echo "# Test rule" > "$branch/.claude/rules/idem.md"
register_branch "$branch"

# Run twice
"$GRAFTER" > /dev/null 2>&1

describe "second run reports already linked"
output=$("$GRAFTER" 2>&1)
assert_output_contains "$output" "already linked"

sandbox_teardown

# =============================================================================
# Test 7: Cross-branch conflict
# =============================================================================
sandbox_setup

branch1=$(create_test_branch "branch-a")
mkdir -p "$branch1/.claude/rules"
echo "# Rule from A" > "$branch1/.claude/rules/conflict.md"

branch2=$(create_test_branch "branch-b")
mkdir -p "$branch2/.claude/rules"
echo "# Rule from B" > "$branch2/.claude/rules/conflict.md"

register_branch "$branch1"
register_branch "$branch2"

describe "cross-branch conflict is reported"
output=$("$GRAFTER" 2>&1)
assert_output_contains "$output" "Conflicts detected"

sandbox_teardown

# =============================================================================
# Test 8: Regular file conflict (not a symlink)
# =============================================================================
sandbox_setup

branch=$(create_test_branch "test-branch")
mkdir -p "$branch/.claude/rules"
echo "# Rule" > "$branch/.claude/rules/existing.md"
register_branch "$branch"

# Pre-create a regular file at target
mkdir -p "$HOME/.claude/rules"
echo "# Existing" > "$HOME/.claude/rules/existing.md"

describe "regular file conflict is reported"
output=$("$GRAFTER" 2>&1)
assert_output_contains "$output" "not a symlink"

sandbox_teardown

# =============================================================================
# Test 9: Project scope basic
# =============================================================================
sandbox_setup

branch=$(create_test_branch "test-branch")
project_target="$SANDBOX/project-target"
mkdir -p "$project_target"

mkdir -p "$branch/projects/myapp/.claude/rules"
echo "# Project rule" > "$branch/projects/myapp/.claude/rules/proj.md"
echo "$project_target" > "$branch/projects/myapp/.eden-target"
register_branch "$branch"

describe "project scope creates symlink in target dir"
output=$("$GRAFTER" 2>&1)
assert_is_symlink "$project_target/.claude/rules/proj.md"

sandbox_teardown

# =============================================================================
# Test 10: Nested project scope (e.g. projects/games/greenwash/)
# =============================================================================
sandbox_setup

branch=$(create_test_branch "test-branch")
project_target="$SANDBOX/nested-target"
mkdir -p "$project_target"

mkdir -p "$branch/projects/games/greenwash/.claude/rules"
echo "# Nested rule" > "$branch/projects/games/greenwash/.claude/rules/nested.md"
echo "$project_target" > "$branch/projects/games/greenwash/.eden-target"
register_branch "$branch"

describe "nested project scope creates symlink"
output=$("$GRAFTER" 2>&1)
assert_is_symlink "$project_target/.claude/rules/nested.md"

describe "nested project uses relative path as owner"
assert_output_contains "$output" "test-branch:games/greenwash"

sandbox_teardown

# =============================================================================
# Test 10b: Dirs without .eden-target are silently skipped (organizational)
# =============================================================================
sandbox_setup

branch=$(create_test_branch "test-branch")
mkdir -p "$branch/projects/just-a-folder/.claude/rules"
echo "# Rule" > "$branch/projects/just-a-folder/.claude/rules/rule.md"
# No .eden-target file — this is just an organizational directory
register_branch "$branch"

describe "dir without .eden-target is silently skipped"
output=$("$GRAFTER" 2>&1)
assert_output_not_contains "$output" "just-a-folder"

sandbox_teardown

# =============================================================================
# Test 10c: Multiple projects at mixed depths
# =============================================================================
sandbox_setup

branch=$(create_test_branch "test-branch")
target_a="$SANDBOX/target-a"
target_b="$SANDBOX/target-b"
target_c="$SANDBOX/target-c"
mkdir -p "$target_a" "$target_b" "$target_c"

# Flat project
mkdir -p "$branch/projects/flat/.claude/rules"
echo "# Flat" > "$branch/projects/flat/.claude/rules/flat.md"
echo "$target_a" > "$branch/projects/flat/.eden-target"

# Nested project
mkdir -p "$branch/projects/games/deep/.claude/rules"
echo "# Deep" > "$branch/projects/games/deep/.claude/rules/deep.md"
echo "$target_b" > "$branch/projects/games/deep/.eden-target"

# Deeper project
mkdir -p "$branch/projects/work/clients/acme/.claude/rules"
echo "# Acme" > "$branch/projects/work/clients/acme/.claude/rules/acme.md"
echo "$target_c" > "$branch/projects/work/clients/acme/.eden-target"

register_branch "$branch"

output=$("$GRAFTER" 2>&1)

describe "flat project discovered"
assert_is_symlink "$target_a/.claude/rules/flat.md"

describe "nested project discovered"
assert_is_symlink "$target_b/.claude/rules/deep.md"

describe "deeply nested project discovered"
assert_is_symlink "$target_c/.claude/rules/acme.md"

sandbox_teardown

# =============================================================================
# Test 11: Non-existent target directory
# =============================================================================
sandbox_setup

branch=$(create_test_branch "test-branch")
mkdir -p "$branch/projects/ghost/.claude/rules"
echo "# Rule" > "$branch/projects/ghost/.claude/rules/rule.md"
echo "/nonexistent/path/nowhere" > "$branch/projects/ghost/.eden-target"
register_branch "$branch"

describe "non-existent target dir shows warning"
output=$("$GRAFTER" 2>&1)
assert_output_contains "$output" "not found"

sandbox_teardown

# =============================================================================
# Test 12: Mixed scopes (global + project)
# =============================================================================
sandbox_setup

branch=$(create_test_branch "test-branch")
project_target="$SANDBOX/project-target"
mkdir -p "$project_target"

# Global
mkdir -p "$branch/.claude/rules"
echo "# Global" > "$branch/.claude/rules/global.md"

# Project
mkdir -p "$branch/projects/myapp/.claude/rules"
echo "# Project" > "$branch/projects/myapp/.claude/rules/local.md"
echo "$project_target" > "$branch/projects/myapp/.eden-target"

register_branch "$branch"

describe "global rule created"
output=$("$GRAFTER" 2>&1)
assert_symlink "$HOME/.claude/rules/global.md" "$branch/.claude/rules/global.md"

describe "project rule created alongside global"
assert_is_symlink "$project_target/.claude/rules/local.md"

sandbox_teardown

# =============================================================================
# Test 13: Comments and blank lines in branches file
# =============================================================================
sandbox_setup

branch=$(create_test_branch "real-branch")
mkdir -p "$branch/.claude/rules"
echo "# Rule" > "$branch/.claude/rules/real.md"

# Write branches file with comments and blanks
cat > "$XDG_CONFIG_HOME/eden/branches" <<EOF
# This is a comment
   # Indented comment

$branch

EOF
register_branch ""  # extra blank line (no-op but tests robustness)

describe "comments and blank lines are ignored"
output=$("$GRAFTER" 2>&1)
assert_symlink "$HOME/.claude/rules/real.md" "$branch/.claude/rules/real.md"

sandbox_teardown

# =============================================================================
# Results
# =============================================================================

report
