# bash completion for git-wt
# Loaded automatically when git-wt.sh is sourced

__git_wt_worktree_branches() {
    git worktree list --porcelain 2>/dev/null | sed -n 's/^branch refs\/heads\///p'
}

__git_wt_branches() {
    git branch -a --format='%(refname:short)' 2>/dev/null
}

_git_wt() {
    local cur prev subcmd
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    # Find the subcommand (first non-flag arg after "wt")
    subcmd=""
    local i
    for (( i=1; i < COMP_CWORD; i++ )); do
        case "${COMP_WORDS[i]}" in
            wt) continue ;;
            -*) continue ;;
            *)  subcmd="${COMP_WORDS[i]}"; break ;;
        esac
    done

    # Complete subcommands
    if [[ -z "$subcmd" ]]; then
        COMPREPLY=( $(compgen -W "add pr rm cd ls init help" -- "$cur") )
        return
    fi

    case "$subcmd" in
        rm)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=( $(compgen -W "--force -f" -- "$cur") )
            else
                COMPREPLY=( $(compgen -W "$(__git_wt_worktree_branches)" -- "$cur") )
            fi
            ;;
        cd)
            COMPREPLY=( $(compgen -W "$(__git_wt_worktree_branches)" -- "$cur") )
            ;;
        add)
            COMPREPLY=( $(compgen -W "$(__git_wt_branches)" -- "$cur") )
            ;;
    esac
}

# Completion for the `wt` shell wrapper
_wt() {
    local cur prev subcmd
    cur="${COMP_WORDS[COMP_CWORD]}"

    # Find subcommand
    subcmd=""
    local i
    for (( i=1; i < COMP_CWORD; i++ )); do
        case "${COMP_WORDS[i]}" in
            -*) continue ;;
            *)  subcmd="${COMP_WORDS[i]}"; break ;;
        esac
    done

    if [[ -z "$subcmd" ]]; then
        COMPREPLY=( $(compgen -W "add pr rm cd ls init help" -- "$cur") )
        return
    fi

    case "$subcmd" in
        rm)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=( $(compgen -W "--force -f" -- "$cur") )
            else
                COMPREPLY=( $(compgen -W "$(__git_wt_worktree_branches)" -- "$cur") )
            fi
            ;;
        cd)
            COMPREPLY=( $(compgen -W "$(__git_wt_worktree_branches)" -- "$cur") )
            ;;
        add)
            COMPREPLY=( $(compgen -W "$(__git_wt_branches)" -- "$cur") )
            ;;
    esac
}

complete -F _wt wt
