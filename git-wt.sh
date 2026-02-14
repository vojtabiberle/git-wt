# git-wt.sh — source this file to get the `wt` shell function
# Usage: source ~/Projects/git-wt/git-wt.sh
#
# Provides `wt` which wraps `git wt` with cd support:
#   wt add <branch> [source]   - create worktree + cd into it
#   wt cd  <branch>            - cd into existing worktree
#   wt rm / wt ls / wt init    - pass through to git wt

wt() {
    case "${1:-}" in
        add)
            local output
            output="$(git wt "$@")" || return $?
            echo "$output"
            local path
            path="$(echo "$output" | tail -1)"
            [[ -d "$path" ]] && cd "$path"
            ;;
        cd)
            local dir
            dir="$(git wt "$@")" && cd "$dir"
            ;;
        *)
            git wt "$@"
            ;;
    esac
}
