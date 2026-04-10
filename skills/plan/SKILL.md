---
name: plan
description: "Create and maintain a plan for the current kdev worktree branch. One plan per branch, stored outside the worktree to avoid git pollution. Triggers: plan, make plan, update plan, show plan, check off, mark done."
license: MIT
compatibility: opencode
metadata:
  category: planning
---

# plan — Branch Plan Management

## Overview

Each kdev worktree branch gets one plan. The plan is a markdown checklist stored outside the git worktree so it never pollutes `git status`.

## Storage

Plan location: `../<branch>.plan/plan.md` relative to the worktree root (CWD).

This resolves to `<repo>/.worktrees/<branch>.plan/plan.md` — a sibling of the worktree directory, inside the already-gitignored `.worktrees/` folder.

To find the path:

```bash
branch_name="$(basename "$PWD")"
plan_dir="../${branch_name}.plan"
plan_file="${plan_dir}/plan.md"
```

Create the directory if it doesn't exist before writing.

## Detail Modes

Default: **full**. Switch with `/plan lite`, `/plan full`, `/plan ultra`.

Modes control how much detail you write per step. The plan structure is the same across all modes — only step granularity changes.

| Mode | Step detail |
|---|---|
| **lite** | One-liner per step. No substeps, no explanation. |
| **full** | Brief context or "how" note under each step. Substeps where non-obvious. |
| **ultra** | Substeps, implementation approach, risks/gotchas, and acceptance criteria per step. |

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
# Add retry logic to API client

**Goal:** Retry failed HTTP requests with exponential backoff

**Status:** in-progress

## Steps

- [x] Add retry config options
- [ ] Implement backoff loop
- [ ] Add tests
- [ ] Update README
```

### full example

```markdown
# Add retry logic to API client

**Goal:** Retry failed HTTP requests with exponential backoff

**Status:** in-progress

## Steps

- [x] Add retry config options
  - maxRetries, baseDelay, maxDelay in ClientConfig
- [ ] Implement backoff loop
  - Wrap fetch call, retry on 5xx and network errors
  - Use exponential backoff: baseDelay * 2^attempt, capped at maxDelay
- [ ] Add tests
  - Mock server returning 503 then 200
  - Verify delay timing within tolerance
- [ ] Update README
  - Document new config options with examples
```

### ultra example

```markdown
# Add retry logic to API client

**Goal:** Retry failed HTTP requests with exponential backoff

**Status:** in-progress

## Steps

- [x] Add retry config options
  - Add maxRetries (default 3), baseDelay (default 1000ms), maxDelay (default 30000ms) to ClientConfig
  - Validate: maxRetries >= 0, baseDelay > 0, maxDelay >= baseDelay
  - ⚠️ Ensure backwards-compatible — all fields optional with defaults
  - ✅ Config accepted, defaults applied when omitted

- [ ] Implement backoff loop
  - Wrap existing fetch in retry loop inside `_request()` method
  - Retry on: HTTP 429, 5xx, network errors (ECONNRESET, ETIMEDOUT)
  - Do NOT retry: 4xx (except 429), abort signals
  - Backoff formula: min(baseDelay * 2^attempt + jitter, maxDelay)
  - Add jitter (0-10% of delay) to prevent thundering herd
  - ⚠️ Risk: retry on POST may cause duplicate side effects — add Idempotency-Key header support
  - ✅ Retries work for GET/POST, respects abort signal, jitter applied

- [ ] Add tests
  - Unit: mock server returning 503×2 then 200 — verify 3 requests made
  - Unit: mock 400 — verify no retry
  - Unit: verify delay between attempts within 20% tolerance
  - Unit: abort signal cancels pending retry
  - Integration: real server with /flaky endpoint
  - ⚠️ Timing tests flaky in CI — use fake timers
  - ✅ All retry scenarios covered, no flaky tests

- [ ] Update README
  - Add "Retry Configuration" section after "Basic Usage"
  - Show minimal config, full config, and disable-retry examples
  - Document which errors trigger retry
  - Add note about idempotency for POST requests
  - ✅ README documents all new config options with copy-paste examples
```

## Behavior Rules

1. **One plan per branch.** Never create a second plan file. Update the existing one.
2. **Check off steps** by changing `- [ ]` to `- [x]` as work completes.
3. **Update status** field as plan progresses.
4. **Read plan first** before any update — never overwrite blindly.
5. **When user says "plan"** without context — show the current plan if it exists, or ask what to plan.
6. **When user says "update plan"** — read the current plan, check off completed steps, add new steps if needed.
7. **Persist mode** across the session. Default is full. Switch only when user says `/plan lite|full|ultra`.
8. **Create plan** only when user asks to make/create/write a plan. Do not auto-create.
