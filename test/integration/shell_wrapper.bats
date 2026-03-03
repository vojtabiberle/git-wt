#!/usr/bin/env bats

setup() {
    load ../test_helper
    setup_test_repo
}

teardown() {
    teardown_test_repo
}

@test "shell_wrapper: wt function is defined after sourcing" {
    run bash -c "source '$GIT_WT_SH' && type -t wt"
    assert_success
    assert_output "function"
}

@test "shell_wrapper: wt ls passes through to git wt" {
    run bash -c "cd '$TEST_REPO' && source '$GIT_WT_SH' && wt ls"
    assert_success
    assert_output --partial "master"
}

@test "shell_wrapper: wt add creates worktree and outputs path" {
    run bash -c "cd '$TEST_REPO' && source '$GIT_WT_SH' && wt --non-interactive add feature/shell-test"
    assert_success
    local wt_path="${lines[-1]}"
    assert [ -d "$wt_path" ]
}

@test "shell_wrapper: wt cd changes directory" {
    # First create the worktree
    bash -c "cd '$TEST_REPO' && source '$GIT_WT_SH' && wt --non-interactive add feature/cd-shell" >/dev/null 2>&1

    # Then test cd — check PWD after wt cd
    run bash -c "cd '$TEST_REPO' && source '$GIT_WT_SH' && wt cd feature/cd-shell && pwd"
    assert_success
    # PWD should be inside the worktree, not the original repo
    refute_output "$TEST_REPO"
}
