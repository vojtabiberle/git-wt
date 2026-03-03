#!/usr/bin/env bats

setup() {
    load ../test_helper
    setup_test_repo
    setup_remote_repo
    REAL_GIT="$(command -v git)"
}

teardown() {
    teardown_test_repo
}

# Helper: create a mock bin with a git wrapper that fakes forge detection
# but passes all other git commands through to the real git binary.
# Usage: setup_forge_mock "https://github.com/test/repo.git"
setup_forge_mock() {
    local forge_url="$1"
    MOCK_BIN="$BATS_TEST_TMPDIR/mock-bin"
    mkdir -p "$MOCK_BIN"

    cat > "$MOCK_BIN/git" <<ENDMOCK
#!/usr/bin/env bash
if [[ "\$1" == "remote" && "\$2" == "get-url" ]]; then
    echo "$forge_url"
    exit 0
fi
exec "$REAL_GIT" "\$@"
ENDMOCK
    chmod +x "$MOCK_BIN/git"

    # Prepend mock-bin so the git wrapper is found first
    export PATH="$MOCK_BIN:$(dirname "$GIT_WT"):$PATH"
}

# -- Argument validation -------------------------------------------------------

@test "cmd_pr: fails without arguments" {
    run "$GIT_WT" pr
    assert_failure
    assert_output --partial "Usage: git wt pr <number>"
}

@test "cmd_pr: rejects non-numeric input" {
    run "$GIT_WT" pr abc
    assert_failure
    assert_output --partial "Invalid PR/MR number"
    assert_output --partial "must be a positive integer"
}

@test "cmd_pr: rejects zero" {
    run "$GIT_WT" pr 0
    assert_failure
    assert_output --partial "Invalid PR/MR number"
}

@test "cmd_pr: rejects negative number" {
    run "$GIT_WT" pr -1
    assert_failure
    assert_output --partial "Invalid PR/MR number"
}

@test "cmd_pr: rejects decimal number" {
    run "$GIT_WT" pr 1.5
    assert_failure
    assert_output --partial "Invalid PR/MR number"
}

@test "cmd_pr: rejects number with leading zero" {
    run "$GIT_WT" pr 01
    assert_failure
    assert_output --partial "Invalid PR/MR number"
}

# -- Forge detection integration ------------------------------------------------

@test "cmd_pr: fails for unsupported forge" {
    setup_forge_mock "https://bitbucket.org/user/repo.git"
    run "$GIT_WT" pr 1
    assert_failure
    assert_output --partial "Cannot detect forge"
}

# -- CLI missing (isolated bash subprocess to avoid PATH pollution) ------------

@test "cmd_pr: fails when gh CLI is not installed" {
    mkdir -p "$BATS_TEST_TMPDIR/no-cli"
    run bash -c "
        export __GIT_WT_TESTING=1
        source '$GIT_WT'
        detect_forge() { echo github; }
        export PATH='$BATS_TEST_TMPDIR/no-cli'
        cmd_pr 1
    "
    assert_failure
    assert_output --partial "GitHub CLI (gh) is required"
}

@test "cmd_pr: fails when glab CLI is not installed (gitlab)" {
    mkdir -p "$BATS_TEST_TMPDIR/no-cli"
    run bash -c "
        export __GIT_WT_TESTING=1
        source '$GIT_WT'
        detect_forge() { echo gitlab; }
        export PATH='$BATS_TEST_TMPDIR/no-cli'
        cmd_pr 1
    "
    assert_failure
    assert_output --partial "GitLab CLI (glab) is required"
}

# -- GitHub: successful flow with mock gh --------------------------------------

@test "cmd_pr: creates worktree from github PR using mock gh" {
    add_remote_branch "feature/pr-branch"
    setup_forge_mock "https://github.com/test/repo.git"

    cat > "$MOCK_BIN/gh" <<'MOCK'
#!/usr/bin/env bash
# Expect: gh pr view <number> --json headRefName -q .headRefName
if [[ "$1" == "pr" && "$2" == "view" && "$4" == "--json" ]]; then
    echo "feature/pr-branch"
    exit 0
fi
exit 1
MOCK
    chmod +x "$MOCK_BIN/gh"

    run "$GIT_WT" --non-interactive pr 42
    assert_success
    assert_output --partial "PR/MR #42"
    assert_output --partial "feature/pr-branch"
    # Last line is the worktree path
    local wt_path="${lines[-1]}"
    assert [ -d "$wt_path" ]
    assert [ -f "$wt_path/remote-file.txt" ]
}

# -- GitLab: successful flow with mock glab ------------------------------------

@test "cmd_pr: creates worktree from gitlab MR using mock glab" {
    add_remote_branch "feature/mr-branch"
    setup_forge_mock "https://gitlab.com/user/repo.git"

    cat > "$MOCK_BIN/glab" <<'MOCK'
#!/usr/bin/env bash
# Expect: glab mr view <number> -F json
if [[ "$1" == "mr" && "$2" == "view" ]]; then
    echo '{"source_branch":"feature/mr-branch","target_branch":"main"}'
    exit 0
fi
exit 1
MOCK
    chmod +x "$MOCK_BIN/glab"

    run "$GIT_WT" --non-interactive pr 10
    assert_success
    assert_output --partial "PR/MR #10"
    assert_output --partial "feature/mr-branch"
    local wt_path="${lines[-1]}"
    assert [ -d "$wt_path" ]
    assert [ -f "$wt_path/remote-file.txt" ]
}

# -- GitHub: gh fails to resolve PR --------------------------------------------

@test "cmd_pr: fails when gh cannot resolve PR number" {
    setup_forge_mock "https://github.com/test/repo.git"

    cat > "$MOCK_BIN/gh" <<'MOCK'
#!/usr/bin/env bash
echo "GraphQL: Could not resolve to a PullRequest" >&2
exit 1
MOCK
    chmod +x "$MOCK_BIN/gh"

    run "$GIT_WT" pr 999
    assert_failure
    assert_output --partial "Failed to get branch for PR #999"
}

# -- GitHub: gh returns empty branch -------------------------------------------

@test "cmd_pr: fails when gh returns empty branch name" {
    setup_forge_mock "https://github.com/test/repo.git"

    cat > "$MOCK_BIN/gh" <<'MOCK'
#!/usr/bin/env bash
echo ""
exit 0
MOCK
    chmod +x "$MOCK_BIN/gh"

    run "$GIT_WT" pr 1
    assert_failure
    assert_output --partial "Could not determine branch name"
}

# -- Shell wrapper: wt pr routes through add|pr case --------------------------

@test "cmd_pr: shell wrapper routes pr command correctly" {
    export PATH="$(dirname "$GIT_WT"):$PATH"
    source "$GIT_WT_SH"
    # Call wt pr with no args — should fail with cmd_pr's usage error,
    # proving the shell wrapper routes 'pr' to git wt pr.
    run wt pr
    assert_failure
    assert_output --partial "Usage: git wt pr <number>"
}
