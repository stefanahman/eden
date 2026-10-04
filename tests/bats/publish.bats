#!/usr/bin/env bats
# `eden-publish` finds what changed since the last release, or says why it
# cannot. Runs against a sandbox repo with a local "canonical" remote; only
# --dry-run, so nothing is tagged, pushed or released.

setup() {
    EDEN_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    export HOME="$BATS_TEST_TMPDIR/home"
    export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
    export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.test GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.test
    mkdir -p "$HOME"
    REMOTE="$BATS_TEST_TMPDIR/remote/stefanahman/eden.git"   # matches the canonical pattern
    git init -q --bare -b main "$REMOTE"
    WORK="$BATS_TEST_TMPDIR/work"
    git init -q -b main "$WORK"
    cd "$WORK"
    git remote add origin "$REMOTE"
    mkdir bin
    cp "$EDEN_ROOT/bin/eden-publish" bin/
    echo 0.1.0 > VERSION
    printf '# Changelog\n\n<!-- releases -->\n' > CHANGELOG.md
    git add -A && git commit -q -m "feat: the engine"
    git commit -q --allow-empty -m "chore(release): v0.1.0"
    RELEASE=$(git rev-parse --short HEAD)
}

push() { git push -q origin main; }

@test "a reachable tag: the changes since it" {
    git tag -a v0.1.0 -m v0.1.0
    git commit -q --allow-empty -m "feat: grafters"
    push
    run bin/eden-publish --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Generating CHANGELOG from v0.1.0..HEAD" ]]
    [[ "$output" =~ "- feat: grafters" ]]
}

@test "a tag outside main's history is refused, naming main's commit of that release" {
    # The release commit amended after tagging: the tag keeps the first one.
    # A body of its own: two empty commits with the same parent, message
    # and second would be one commit.
    git checkout -q -b old HEAD~1
    git commit -q --allow-empty -m "chore(release): v0.1.0" -m "the first try"
    git tag -a v0.1.0 -m v0.1.0
    git checkout -q main
    git commit -q --allow-empty -m "feat: grafters"
    push
    run bin/eden-publish --dry-run
    [ "$status" -eq 2 ]
    [[ "$output" =~ "v0.1.0 exists but is not in main's history" ]]
    [[ "$output" =~ "--since $RELEASE" ]]
    [[ ! "$output" =~ "Initial release" ]]
}

@test "--since lists the changes after the commit it names" {
    git commit -q --allow-empty -m "feat: grafters"
    git commit -q --allow-empty -m "docs: words"
    push
    run bin/eden-publish --dry-run --since "$RELEASE"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Generating CHANGELOG from $RELEASE..HEAD" ]]
    [[ "$output" =~ "- feat: grafters" ]]
    [[ ! "$output" =~ "- feat: the engine" ]]
}

@test "--since must be a commit in main's history" {
    git checkout -q -b side
    git commit -q --allow-empty -m "feat: elsewhere"
    SIDE=$(git rev-parse --short HEAD)
    git checkout -q main
    push
    run bin/eden-publish --dry-run --since "$SIDE"
    [ "$status" -eq 2 ]
    [[ "$output" =~ "is not in main's history" ]]
    run bin/eden-publish --dry-run --since nosuchref
    [ "$status" -eq 2 ]
    [[ "$output" =~ "no such commit" ]]
}

@test "no tag at all is a first release" {
    push
    run bin/eden-publish --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Initial release." ]]
}
