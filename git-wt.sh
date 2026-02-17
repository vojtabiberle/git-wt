# git-wt.sh — source this file to get the `wt` shell function
# Usage: source ~/Projects/git-wt/git-wt.sh
#
# Provides `wt` which wraps `git wt` with cd support:
#   wt add <branch> [source]   - create worktree + cd into it
#   wt cd  <branch>            - cd into existing worktree
#   wt rm / wt ls / wt init    - pass through to git wt

# Load completions
_git_wt_dir="${BASH_SOURCE[0]:-${(%):-%x}}"
_git_wt_dir="$(cd "$(dirname "$_git_wt_dir")" && pwd)"
if [[ -n "${ZSH_VERSION:-}" ]]; then
    [[ -f "$_git_wt_dir/completions/git-wt.zsh" ]] && source "$_git_wt_dir/completions/git-wt.zsh"
elif [[ -n "${BASH_VERSION:-}" ]]; then
    [[ -f "$_git_wt_dir/completions/git-wt.bash" ]] && source "$_git_wt_dir/completions/git-wt.bash"
fi
unset _git_wt_dir

wt() {
    # Find the subcommand, skipping any leading global flags
    local cmd=""
    local arg
    for arg in "$@"; do
        case "$arg" in
            --non-interactive|--yes) ;;
            --help|-h) cmd="help"; break ;;
            -*) cmd="$arg"; break ;;
            *)  cmd="$arg"; break ;;
        esac
    done

    case "$cmd" in
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
