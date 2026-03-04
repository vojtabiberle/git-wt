#!/usr/bin/env bats

setup() {
    load ../test_helper
    setup_test_repo
}

teardown() {
    teardown_test_repo
}

@test "cmd_add: creates worktree for new branch" {
    run "$GIT_WT" --non-interactive add feature/test
    assert_success
    # Last line of stdout is the worktree path
    local wt_path="${lines[-1]}"
    assert [ -d "$wt_path" ]
    # Branch should exist
    git show-ref --verify --quiet "refs/heads/feature/test"
}

@test "cmd_add: creates worktree from source branch" {
    git checkout -b develop
    echo "develop content" > dev.txt
    git add dev.txt && git commit -m "develop commit"
    git checkout master

    run "$GIT_WT" --non-interactive add feature/from-dev develop
    assert_success
    local wt_path="${lines[-1]}"
    assert [ -f "$wt_path/dev.txt" ]
}

@test "cmd_add: returns existing worktree path if already exists" {
    run "$GIT_WT" --non-interactive add feature/dup
    assert_success
    local first_path="${lines[-1]}"

    run "$GIT_WT" --non-interactive add feature/dup
    assert_success
    local second_path="${lines[-1]}"
    assert_equal "$first_path" "$second_path"
}

@test "cmd_add: fails without branch argument" {
    run "$GIT_WT" add
    assert_failure
    assert_output --partial "Usage:"
}

@test "cmd_add: --force resets existing branch to source" {
    git checkout -b existing-branch
    echo "old" > old.txt
    git add old.txt && git commit -m "old commit"
    git checkout master

    echo "new" > new.txt
    git add new.txt && git commit -m "new on master"

    run "$GIT_WT" --non-interactive add existing-branch master --force
    assert_success
    local wt_path="${lines[-1]}"
    assert [ -f "$wt_path/new.txt" ]
}

@test "cmd_add: fails when source specified for existing branch without --force" {
    git branch existing-branch
    run "$GIT_WT" --non-interactive add existing-branch master
    assert_failure
    assert_output --partial "already exists"
    assert_output --partial "--force"
}

@test "cmd_add: handles slashes in branch names" {
    run "$GIT_WT" --non-interactive add feat/scope/deep
    assert_success
    local wt_path="${lines[-1]}"
    assert [ -d "$wt_path" ]
    # Directory name should have dashes not slashes
    [[ "$wt_path" == *"feat-scope-deep"* ]]
}

@test "cmd_add: runs WORKTREE_SETUP commands" {
    cat > "$TEST_REPO/worktree.conf" <<'EOF'
WORKTREE_SETUP=("touch .setup-marker")
EOF
    run "$GIT_WT" --non-interactive add feature/setup-test
    assert_success
    local wt_path="${lines[-1]}"
    assert [ -f "$wt_path/.setup-marker" ]
}

@test "cmd_add: picks up remote branch with --non-interactive" {
    setup_remote_repo
    add_remote_branch "feature/remote-only"

    run "$GIT_WT" --non-interactive add feature/remote-only
    assert_success
    local wt_path="${lines[-1]}"
    assert [ -d "$wt_path" ]
    assert [ -f "$wt_path/remote-file.txt" ]
}

@test "cmd_add: warns and continues when setup command fails" {
    cat > "$TEST_REPO/worktree.conf" <<'EOF'
WORKTREE_SETUP=("bin/nonexistent-script")
EOF
    run "$GIT_WT" --non-interactive add feature/bad-setup
    assert_success
    assert_output --partial "Setup command failed"
    assert_output --partial "Worktree ready at:"
}

@test "cmd_add: directory conflict fails gracefully" {
    # Compute expected worktree path: WORKTREE_DIR defaults to ".." (parent of repo),
    # WORKTREE_PREFIX defaults to repo dirname ("repo"), branch sanitized
    local wt_path="$BATS_TEST_TMPDIR/repo-conflict-branch"
    mkdir -p "$wt_path"

    run "$GIT_WT" --non-interactive add conflict-branch
    assert_failure
    assert_output --partial "exists but is not a registered worktree"
}
