# kdev

```
██╗  ██╗██████╗ ███████╗██╗   ██╗
██║ ██╔╝██╔══██╗██╔════╝██║   ██║
█████╔╝ ██║  ██║█████╗  ██║   ██║
██╔═██╗ ██║  ██║██╔══╝  ╚██╗ ██╔╝
██║  ██╗██████╔╝███████╗ ╚████╔╝
╚═╝  ╚═╝╚═════╝ ╚══════╝  ╚═══╝
```

**Keyboard-driven terminal dev environment on macOS.**

One command sets up Alacritty + tmux + Neovim + lazygit + lf. Another command
creates a git worktree with a 3-pane tmux layout — pi coding agent, lazygit,
and neovim — all pointed at the right directory.

## Requirements

| Tool    | Purpose                    |
|---------|----------------------------|
| macOS   | Target platform            |
| Homebrew| Package manager (auto-checked) |

Everything else is installed by `kdev setup`.

## Installation

```bash
# Clone the repo
git clone https://github.com/kmakiela96/kdev ~/kdev

# Symlink into PATH
ln -s ~/kdev/kdev ~/.local/bin/kdev

# Install all tools and write configs
kdev setup

# Verify
kdev --version
```

## Shell Completions

Add to `~/.zshrc` (zsh):

```zsh
eval "$(kdev --completions zsh)"
```

Or `~/.bashrc` (bash):

```bash
eval "$(kdev --completions bash)"
```

Completes subcommands, options, and worktree names:

```
$ kdev <TAB>
adding-new-features  delete  dev  launch  list  setup

$ kdev delete <TAB>
adding-new-features  feature-auth

$ kdev dev --<TAB>
--from  --help
```

## Quick Start

```bash
# Set up the full dev environment (first time only)
kdev setup

# Start working on a feature
cd ~/my-project
kdev dev feature-auth

# List worktrees
kdev list

# Clean up when done
kdev delete feature-auth
```

## How It Works

### `setup` — Install Everything

```bash
kdev setup          # install tools + write configs
kdev setup --plan   # dry run — show what would be done
```

Installs (idempotent — safe to re-run):

| Tool              | Method                       |
|-------------------|------------------------------|
| Alacritty         | `brew install --cask`        |
| tmux              | `brew install`               |
| Neovim            | `brew install`               |
| lazygit           | `brew install`               |
| lf                | `brew install`               |
| bat               | `brew install`               |
| git               | `brew install`               |
| node/npm          | `brew install`               |
| pi-coding-agent   | `npm install -g`             |
| tmux-resurrect    | `git clone` (plugin)         |

Configs written:

| File                                         | What                              |
|----------------------------------------------|-----------------------------------|
| `~/.config/alacritty/alacritty.toml`         | Alacritty config (Option key)     |
| `~/.config/tmux/tmux.conf`                   | Full tmux config (Tokyo Night)    |
| `~/.config/tmux/plugins/tmux-resurrect/`     | Session persistence plugin        |
| `~/.config/lf/`                              | lf config (lfrc, scope, icons)    |
| `~/.agents/skills/`                          | pi agent skills (ck, cqs, caveman, gangsta, monk) |
| `~/.pi/agent/AGENTS.md`                       | Global pi agent instructions      |
| `~/.zshrc`                                   | Shell completions (appended)      |

If `~/.tmux.conf` exists, it is backed up to `~/.tmux.conf.bak` and removed
so tmux reads the XDG-compliant location. If `~/.config/alacritty/alacritty.toml`
exists, it is backed up before writing the kdev version.

The Alacritty config sets `option_as_alt = "OnlyLeft"` so that:
- **Left Option** = Alt (tmux `M-1`…`M-9` window switching)
- **Right Option** = macOS compose (diacritics: ą ć ę ł ń ó ś ź ż)

### `dev` — Create Worktree + Start Session

```bash
kdev dev <name> [--from <ref>]
```

1. Creates `.worktrees/<name>/` as a git worktree on branch `<name>`
2. Adds `.worktrees` to `.gitignore`
3. Creates a tmux session (named after the repo) with a 3-pane layout:

