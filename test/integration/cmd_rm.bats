#!/usr/bin/env bats

setup() {
    load ../test_helper
    setup_test_repo
}

teardown() {
    teardown_test_repo
}

@test "cmd_rm: removes existing worktree" {
    "$GIT_WT" --non-interactive add feature/to-remove >/dev/null 2>&1
    run "$GIT_WT" rm feature/to-remove
    assert_success
    assert_output --partial "Worktree removed"
}

@test "cmd_rm: fails for nonexistent worktree" {
    run "$GIT_WT" rm nonexistent-branch
    assert_failure
    assert_output --partial "No worktree found"
}

@test "cmd_rm: --force removes dirty worktree" {
    local wt_path
    wt_path="$("$GIT_WT" --non-interactive add feature/dirty 2>/dev/null | tail -n1)"
    echo "uncommitted" > "$wt_path/dirty.txt"

    run "$GIT_WT" rm --force feature/dirty
    assert_success
    assert_output --partial "Worktree removed"
}

@test "cmd_rm: runs WORKTREE_TEARDOWN commands" {
    cat > "$TEST_REPO/worktree.conf" <<'EOF'
WORKTREE_TEARDOWN=("touch $BATS_TEST_TMPDIR/teardown-ran")
EOF
    "$GIT_WT" --non-interactive add feature/teardown-test >/dev/null 2>&1

    export BATS_TEST_TMPDIR
    run "$GIT_WT" rm feature/teardown-test
    assert_success
    assert [ -f "$BATS_TEST_TMPDIR/teardown-ran" ]
}

@test "cmd_rm: warns and continues when teardown command fails" {
    cat > "$TEST_REPO/worktree.conf" <<'EOF'
WORKTREE_TEARDOWN=("bin/nonexistent-script")
EOF
    "$GIT_WT" --non-interactive add feature/bad-teardown >/dev/null 2>&1

    run "$GIT_WT" rm feature/bad-teardown
    assert_success
    assert_output --partial "Teardown command failed"
    assert_output --partial "Worktree removed"
}

@test "cmd_rm: skips teardown when worktree directory is already gone" {
    cat > "$TEST_REPO/worktree.conf" <<'EOF'
WORKTREE_TEARDOWN=("echo should-not-run")
EOF
    local wt_path
    wt_path="$("$GIT_WT" --non-interactive add feature/gone 2>/dev/null | tail -n1)"

    # Manually remove the directory (simulating external deletion)
    rm -rf "$wt_path"

    run "$GIT_WT" rm --force feature/gone
    assert_success
    assert_output --partial "Worktree directory not found, skipping teardown"
}

@test "cmd_rm: fails without branch when not in worktree" {
    run "$GIT_WT" rm
    assert_failure
    assert_output --partial "Not in a worktree"
}
