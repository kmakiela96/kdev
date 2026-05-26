# kdev

```
██╗  ██╗██████╗ ███████╗██╗   ██╗
██║ ██╔╝██╔══██╗██╔════╝██║   ██║
█████╔╝ ██║  ██║█████╗  ██║   ██║
██╔═██╗ ██║  ██║██╔══╝  ╚██╗ ██╔╝
██║  ██╗██████╔╝███████╗ ╚████╔╝
╚═╝  ╚═╝╚═════╝ ╚══════╝  ╚═══╝
```

**A dumb vibe coded keyboard-driven terminal dev environment on macOS.**

One command sets up Alacritty + tmux + Neovim + lazygit + lf. Another command
creates a git worktree with a 3-pane tmux layout — pi coding agent, lazygit,
and lf — all pointed at the right directory.

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

# Or open a session on the current branch without a worktree
kdev here

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
| git-delta         | `brew install`               |
| git               | `brew install`               |
| node/npm          | `brew install`               |
| fzf               | `brew install`               |
| fd                | `brew install`               |
| pi-coding-agent   | `npm install -g`             |
| @ff-labs/pi-fff    | `pi install` (pi package)    |
| tmux-resurrect    | `git clone` (plugin)         |

Environment configured:

| Variable | Value | Where |
|----------|-------|-------|
| `PI_FFF_MODE` | `override` | shell rc file (auto-detected) |

Configs written:

| File                                         | What                              |
|----------------------------------------------|-----------------------------------|
| `~/.config/lazygit/config.yml`                      | lazygit config (delta syntax pager, vim editor) |
| `~/.config/alacritty/alacritty.toml`         | Alacritty config (Option key)     |
| `~/.config/tmux/tmux.conf`                   | Full tmux config (Tokyo Night)    |
| `~/.config/tmux/plugins/tmux-resurrect/`     | Session persistence plugin        |
| `~/.config/lf/`                              | lf config (lfrc, scope, icons)    |
| `~/.config/nvim/`                            | Neovim config (plugins, fzf-lua LSP tabedit, gitsigns, tabby, tab keymaps) |
| `~/.agents/skills/`                          | pi agent skills (ck, cqs, caveman, monk) |
| `~/.pi/agent/extensions/`                    | pi extensions (ck-pi-extension)  |
| `~/.pi/agent/AGENTS.md`                       | Global pi agent instructions      |
| `~/.zshrc`                                   | Shell completions (appended)      |

If `~/.tmux.conf` exists, it is backed up to `~/.tmux.conf.bak` and removed
so tmux reads the XDG-compliant location. If `~/.config/alacritty/alacritty.toml`
exists, it is backed up before writing the kdev version.

The Alacritty config sets `option_as_alt = "OnlyLeft"` so that:
- **Left Option** = Alt (tmux `M-1`…`M-9` window switching)
- **Right Option** = macOS compose (diacritics: ą ć ę ł ń ó ś ź ż)

### `here` — Open Session on Current Branch

```bash
kdev here
```

Opens the 3-pane dev layout in the repo root for the current branch — no
worktree created, no git fetch. Use when you want the layout without spinning
up a worktree (e.g. working directly on `main`).

Fails in detached HEAD state. Requires being inside a git repository. Works on repos with no commits yet (empty repos).

### `dev` — Create Worktree + Start Session

```bash
kdev dev <name> [--from <ref>]
```

1. Creates `.worktrees/<name>/` as a git worktree on branch `<name>`
2. Adds `.worktrees` to `.gitignore`
3. Creates a tmux session with a 3-pane layout:

```
┌──────────────────┬──────────────────┐
│                  │    lazygit       │
│    pi agent      │   (top-right)    │
│    (left, 50%)   ├──────────────────┤
│                  │    lf            │
│                  │  (bottom-right)  │
└──────────────────┴──────────────────┘
```

**Session model (browser-tab style):**
- Each terminal window gets its own tmux session (named `repo`, `repo_2`, ...)
- Each worktree becomes a tab (tmux window) in the session
- A worktree can only be open in one session at a time
- Opening the same worktree from another terminal switches you to where it's already open
- Running `kdev dev` from inside tmux adds tabs to the current session

If the worktree already exists, just attaches/switches to the session.

