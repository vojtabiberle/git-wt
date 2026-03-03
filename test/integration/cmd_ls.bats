#!/usr/bin/env bats

setup() {
    load ../test_helper
    setup_test_repo
}

teardown() {
    teardown_test_repo
}

@test "cmd_ls: lists main worktree" {
    run "$GIT_WT" ls
    assert_success
    assert_output --partial "$TEST_REPO"
    assert_output --partial "master"
}

@test "cmd_ls: lists added worktree" {
    "$GIT_WT" --non-interactive add feature/listed >/dev/null 2>&1

    run "$GIT_WT" ls
    assert_success
    assert_output --partial "feature/listed"
}
