# zsh completion for git-wt
# Loaded automatically when git-wt.sh is sourced

__git_wt_worktree_branches() {
    local branches
    branches=("${(@f)$(git worktree list --porcelain 2>/dev/null | sed -n 's/^branch refs\/heads\///p')}")
    echo "${branches[@]}"
}

__git_wt_branches() {
    local branches
    branches=("${(@f)$(git branch -a --format='%(refname:short)' 2>/dev/null)}")
    echo "${branches[@]}"
}

_git-wt() {
    local -a subcommands
    subcommands=(
        'add:Create a worktree for a branch'
        'pr:Create worktree from PR/MR number'
        'rm:Remove a worktree'
        'cd:cd into an existing worktree'
        'ls:List all worktrees'
        'init:Interactively create worktree.conf.local'
        'help:Show help'
    )

    if (( CURRENT == 2 )); then
        _describe 'subcommand' subcommands
        return
    fi

    local subcmd="${words[2]}"
    case "$subcmd" in
        rm)
            if [[ "$words[CURRENT]" == -* ]]; then
                local -a flags=('--force' '-f')
                compadd -a flags
            else
                local -a wt_branches
                wt_branches=("${(@f)$(git worktree list --porcelain 2>/dev/null | sed -n 's/^branch refs\/heads\///p')}")
                compadd -a wt_branches
            fi
            ;;
        cd)
            local -a wt_branches
            wt_branches=("${(@f)$(git worktree list --porcelain 2>/dev/null | sed -n 's/^branch refs\/heads\///p')}")
            compadd -a wt_branches
            ;;
        add)
            local -a all_branches
            all_branches=("${(@f)$(git branch -a --format='%(refname:short)' 2>/dev/null)}")
            compadd -a all_branches
            ;;
    esac
}

# Register for `git wt` (git's completion system looks for _git-wt)
# Completion for the `wt` shell wrapper
_wt() {
    _git-wt "$@"
}

if (( $+functions[compdef] )); then
    compdef _git-wt git-wt
    compdef _wt wt
fi
