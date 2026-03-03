#!/usr/bin/env bats

setup() {
    load ../test_helper
    load_git_wt_functions
}

@test "sanitize_branch: replaces slash with dash" {
    run sanitize_branch "feature/login"
    assert_output "feature-login"
}

@test "sanitize_branch: lowercases uppercase letters" {
    run sanitize_branch "Feature-Login"
    assert_output "feature-login"
}

@test "sanitize_branch: handles multiple slashes" {
    run sanitize_branch "feat/scope/deep/branch"
    assert_output "feat-scope-deep-branch"
}

@test "sanitize_branch: handles already clean branch name" {
    run sanitize_branch "simple-branch"
    assert_output "simple-branch"
}

@test "sanitize_branch: handles empty string" {
    run sanitize_branch ""
    assert_output ""
}

@test "sanitize_branch: preserves dots" {
    run sanitize_branch "release/1.2.3"
    assert_output "release-1.2.3"
}

@test "sanitize_branch: preserves hyphens" {
    run sanitize_branch "my-feature/sub-part"
    assert_output "my-feature-sub-part"
}

@test "sanitize_branch: combined uppercase and slashes" {
    run sanitize_branch "Feature/JIRA-123/Some-Task"
    assert_output "feature-jira-123-some-task"
}
