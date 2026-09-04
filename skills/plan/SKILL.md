---
name: plan
description: "Create and maintain a high-level plan for the current branch. One plan per branch, stored outside git in worktree mode, at repo root (never staged) on a normal branch. Triggers: plan, make plan, update plan, show plan, check off, mark done."
license: MIT
compatibility: opencode
metadata:
  category: planning
---

# plan — Branch Plan Management

## Overview

Each branch gets one plan. A plan is a **high-level** markdown checklist describing
*what* has to be achieved and *why* — never a file-by-file edit script.

## Level of Abstraction

A plan describes outcomes and behaviour, not code mechanics.

**Never include:**
- Which files to create or edit, or paths/line numbers
- Function, class, or variable names to add or rename
- Code snippets or diffs
- Lists of unit tests to write, test names, or assertions
- Which test file a test belongs in

**Do include:**
- The goal and the constraints/invariants that must hold
- Behavioural outcomes per step ("retries stop on non-retryable errors")
- Sequencing and dependencies between steps
- Risks, open questions, decisions to make
- How the change will be *verified at a system level* — integration and
  e2e test setup (harness, fixtures, environments, seed data, CI wiring) is in
  scope; enumerating individual unit tests is not

If you catch yourself naming a file or a test case, raise the abstraction level.

## Storage

First determine the mode:

```bash
git rev-parse --git-dir            # a worktree has a gitdir like <repo>/.git/worktrees/<name>
git rev-parse --show-toplevel
```

You are in **worktree mode** if the current checkout is a linked git worktree
(commonly under `<repo>/.worktrees/<branch>`), otherwise **branch mode**.

### Worktree mode

Unchanged behaviour — plan lives outside the worktree:

```bash
branch_name="$(basename "$PWD")"
plan_dir="../${branch_name}.plan"
plan_file="${plan_dir}/plan.md"
```

This resolves to `<repo>/.worktrees/<branch>.plan/plan.md`, a sibling of the
worktree inside the already-gitignored `.worktrees/` folder. Create the
directory if missing.

### Branch mode (normal checkout)

Store the plan at the repository root:

```bash
repo_root="$(git rev-parse --show-toplevel)"
branch_name="$(git rev-parse --abbrev-ref HEAD)"
plan_file="${repo_root}/$(basename "$branch_name").plan.md"
```

Rules for branch mode:
- **Never** `git add`, `git stage`, or `git commit` the plan file.
- **Never** add it to `.gitignore` or `.git/info/exclude` unless the user asks.
- If you run `git add -A` style commands, exclude the plan file; prefer explicit
  paths when staging.
- If the user asks to commit work while a plan file exists, stage only the real
  changes and mention the plan file was left untracked on purpose.

## Detail Modes

Default: **full**. Switch with `/plan lite`, `/plan full`, `/plan ultra`.

Modes control how much detail per step. All modes stay high-level.

| Mode | Step detail |
|---|---|
| **lite** | One-liner outcome per step. No substeps. |
| **full** | One or two notes under each step: intent, constraint, or dependency. |
| **ultra** | Notes plus risks/open questions and acceptance criteria per step. |

## Plan Structure

```markdown
# <Plan Name>

**Goal:** <one-line summary of what this plan achieves>

**Status:** draft | in-progress | done | blocked

## Steps

- [ ] Step 1
- [ ] Step 2
- [ ] Step 3
```

### lite example

```markdown
# Retry failed API requests

**Goal:** Transient upstream failures stop surfacing to callers

**Status:** in-progress

## Steps

- [x] Make retry behaviour configurable
- [ ] Retry transient failures with exponential backoff
- [ ] Stand up an integration environment with a flaky endpoint
- [ ] Document the new behaviour
```

### full example

```markdown
# Retry failed API requests

**Goal:** Transient upstream failures stop surfacing to callers

**Status:** in-progress

## Steps

- [x] Make retry behaviour configurable
  - Opt-out must be possible; defaults apply when unconfigured
- [ ] Retry transient failures with exponential backoff
  - Only transient failures retry; client errors surface immediately
  - Backoff must be bounded and jittered
- [ ] Stand up an integration environment with a flaky endpoint
  - Controllable failure injection, deterministic timing in CI
- [ ] Document the new behaviour
  - Cover defaults, opt-out, and which failures retry
```

### ultra example

```markdown
# Retry failed API requests

**Goal:** Transient upstream failures stop surfacing to callers

**Status:** in-progress

## Steps

- [x] Make retry behaviour configurable
  - Existing callers keep working with no changes
  - ⚠️ Config surface is public — decide names once, they are hard to change
  - ✅ Defaults applied when unconfigured; retries can be disabled

- [ ] Retry transient failures with exponential backoff
  - Transient = rate limiting, upstream server failure, network interruption
  - Non-transient client errors must never retry
  - Backoff bounded by a ceiling and jittered to avoid synchronised retries
  - Cancellation must interrupt a pending retry
  - ⚠️ Retrying non-idempotent writes risks duplicate side effects — decide
    whether callers must opt in for those
  - ✅ Transient failures recover silently; client errors and cancellation are
    immediate

- [ ] Stand up an integration environment with a flaky endpoint
  - Failure injection controllable per scenario
  - Timing made deterministic so CI is not flaky
  - Wire the suite into CI as a required check
  - ⚠️ Real-time waits make the suite slow — plan for time control
  - ✅ End-to-end recovery is observable in CI, reliably

- [ ] Document the new behaviour
  - Defaults, opt-out, retryable vs non-retryable failures, idempotency caveat
  - ✅ A caller can predict retry behaviour from the docs alone
```

## Behavior Rules

1. **Detect mode first.** Worktree → `../<branch>.plan/plan.md`; branch →
   `<repo_root>/<branch>.plan.md`, never staged or committed.
2. **Stay high-level.** No file paths, no symbol names, no unit-test lists.
3. **One plan per branch.** Never create a second plan file. Update the existing one.
4. **Check off steps** by changing `- [ ]` to `- [x]` as work completes.
5. **Update status** field as plan progresses.
6. **Read plan first** before any update — never overwrite blindly.
7. **When user says "plan"** without context — show the current plan if it exists, or ask what to plan.
8. **When user says "update plan"** — read the current plan, check off completed steps, add new steps if needed.
9. **Persist mode** across the session. Default is full. Switch only when user says `/plan lite|full|ultra`.
10. **Create plan** only when user asks to make/create/write a plan. Do not auto-create.