Running `kdev <name>` without a subcommand is shorthand for `dev <name>`.

See also `kdev here` for opening a session on the current branch without a worktree.

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

If the worktree is already open in another terminal, you'll get an error:
```
✗ Worktree 'feature-auth' is already open in session 'my-project' (another terminal).
  Switch to that terminal, or close the window there first.
```

### `list` — Show Worktrees

```bash
kdev list
```

Shows all worktrees with branch, dirty status, and tmux window state:

```
  my-project worktrees:  (prefix: my-project)

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

tmux uses two modes: **nav mode** (`Ctrl-a` toggle) for persistent vim-style
navigation, and **prefix** (`Ctrl-b`) for one-shot structural commands.

### Nav mode (Ctrl-a toggle on/off)

Press `Ctrl-a` to enter nav mode. Keys work repeatedly without re-pressing
the prefix. Press `Ctrl-a` or `Esc` to exit.

| Shortcut  | Action                           |
|-----------|----------------------------------|
| `h/j/k/l` | Navigate panes                  |
| `H/J/K/L` | Swap pane position              |
| `f`        | Toggle pane zoom (fullscreen)   |
| `d`        | Kill current pane               |
| `p`        | New pi agent pane (vertical split) |
| `t`        | New terminal pane (vertical split) |
| `Ctrl-a`   | Exit nav mode                   |
| `Esc`      | Exit nav mode                   |

The status bar shows a yellow **NAV** indicator when nav mode is active.

### Prefix (Ctrl-b, one-shot)

| Shortcut            | Action                           |
|---------------------|----------------------------------|
| `Ctrl-b \|`         | Split pane horizontally (left/right) |
| `Ctrl-b -`          | Split pane vertically (top/bottom)   |
| `Ctrl-b g`          | New window: lazygit              |
| `Ctrl-b e`          | New window: nvim                 |
| `Ctrl-b c`          | New window: shell                |
| `Ctrl-b d`          | Detach session                   |
| `Ctrl-b Ctrl-s`     | Save session (tmux-resurrect)    |
| `Ctrl-b Ctrl-r`     | Restore session (tmux-resurrect) |

### Window switching (no prefix)

| Shortcut      | Action                      |
|---------------|-----------------------------|
| `Option+1-9`  | Switch to window by number  |

### lf keybindings

| Key | Action |
|-----|--------|
| `f` | Fuzzy jump to any file (fzf) |
| `C` | Search code by name pattern (`*Foo*`) across `.scala/.rs/.hs/.c/.h` |
| `H` | Go to home directory |
| `D` | Delete |
| `E` | Extract archive |
| `B` | Bulk rename |
| `r` | Reload |
| `.` | Toggle hidden files |
| `s` | Open shell |

## Persistence

- tmux sessions survive terminal close — reopen with `kdev dev <name>` or `kdev launch <name>`
- Each terminal window gets its own session; closing and re-running kdev creates a new one
- tmux-resurrect saves/restores sessions across tmux server restarts:
  - `Ctrl-b Ctrl-s` to save
  - `Ctrl-b Ctrl-r` to restore

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

## Pi Extensions

`kdev setup` installs pi extensions for enhanced code search:

| Extension | Source | What |
|-----------|--------|------|
| ck-pi-extension | local (`extensions/`) | Semantic + hybrid code search via ck embeddings |
| @ff-labs/pi-fff | npm (pi package) | Fuzzy file/content search, frecency-ranked, git-aware |

fff runs in **override mode** (`PI_FFF_MODE=override`) — it replaces pi's
built-in `grep` and `find` tools entirely with faster, smarter versions.
The env var is auto-added to your shell rc file (zsh/bash/fish/POSIX).

These are complementary:
- **fff** → fuzzy/regex file and content search ("find `retryCount`")
- **ck** → concept-level semantic search ("find retry logic", "error handling")

## Self-test

```bash
kdev --test
```

108 tests covering git helpers, config generation (tmux + Alacritty + nav mode),
dev/launch/list/delete/here commands (including broken worktree repair), tmux
layout and session isolation (browser-tab model, max-one-window constraint),
setup plan (including skills, extensions, and PI_FFF_MODE install), and meta flags.

## License

GPL v3 — see [LICENSE](LICENSE).
