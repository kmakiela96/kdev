#!/usr/bin/env bash
# spawn.sh — run a pi subagent non-interactively, to completion, blocking.
#
# Usage:
#   spawn.sh [--no-approve] "<prompt text>"
#
# Runs `pi -p --approve "<prompt>"` (or --no-approve) in the background,
# captures stdout+stderr to a log file, and blocks on it with `wait` — never
# a sleep-polling loop. On completion prints the full log, then a one-line
# summary (log path, exit code, duration), and exits with the subagent's
# exit code.
#
# To fan out multiple subagents, call this script multiple times — each
# call is one-at-a-time/blocking by design. Background several invocations
# of spawn.sh yourself and `wait` on all of them to parallelize.
set -euo pipefail

_spawn_usage() {
  echo "Usage: $(basename "$0") [--no-approve] \"<prompt text>\"" >&2
  exit 1
}

# Determine the log directory:
#   - Inside a kdev worktree (toplevel path contains /.worktrees/<name>/):
#     write to <worktree>/.spawn-logs/, and make sure that dir is gitignored.
#   - Otherwise (repo default branch / `kdev here`, or not in a git repo at
#     all): write to /tmp/<repo-name>/.
_spawn_log_dir() {
  local toplevel repo_name

  if ! toplevel="$(git rev-parse --show-toplevel 2>/dev/null)"; then
    echo "/tmp/spawn-logs"
    return 0
  fi

  if [[ "$toplevel" == *"/.worktrees/"* ]]; then
    echo "$toplevel/.spawn-logs"
    return 0
  fi

  repo_name="$(basename "$toplevel")"
  echo "/tmp/$repo_name"
}

_spawn_main() {
  local approve_flag="--approve"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-approve|-na)
        approve_flag="--no-approve"
        shift
        ;;
      -h|--help)
        _spawn_usage
        ;;
      --)
        shift
        break
        ;;
      -*)
        echo "Unknown option: $1" >&2
        _spawn_usage
        ;;
      *)
        break
        ;;
    esac
  done

  if [[ $# -lt 1 ]]; then
    _spawn_usage
  fi

  local prompt="$1"

  local log_dir
  log_dir="$(_spawn_log_dir)"
  mkdir -p "$log_dir"

  # If we picked a worktree-local .spawn-logs dir, make sure it's gitignored.
  if [[ "$log_dir" == *"/.worktrees/"*"/.spawn-logs" ]]; then
    local worktree_root gitignore
    worktree_root="${log_dir%/.spawn-logs}"
    gitignore="$worktree_root/.gitignore"
    if [[ ! -f "$gitignore" ]] || ! grep -qxF ".spawn-logs/" "$gitignore" 2>/dev/null; then
      echo ".spawn-logs/" >> "$gitignore"
    fi
  fi

  local timestamp suffix log_file
  timestamp="$(date +%Y%m%d-%H%M%S)"
  # head -c6 closes the pipe early, causing tr to receive SIGPIPE (exit 141);
  # with pipefail that would abort the whole script under set -e, so guard it.
  suffix="$(LC_ALL=C tr -dc 'a-z0-9' </dev/urandom 2>/dev/null | head -c6 || true)"
  if [[ -z "$suffix" ]]; then
    suffix="$RANDOM"
  fi
  log_file="$log_dir/spawn-${timestamp}-${suffix}.log"

  local start_ts
  start_ts=$(date +%s)

  pi -p "$approve_flag" "$prompt" >"$log_file" 2>&1 &
  local pid=$!

  local exit_code=0
  wait "$pid" || exit_code=$?

  local end_ts duration
  end_ts=$(date +%s)
  duration=$((end_ts - start_ts))

  cat "$log_file"

  echo "spawn: log=$log_file exit=$exit_code duration=${duration}s"

  return "$exit_code"
}

# Only run when executed directly — allows the log-dir-selection logic to be
# unit tested by sourcing this file without invoking `pi`.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  _spawn_main "$@"
  exit $?
fi