```
┌──────────────────┬──────────────────┐
│                  │    lazygit       │
│    pi agent      │   (top-right)    │
│    (left, 50%)   ├──────────────────┤
│                  │    lf            │
│                  │  (bottom-right)  │
└──────────────────┴──────────────────┘
```

If the worktree already exists, just attaches/switches to the session.

Running `kdev <name>` without a subcommand is shorthand for `dev <name>`.

**Options:**
- `--from <ref>` — base ref for the new branch (default: main/master or HEAD)

**Examples:**
```bash
kdev dev feature-auth           # branch from default branch
kdev dev bugfix-42 --from main  # explicit base ref
kdev feature-auth               # shorthand (same as dev)
```

### `launch` — Attach to Existing Worktree

```bash
kdev launch <name>
```

Opens the tmux session for an existing worktree. Fails if the worktree
doesn't exist — use `dev` to create one.

### `list` — Show Worktrees

```bash
kdev list
```

Shows all worktrees with branch, dirty status, and tmux window state:

```
  my-project worktrees:  (session: my-project)

  NAME                 BRANCH               STATUS     TMUX
  ────                 ──────               ──────     ────
  feature-auth         feature-auth         clean      active
  bugfix-42            bugfix-42            dirty      open
  experiment           experiment           clean      none
```

### `delete` — Remove a Worktree

```bash
kdev delete <name> [--force]
```

Removes the worktree directory, prunes git metadata, and deletes the branch
(if it matches the worktree name). Also kills the tmux window.

- Without `--force`: fails if worktree is dirty or tmux window is open
- With `--force`: removes everything regardless

## Keybindings

All pane and window controls go through the `Ctrl-a` prefix — no conflicts
with applications running inside panes (lf, lazygit, nvim, etc.).

### tmux (prefix: Ctrl-a)

| Shortcut            | Action                           |
|---------------------|----------------------------------|
| `Ctrl-a h/j/k/l`   | Navigate panes                   |
| `Ctrl-a H/J/K/L`   | Swap pane position               |
| `Ctrl-a f`          | Toggle pane zoom (fullscreen)    |
| `Ctrl-a \|`         | Split pane vertically            |
| `Ctrl-a -`          | Split pane horizontally          |
| `Ctrl-a g`          | New window: lazygit              |
| `Ctrl-a e`          | New window: nvim                 |
| `Ctrl-a c`          | New window: shell                |
| `Ctrl-a d`          | Detach session                   |
| `Ctrl-a Ctrl-s`     | Save session (tmux-resurrect)    |
| `Ctrl-a Ctrl-r`     | Restore session (tmux-resurrect) |

### Window switching (no prefix)

| Shortcut      | Action                      |
|---------------|-----------------------------|
| `Option+1-9`  | Switch to window by number  |

## Persistence

- tmux sessions survive terminal close — reattach with `tmux attach`
- tmux-resurrect saves/restores sessions across tmux server restarts:
  - `Ctrl-a Ctrl-s` to save
  - `Ctrl-a Ctrl-r` to restore

## Customization

### Changing the layout

Edit `_setup_dev_layout()` in `kdev`. The function creates panes
using `tmux split-window` with percentage flags (`-p 50`, `-p 65`).

### Adding tools to setup

1. Add install call in `cmd_setup()` (both real and `--plan` branches)
2. Add to the `tools` array in the plan section
3. Run `kdev --test`

### tmux config

Edit `~/.config/tmux/tmux.conf` directly, or modify `_tmux_conf_content()`
in the script to make changes persist across `setup` re-runs.

## File Structure

```
~/.config/
  alacritty/
    alacritty.toml               # generated by setup (Option key)
  tmux/
    tmux.conf                    # generated by setup
    plugins/
      tmux-resurrect/            # session persistence
  nvim/
    init.lua                     # your neovim config (untouched)
```

## Self-test

```bash
kdev --test
```

67 tests covering git helpers, config generation (tmux + Alacritty),
dev/launch/list/delete commands (including broken worktree repair), tmux
layout, setup plan (including skills install), and meta flags.

## License

GPL v3 — see [LICENSE](LICENSE).
