#!/usr/bin/env bash
# Claude popup terminal — Sway scratchpad orchestrator.
# Usage:
#   claude-popup show <session-id>   — surface popup attached to matching tmux session
#   claude-popup dismiss             — hide popup back to scratchpad

set -euo pipefail

VERB="${1:-}"
# Tracks which tmux session is currently in the popup (consumed by dismiss)
STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/claude-popup-session"
APP_ID="claude-popup"

# ── Helpers ──────────────────────────────────────────────────────────────────

# Find the Sway container ID for the popup window (empty string if not found)
popup_con_id() {
  swaymsg -t get_tree 2>/dev/null \
    | jq -r --arg appid "$APP_ID" '.. | objects | select(.app_id? == $appid) | .id' 2>/dev/null \
    | head -1
}

# Resolve a Claude session_id to the best-matching claudesquad_ tmux session.
# Falls back to the first claudesquad_ session if no fragment match.
resolve_tmux_session() {
  local sid="$1"
  local match

  # Try exact substring match first
  match=$(tmux list-sessions -F "#{session_name}" 2>/dev/null \
    | grep "^claudesquad_" \
    | grep -Fi "$sid" \
    | head -1) || true

  if [ -n "$match" ]; then
    echo "$match"
    return
  fi

  # Fallback: first claudesquad_ session
  tmux list-sessions -F "#{session_name}" 2>/dev/null \
    | grep "^claudesquad_" \
    | head -1 || true
}

# ── show ─────────────────────────────────────────────────────────────────────

cmd_show() {
  local session_id="${1:-}"
  [ -z "$session_id" ] && exit 0

  local tmux_session
  tmux_session=$(resolve_tmux_session "$session_id")
  [ -z "$tmux_session" ] && exit 0

  # Guard: tmux session must exist
  tmux has-session -t "$tmux_session" 2>/dev/null || exit 0

  # Record active session
  printf '%s' "$tmux_session" > "$STATE_FILE"

  local con_id
  con_id=$(popup_con_id)

  if [ -n "$con_id" ]; then
    # Window exists — deterministically surface it (move to scratchpad first to
    # avoid the toggle footgun where a second 'scratchpad show' hides it)
    swaymsg "[app_id=$APP_ID] move scratchpad" &>/dev/null || true
    swaymsg "[app_id=$APP_ID] scratchpad show" &>/dev/null || true
    swaymsg "[app_id=$APP_ID] focus" &>/dev/null || true
    tmux switch-client -t "$tmux_session" 2>/dev/null || true
  else
    # Launch new popup window — for_window rule will move it to scratchpad
    alacritty --class "$APP_ID" --title "Claude Popup" \
      -e tmux attach-session -t "$tmux_session" &>/dev/null &
    disown

    # Wait for window to appear (up to 2s), then surface it
    local i
    for i in $(seq 1 20); do
      sleep 0.1
      con_id=$(popup_con_id)
      if [ -n "$con_id" ]; then
        swaymsg "[app_id=$APP_ID] scratchpad show" &>/dev/null || true
        swaymsg "[app_id=$APP_ID] focus" &>/dev/null || true
        break
      fi
    done
  fi
}

# ── dismiss ──────────────────────────────────────────────────────────────────

cmd_dismiss() {
  local session_id="${1:-}"

  # If a session_id was provided, only dismiss if it matches the active popup session.
  # This prevents session A's Stop from hiding a popup showing session B.
  if [ -n "$session_id" ] && [ -f "$STATE_FILE" ]; then
    local active_session
    active_session=$(cat "$STATE_FILE")
    local stopping_session
    stopping_session=$(resolve_tmux_session "$session_id")
    if [ -n "$stopping_session" ] && [ "$stopping_session" != "$active_session" ]; then
      return 0
    fi
  fi

  rm -f "$STATE_FILE"

  local con_id
  con_id=$(popup_con_id)
  [ -z "$con_id" ] && return 0

  # Always-hide (not toggle) — safe regardless of current visibility
  swaymsg "[app_id=$APP_ID] move scratchpad" &>/dev/null || true
}

# ── Dispatch ─────────────────────────────────────────────────────────────────

case "$VERB" in
  show)    cmd_show "${2:-}" ;;
  dismiss) cmd_dismiss "${2:-}" ;;
  *)       echo "Usage: claude-popup show <session-id> | claude-popup dismiss" >&2; exit 1 ;;
esac
