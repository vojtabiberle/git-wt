#!/usr/bin/env bats

setup() {
    load ../test_helper
}

@test "main dispatch: --help shows help" {
    run "$GIT_WT" --help
    assert_output --partial "git-wt — Git worktree helper"
}

@test "main dispatch: -h shows help" {
    run "$GIT_WT" -h
    assert_output --partial "git-wt — Git worktree helper"
}

@test "main dispatch: help subcommand shows help" {
    run "$GIT_WT" help
    assert_output --partial "git-wt — Git worktree helper"
}

@test "main dispatch: unknown command fails" {
    run "$GIT_WT" nonexistent
    assert_failure
    assert_output --partial "Unknown command: nonexistent"
}

@test "main dispatch: no arguments shows help" {
    run "$GIT_WT"
    assert_output --partial "USAGE"
}

@test "main dispatch: --non-interactive is a global flag" {
    # --non-interactive alone should default to help
    run "$GIT_WT" --non-interactive
    assert_output --partial "USAGE"
}
