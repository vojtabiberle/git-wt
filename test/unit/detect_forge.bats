#!/usr/bin/env bats

setup() {
    load ../test_helper
    load_git_wt_functions
    setup_test_repo
    setup_remote_repo
}

teardown() {
    teardown_test_repo
}

@test "detect_forge: identifies github.com SSH URL" {
    git remote set-url origin "git@github.com:user/repo.git"
    run detect_forge
    assert_success
    assert_output "github"
}

@test "detect_forge: identifies github.com HTTPS URL" {
    git remote set-url origin "https://github.com/user/repo.git"
    run detect_forge
    assert_success
    assert_output "github"
}

@test "detect_forge: identifies gitlab SSH URL" {
    git remote set-url origin "git@gitlab.com:user/repo.git"
    run detect_forge
    assert_success
    assert_output "gitlab"
}

@test "detect_forge: identifies gitlab HTTPS URL" {
    git remote set-url origin "https://gitlab.com/user/repo.git"
    run detect_forge
    assert_success
    assert_output "gitlab"
}

@test "detect_forge: identifies self-hosted gitlab" {
    git remote set-url origin "git@gitlab.company.com:group/repo.git"
    run detect_forge
    assert_success
    assert_output "gitlab"
}

@test "detect_forge: fails for unknown forge" {
    git remote set-url origin "https://bitbucket.org/user/repo.git"
    run detect_forge
    assert_failure
    assert_output --partial "Cannot detect forge"
}

@test "detect_forge: fails when no origin remote" {
    git remote remove origin
    run detect_forge
    assert_failure
    assert_output --partial "No 'origin' remote found"
}
