#!/usr/bin/env bats

setup() {
    load ../test_helper
    load_git_wt_functions
    # Set up config variables as load_config would
    WORKTREE_DIR="/tmp/worktrees"
}

@test "worktree_path_for: with prefix" {
    WORKTREE_PREFIX="myapp"
    run worktree_path_for "feature/login"
    assert_output "/tmp/worktrees/myapp-feature-login"
}

@test "worktree_path_for: without prefix" {
    WORKTREE_PREFIX=""
    run worktree_path_for "feature/login"
    assert_output "/tmp/worktrees/feature-login"
}

@test "worktree_path_for: normalizes uppercase" {
    WORKTREE_PREFIX="MyApp"
    run worktree_path_for "Feature/LOGIN"
    assert_output "/tmp/worktrees/MyApp-feature-login"
}
