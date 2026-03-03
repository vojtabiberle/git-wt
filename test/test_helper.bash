# test/test_helper.bash — shared setup for all git-wt tests

bats_load_library bats-support
bats_load_library bats-assert
bats_load_library bats-file

# Paths to the scripts under test
export GIT_WT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/git-wt"
export GIT_WT_SH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/git-wt.sh"

# Source git-wt functions without running main()
load_git_wt_functions() {
    export __GIT_WT_TESTING=1
    source "$GIT_WT"
}

# Create an isolated git repo for integration tests
setup_test_repo() {
    export TEST_REPO="$BATS_TEST_TMPDIR/repo"
    mkdir -p "$TEST_REPO"
    git -C "$TEST_REPO" init --initial-branch=master
    git -C "$TEST_REPO" config user.email "test@test.com"
    git -C "$TEST_REPO" config user.name "Test"
    echo "init" > "$TEST_REPO/file.txt"
    git -C "$TEST_REPO" add file.txt
    git -C "$TEST_REPO" commit -m "initial commit"
    cd "$TEST_REPO"
}

# Clean up worktrees and temp directory
teardown_test_repo() {
    # Remove any worktrees created during the test
    if [[ -d "$TEST_REPO" ]]; then
        cd /
        git -C "$TEST_REPO" worktree list --porcelain 2>/dev/null \
            | awk '/^worktree / { print substr($0, 10) }' \
            | while read -r wt; do
                [[ "$wt" == "$TEST_REPO" ]] && continue
                git -C "$TEST_REPO" worktree remove --force "$wt" 2>/dev/null || true
            done
    fi
    # BATS_TEST_TMPDIR is cleaned up automatically by bats
}

# Create a bare remote + clone for remote-aware tests
setup_remote_repo() {
    export REMOTE_REPO="$BATS_TEST_TMPDIR/remote.git"
    git clone --bare "$TEST_REPO" "$REMOTE_REPO"
    git -C "$TEST_REPO" remote add origin "$REMOTE_REPO"
    git -C "$TEST_REPO" fetch origin
}

# Push a new branch to the remote only (not local)
add_remote_branch() {
    local branch="$1"
    local tmp_clone="$BATS_TEST_TMPDIR/tmp-clone"
    git clone "$REMOTE_REPO" "$tmp_clone" 2>/dev/null
    git -C "$tmp_clone" config user.email "test@test.com"
    git -C "$tmp_clone" config user.name "Test"
    git -C "$tmp_clone" checkout -b "$branch"
    echo "remote-$branch" > "$tmp_clone/remote-file.txt"
    git -C "$tmp_clone" add remote-file.txt
    git -C "$tmp_clone" commit -m "add $branch on remote"
    git -C "$tmp_clone" push origin "$branch"
    rm -rf "$tmp_clone"
    # Fetch so the test repo sees it
    git -C "$TEST_REPO" fetch origin
}
