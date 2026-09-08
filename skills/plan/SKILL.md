---
name: plan
description: "Create and maintain topic-named high-level plans for the project, each stored as its own checklist file in the repo root. Triggers: plan, make plan, update plan, show plan, check off, mark done."
license: MIT
compatibility: opencode
metadata:
  category: planning
---

# plan — Project Plan Management

## Overview

A project can have any number of plans, each about a distinct topic or effort
(a new module, a refactor, a migration). A plan is a **high-level** markdown
checklist describing *what* has to be achieved and *why* — never a
file-by-file edit script. It is committed to the repo like any other file.
When a plan is finished, the user deletes it — the agent never deletes it
automatically.

## Level of Abstraction

There is only one detail level. A plan describes outcomes and behaviour, not code
mechanics — it can be as detailed as needed conceptually, but never points at
implementation locations.

**Never include:**
- Which files to create or edit, or paths/line numbers
- Function, class, or variable names to add or rename
- Code snippets or diffs
- Lists of unit tests to write, test names, or assertions
- Which test file a test belongs in

**Do include:**
- The goal and the constraints/invariants that must hold
- Behavioural or conceptual outcomes per step ("remodel the ADTs so state is a
  closed sum type instead of optional fields")
- Sequencing and dependencies between steps
- Risks, open questions, decisions to make
- How the change will be *verified at a system level* — integration and
  e2e test setup (harness, fixtures, environments, seed data, CI wiring) is in
  scope; enumerating individual unit tests is not

If you catch yourself naming a file, symbol, or test case, raise the abstraction level.

## Storage

Plan location: `PLAN_<TOPIC>.md` in the repository root, where `<TOPIC>` is an
uppercase, underscore-separated short name describing what the plan is about
(e.g. `PLAN_NEW_HTTP_MODULE.md`, `PLAN_REFACTOR_AUTH.md`).

```bash
repo_root="$(git rev-parse --show-toplevel)"
plan_file="${repo_root}/PLAN_<TOPIC>.md"
```

Rules:
- Derive `<TOPIC>` from the goal of the plan, kept short (2-5 words).
- Never create two plan files for the same topic — update the existing one instead.
- Different topics get different files; do not merge unrelated efforts into one plan file.
- The plan file is a normal tracked file — commit it like any other change.
- Never delete it. Only the user deletes it, once that plan is finished.

## Plan Structure

```markdown
# <Plan Name>

**Goal:** <one-line summary of what this plan achieves>

**Status:** draft | in-progress | done | blocked

## Steps

- [ ] Step 1
  - conceptual context: intent, constraint, or dependency
- [ ] Step 2
- [ ] Step 3
```

### example

`PLAN_RETRY_HTTP_CLIENT.md`:

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
  - ⚠️ Retrying non-idempotent writes risks duplicate side effects — decide
    whether callers must opt in for those
- [ ] Stand up an integration environment with a flaky endpoint
  - Controllable failure injection, deterministic timing in CI
- [ ] Document the new behaviour
  - Cover defaults, opt-out, and which failures retry
  - ✅ A caller can predict retry behaviour from the docs alone
```

## Behavior Rules

1. **One plan file per topic, any number of topics.** Name each file `PLAN_<TOPIC>.md`. Never create a second file for the same topic — update the existing one.
2. **Stay high-level.** No file paths, no symbol names, no unit-test lists.
3. **Check off steps** by changing `- [ ]` to `- [x]` as work completes.
4. **Update status** field as plan progresses.
5. **Read plan first** before any update — never overwrite blindly.
6. **When user says "plan"** without a topic — if exactly one `PLAN_*.md` file exists, show it; if several exist, ask which topic; if none exist, ask what to plan.
7. **When user says "update plan"** — identify the topic (from context or by asking), read that plan file, check off completed steps, add new steps if needed.
8. **Create a plan** only when user asks to make/create/write a plan. Do not auto-create. Pick a topic name for the file based on the goal.
9. **Never delete a plan file.** Only the user deletes it, once that plan is finished.
