---
name: spawn
description: "Spawn a pi subagent non-interactively to do actual file-writing work and wait for it to finish, rather than polling, optionally choosing which model the subagent runs on. Use when you need to delegate an implementation task to a subagent that runs to completion in the background, or to run a task on a specific/cheaper/stronger model. Triggers: spawn a subagent, delegate to a subagent, have a subagent do this, fan out work to a subagent, run a subagent in the background, spawn with model, use sonnet/opus for this subagent."
license: MIT
compatibility: opencode
metadata:
  category: agent-orchestration
---

# spawn — Delegate to a non-interactive pi subagent

## What it does

`spawn.sh` runs `pi -p --approve [--model <pattern>] "<prompt>"` in the
background, captures its
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
skills/spawn/spawn.sh --model opus "do the hard refactor in src/"
skills/spawn/spawn.sh -m anthropic/claude-sonnet-4-5 "add tests for parser"
```

- Default is auto-approve (`--approve`) — the subagent edits files without
  gating on approval.
- Pass `--no-approve` (or `-na`) to gate edits behind approval instead —
  use this only when the caller explicitly wants edits reviewed/approved.
- The prompt is a single argument — quote it.

## Choosing the model

`--model <pattern>` (or `-m`, or `--model=<pattern>`) is passed straight
through to `pi --model`, so it accepts anything pi accepts:

| Form | Example |
|------|---------|
| Fuzzy pattern | `--model sonnet`, `--model opus` |
| `provider/id` | `--model anthropic/claude-sonnet-4-5` |
| With thinking level | `--model "openai/gpt-5:high"` |

- Omit the flag to use pi's own default model.
- `SPAWN_MODEL` is used as the default when set; an explicit `--model`
  always wins.
- The chosen model is echoed in the summary line as `model=<value>`
  (`model=default` when none was chosen).

Pick a cheap/fast model for mechanical work (renames, boilerplate, doc
edits) and a stronger one for design-heavy refactors. When fanning out,
different subagents can run on different models.

## Fanning out multiple subagents

Each call to `spawn.sh` is one-at-a-time/blocking by design. To run several
subagents in parallel, background multiple `spawn.sh` invocations yourself
and `wait` on all of them:

```bash
skills/spawn/spawn.sh -m sonnet "task A" > /tmp/out-a.txt &
pid_a=$!
skills/spawn/spawn.sh -m opus "task B" > /tmp/out-b.txt &
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
- Use `--model` when the task warrants a specific model tier — and honour
  the model the user names
- Background multiple `spawn.sh` calls yourself to parallelize — don't
  expect `spawn.sh` to parallelize for you

**Don't:**
- Poll a log file in a loop waiting for completion — `spawn.sh` already
  blocks correctly via `wait`
- Assume `spawn.sh` returns before the subagent finishes — it always
  blocks until done
- Invent model names — pass a pi-valid pattern, or omit `--model`
