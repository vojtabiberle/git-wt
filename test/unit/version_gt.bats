#!/usr/bin/env bats

setup() {
    load ../test_helper
    load_git_wt_functions
}

@test "version_gt: higher major version" {
    run version_gt "2.0.0" "1.0.0"
    assert_success
}

@test "version_gt: higher minor version" {
    run version_gt "1.2.0" "1.1.0"
    assert_success
}

@test "version_gt: higher patch version" {
    run version_gt "1.0.2" "1.0.1"
    assert_success
}

@test "version_gt: equal versions returns false" {
    run version_gt "1.0.0" "1.0.0"
    assert_failure
}

@test "version_gt: lower version returns false" {
    run version_gt "1.0.0" "2.0.0"
    assert_failure
}

@test "version_gt: multi-digit version comparison" {
    run version_gt "1.10.0" "1.9.0"
    assert_success
}
