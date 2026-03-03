#!/usr/bin/env bats

setup() {
    load ../test_helper
}

teardown() {
    teardown_test_repo 2>/dev/null || true
}

@test "edge_case: running outside git repo fails" {
    cd "$BATS_TEST_TMPDIR"
    run "$GIT_WT" ls
    assert_failure
}

@test "edge_case: directory conflict detected" {
    setup_test_repo
    local wt_path="$BATS_TEST_TMPDIR/repo-blocked"
    mkdir -p "$wt_path"

    run "$GIT_WT" --non-interactive add blocked
    assert_failure
    assert_output --partial "exists but is not a registered worktree"
}

@test "edge_case: uppercase branch names are normalized" {
    setup_test_repo

    run "$GIT_WT" --non-interactive add UPPERCASE-BRANCH
    assert_success
    local wt_path="${lines[-1]}"
    # Path should contain lowercased version
    [[ "$wt_path" == *"uppercase-branch"* ]]
}

@test "edge_case: deeply nested slash branch names" {
    setup_test_repo
    run "$GIT_WT" --non-interactive add a/b/c/d/e
    assert_success
    local wt_path="${lines[-1]}"
    [[ "$wt_path" == *"a-b-c-d-e"* ]]
}
