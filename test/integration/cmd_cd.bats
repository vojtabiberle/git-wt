#!/usr/bin/env bats

setup() {
    load ../test_helper
    setup_test_repo
}

teardown() {
    teardown_test_repo
}

@test "cmd_cd: prints worktree path" {
    local wt_path
    wt_path="$("$GIT_WT" --non-interactive add feature/cd-test 2>/dev/null | tail -n1)"

    run "$GIT_WT" cd feature/cd-test
    assert_success
    assert_output "$wt_path"
}

@test "cmd_cd: fails without arguments" {
    run "$GIT_WT" cd
    assert_failure
    assert_output --partial "Usage:"
}

@test "cmd_cd: fails for nonexistent worktree" {
    run "$GIT_WT" cd no-such-branch
    assert_failure
    assert_output --partial "No worktree found"
}
