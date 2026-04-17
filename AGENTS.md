# kdev — Agent Instructions

## Project

Single-file bash script (`kdev`) that sets up a keyboard-driven
terminal dev environment on macOS using Alacritty + tmux + Neovim + lazygit.
Manages parallel git worktrees with tmux sessions. Each worktree gets a
3-pane layout (pi coding agent, lazygit, lf). tmux uses two modes:
`Ctrl-a` toggles persistent nav mode (vim hjkl), `Ctrl-b` is one-shot prefix
for structural commands.

Also in the repo: `zproj` (upstream fork, do not modify), `skills/`,
`rules/`, `global-agents.md`, `README.md`.

## Build & Test

```bash
kdev --test       # full test suite — MUST pass before any commit
kdev --version    # current version
kdev --help       # all subcommands
```

Before every commit:
1. Bump `readonly VERSION=` — patch (x.y.Z) for fixes, minor (x.Y.0) for features
2. Run `kdev --test` — done when output says `All N tests passed (0 skipped)`
3. Update `README.md` to reflect any user-facing changes

## Code Conventions

- Single file `kdev`. Never create additional source files.
- Subcommands: `cmd_<name>`. Helpers: `_<name>`. Usage: `usage_<name>`.
- `die "msg"` for fatal errors (exits 1). `_err "msg"` + `return 1` when caller needs cleanup.
- `warn`, `info` (green checkmark), `dim` for output.
- `set -euo pipefail` — quote all expansions, use `"${var:-}"` for optionals.
- `((count++)) || true` to protect arithmetic from `set -e`.
- `local` for all function variables; declare loop variables before the loop.

## Architecture (top to bottom)

1. **Constants** — `VERSION`, `WORKTREES_DIR`, color vars
2. **Helpers** — `die`, `_err`, `warn`, `info`, `dim`, `step`
3. **Git helpers** — `_find_repo_root`, `_git_default_branch`, `_git_is_dirty`, `_ensure_gitignore`
4. **tmux helpers** — `_tmux_session_name`, `_tmux_attach_or_switch`
5. **Config generators** — `_tmux_conf_content`, `_alacritty_conf_content`
6. **Setup functions** — `_check_brew`, `_install_brew_formula`, `_install_brew_cask`, `_install_pi_agent`, `_write_tmux_conf`, `_write_alacritty_conf`, `_install_lf_config`, `_install_tmux_resurrect`, `_install_skills`, `_install_global_agents_md`
7. **Subcommand: setup** — `cmd_setup`
8. **Layout** — `_setup_dev_layout` (3-pane tmux layout)
9. **Session launcher** — `_launch_session` (shared by dev and launch)
10. **Subcommands** — `cmd_dev`, `cmd_launch`, `cmd_list`, `cmd_delete`
11. **Usage functions** — `usage_main`, `usage_dev`, `usage_launch`, `usage_list`, `usage_delete`, `usage_setup`
12. **Self-test** — `cmd_test()`
13. **Main dispatch** — `main()` case statement

## Tests

Every feature, behaviour change, or bug fix requires tests. No exceptions.

Helpers: `_t_check "desc" <cmd>` (pass if exit 0), `_t_grep "desc" <pattern> <cmd>` (pass if output matches), `_t_pass`, `_t_fail`, `_t_skip`, `_section "XX — desc"`.

Test section prefixes:

| Prefix | Tests |
|--------|-------|
| G | Git helpers (_find_repo_root, _git_is_dirty, _tmux_session_name, _ensure_gitignore, _git_default_branch) |
| C | Config content (tmux.conf, alacritty keybindings) |
| D | Dev command (worktree creation, branch, --from, validation) |
| L | List command |
| X | Delete command (clean, dirty, --force) |
| T | tmux layout (session, panes, windows) — gated on `command -v tmux` |
| S | Setup (--plan output) |
| V | Meta (--version, --help, semver, unknown options) |

To add a test: find the prefix, use the next number (e.g. `D9` exists, add `D10`), place adjacent to related tests.

## Common Tasks

### Adding a subcommand

1. Add `cmd_<name>()` in the subcommands section
2. Add `usage_<name>()` in the usage section
3. Add case in `main()` dispatch
4. Add to `usage_main()` listing
5. Add tests with a new prefix
6. Run `kdev --test`

### Adding a tool to setup

1. Add install call in `cmd_setup()` (both real and `--plan` branches)
2. Add check in the plan tools array
3. Add test in S section
4. Run `kdev --test`

### Fixing a bug

1. Reproduce the bug
2. Write tests that fail — confirm with `kdev --test`
3. Fix the bug
4. Run `kdev --test` — all tests must pass

### Shipping a change

1. Bump `VERSION` if not already bumped
2. Run `kdev --test`, fix failures
3. Update `README.md` for user-facing changes
4. Verify `AGENTS.md` is factually correct
5. `git add && git commit` with clear message

## Do Not

- Create additional source files
- Commit with failing or skipped tests
- Use `die` inside a function that needs cleanup — use `_err` + `return 1`
- Add comments restating what code does — only explain *why*
- Modify `zproj`, `skills/`, or `rules/` unless asked

## When Stuck

- `kdev setup --plan` to check what's installed
- `kdev --test` to see failures — tests are the best docs for expected behaviour
- Ask the user before architectural changes or adding dependencies
