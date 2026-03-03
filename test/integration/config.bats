#!/usr/bin/env bats

setup() {
    load ../test_helper
    setup_test_repo
    load_git_wt_functions
}

teardown() {
    teardown_test_repo
}

@test "config: default prefix is repo directory name" {
    load_config
    assert_equal "$WORKTREE_PREFIX" "repo"
}

@test "config: worktree.conf overrides prefix" {
    cat > "$TEST_REPO/worktree.conf" <<'EOF'
WORKTREE_PREFIX="custom"
EOF
    load_config
    assert_equal "$WORKTREE_PREFIX" "custom"
}

@test "config: worktree.conf.local overrides worktree.conf" {
    cat > "$TEST_REPO/worktree.conf" <<'EOF'
WORKTREE_PREFIX="from-conf"
EOF
    cat > "$TEST_REPO/worktree.conf.local" <<'EOF'
WORKTREE_PREFIX="from-local"
EOF
    load_config
    assert_equal "$WORKTREE_PREFIX" "from-local"
}

@test "config: custom WORKTREE_DIR" {
    local custom_dir="$BATS_TEST_TMPDIR/custom-wt"
    mkdir -p "$custom_dir"
    cat > "$TEST_REPO/worktree.conf" <<EOF
WORKTREE_DIR="$custom_dir"
EOF
    load_config
    assert_equal "$WORKTREE_DIR" "$custom_dir"
}

@test "config: relative WORKTREE_DIR resolved from repo root" {
    mkdir -p "$TEST_REPO/../sibling-wt"
    cat > "$TEST_REPO/worktree.conf" <<'EOF'
WORKTREE_DIR="../sibling-wt"
EOF
    load_config
    # Should be an absolute path
    [[ "$WORKTREE_DIR" == /* ]]
    assert [ -d "$WORKTREE_DIR" ]
}

@test "config: WORKTREE_SETUP is an array" {
    cat > "$TEST_REPO/worktree.conf" <<'EOF'
WORKTREE_SETUP=("echo hello" "echo world")
EOF
    load_config
    assert_equal "${#WORKTREE_SETUP[@]}" 2
    assert_equal "${WORKTREE_SETUP[0]}" "echo hello"
    assert_equal "${WORKTREE_SETUP[1]}" "echo world"
}

@test "config: empty prefix produces clean path" {
    cat > "$TEST_REPO/worktree.conf" <<'EOF'
WORKTREE_PREFIX=""
EOF
    load_config
    local result
    result="$(worktree_path_for "my-branch")"
    # Should not have double slash or leading dash
    [[ "$result" != *"//"* ]]
    [[ "$result" == *"/my-branch" ]]
}
