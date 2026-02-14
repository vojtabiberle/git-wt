# git-wt

Git worktree helper that combines worktree creation, setup, and navigation into a single command.

```bash
wt add feature/login master   # create worktree + cd into it
wt cd feature/login           # cd into existing worktree
wt rm feature/login           # remove worktree
wt ls                              # list worktrees
```

## Installation

Clone the repo and add two lines to your `~/.zshrc` (or `~/.bashrc`):

```bash
export PATH="$HOME/Projects/git-wt:$PATH"
source ~/Projects/git-wt/git-wt.sh
```

This gives you:

- **`git wt`** — works as a git subcommand (via PATH auto-discovery)
- **`wt`** — shell function wrapper that adds `cd` support for `add` and `cd` commands

Alternatively, use a git alias without the shell wrapper (no auto-cd):

```bash
git config --global alias.wt '!git-wt'
```

## Commands

| Command | Description |
|---|---|
| `wt add <branch> [source]` | Create a worktree for `<branch>`, optionally from `[source]` branch |
| `wt rm [branch]` | Remove a worktree. Without args, removes the current one |
| `wt cd <branch>` | cd into an existing worktree |
| `wt ls` | List all worktrees (`git worktree list`) |
| `wt init` | Interactively create `worktree.conf.local` |
| `wt help` | Show help |

## Configuration

git-wt uses two shell-sourceable config files in each project's repo root:

**`worktree.conf`** — committed project defaults:

```bash
WORKTREE_DIR=".."
WORKTREE_PREFIX="myapp"
WORKTREE_SETUP=("./setup.sh")
```

**`worktree.conf.local`** — personal overrides (gitignored):

```bash
WORKTREE_DIR="/home/me/worktrees"
WORKTREE_SETUP=("./setup.sh" "direnv allow")
```

The script sources `worktree.conf` first, then `worktree.conf.local`. Later values fully replace earlier ones.

### Variables

| Variable | Default | Description |
|---|---|---|
| `WORKTREE_DIR` | `..` | Base directory for worktrees (relative to repo root) |
| `WORKTREE_PREFIX` | repo name | Prefix for worktree directory names |
| `WORKTREE_SETUP` | `()` | Commands to run after creating a worktree |

### Directory naming

Format: `<base>/<prefix>-<sanitized-branch>`

Branch `feature/login` with prefix `myapp` and base `..`:
```
../myapp-feature-login
```

Sanitization: `/` becomes `-`, everything lowercased.

## How it works

`git-wt` is a standalone bash script. When placed in PATH, git discovers it automatically as `git wt` (git's subcommand convention for `git-<name>` executables).

The `wt` shell function (from `git-wt.sh`) wraps `git wt` and adds directory changing — a subprocess can't change the parent shell's directory, so the function captures the path from stdout and runs `cd`.

All info messages go to stderr. Only the worktree path goes to stdout (as the last line), enabling the shell wrapper to capture it.

## Example workflow

```bash
# Set up per-project config
cd ~/projects/my-app
cat > worktree.conf <<'EOF'
WORKTREE_DIR=".."
WORKTREE_PREFIX="my-app"
WORKTREE_SETUP=("npm install")
EOF
echo "worktree.conf.local" >> .gitignore

# Create a worktree (auto-creates branch, runs setup, cd's into it)
wt add feature/login master

# Work on the feature...

# List worktrees
wt ls

# Switch to another worktree
wt cd main

# Clean up
wt rm feature/login
```

## License

MIT
