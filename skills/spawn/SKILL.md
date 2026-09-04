---
name: spawn
description: "Spawn a pi subagent non-interactively to do actual file-writing work and wait for it to finish, rather than polling. Use when you need to delegate an implementation task to a subagent that runs to completion in the background. Triggers: spawn a subagent, delegate to a subagent, have a subagent do this, fan out work to a subagent, run a subagent in the background."
license: MIT
compatibility: opencode
metadata:
  category: agent-orchestration
---

# spawn — Delegate to a non-interactive pi subagent

## What it does

`spawn.sh` runs `pi -p --approve "<prompt>"` in the background, captures its
stdout+stderr to a log file, and blocks with `wait` on the backgrounded
process — never a sleep-polling loop. When the subagent finishes, it prints
the full log, then a one-line summary (log path, exit code, duration), and
exits with the subagent's own exit code.

Use this instead of manually backgrounding `pi -p` yourself and polling for
completion.

## Usage

```bash
skills/spawn/spawn.sh "implement X in file Y and run the tests"
skills/spawn/spawn.sh --no-approve "refactor Z, but ask before editing"
```

- Default is auto-approve (`--approve`) — the subagent edits files without
  gating on approval.
- Pass `--no-approve` (or `-na`) to gate edits behind approval instead —
  use this only when the caller explicitly wants edits reviewed/approved.
- The prompt is a single argument — quote it.

## Fanning out multiple subagents

Each call to `spawn.sh` is one-at-a-time/blocking by design. To run several
subagents in parallel, background multiple `spawn.sh` invocations yourself
and `wait` on all of them:

```bash
skills/spawn/spawn.sh "task A" > /tmp/out-a.txt &
pid_a=$!
skills/spawn/spawn.sh "task B" > /tmp/out-b.txt &
pid_b=$!
wait "$pid_a" "$pid_b"
```

## Log locations

- Inside a kdev worktree (cwd under some repo's `.worktrees/<name>/`):
  logs go to `.spawn-logs/` inside that worktree. `.spawn-logs/` is added
  to the worktree repo's `.gitignore` automatically if missing.
- Outside a worktree (e.g. the repo's default branch, `kdev here`
  scenario, or no git repo at all): logs go to `/tmp/<repo-name>/`
  (or `/tmp/spawn-logs` if not in a git repo).

Every invocation gets a unique log filename (timestamp + random suffix) —
previous runs are never overwritten.

## Do / Don't

**Do:**
- Quote the prompt as a single argument
- Use `--no-approve` when the user explicitly wants edits gated
- Background multiple `spawn.sh` calls yourself to parallelize — don't
  expect `spawn.sh` to parallelize for you

**Don't:**
- Poll a log file in a loop waiting for completion — `spawn.sh` already
  blocks correctly via `wait`
- Assume `spawn.sh` returns before the subagent finishes — it always
  blocks until done
