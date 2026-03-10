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

# Launch the popup terminal attached to the given tmux session, wait for it to
# appear in Sway, then surface it from the scratchpad.
launch_popup() {
  local target_session="$1"

  alacritty --class "$APP_ID" --title "Claude Popup" \
    -e tmux attach-session -t "$target_session" &>/dev/null &
  disown

  # Wait for window to appear (up to 2s), then surface it
  local i con_id
  for i in $(seq 1 20); do
    sleep 0.1
    con_id=$(popup_con_id)
    if [ -n "$con_id" ]; then
      swaymsg "[app_id=$APP_ID] scratchpad show" &>/dev/null || true
      swaymsg "[app_id=$APP_ID] focus" &>/dev/null || true
      return
    fi
  done
}

# ── show ─────────────────────────────────────────────────────────────────────

cmd_show() {
  local tmux_session="${1:-}"
  [ -z "$tmux_session" ] && exit 0

  # Guard: tmux session must exist
  tmux has-session -t "$tmux_session" 2>/dev/null || exit 0

  local active_session=""
  [ -f "$STATE_FILE" ] && active_session=$(cat "$STATE_FILE")

  # Record active session
  printf '%s' "$tmux_session" > "$STATE_FILE"

  local con_id
  con_id=$(popup_con_id)

  if [ -n "$con_id" ] && [ "$tmux_session" = "$active_session" ]; then
    # Popup exists and already shows the right session — just surface it.
    swaymsg "[app_id=$APP_ID] move scratchpad" &>/dev/null || true
    swaymsg "[app_id=$APP_ID] scratchpad show" &>/dev/null || true
    swaymsg "[app_id=$APP_ID] focus" &>/dev/null || true
  else
    # Either no popup exists, or it shows a different session.
    # Kill any stale popup and spawn a fresh one attached to the target session.
    # (tmux switch-client can't reliably target the popup's client from a
    # backgrounded hook process, so kill+respawn is the safe approach.)
    if [ -n "$con_id" ]; then
      swaymsg "[app_id=$APP_ID] kill" &>/dev/null || true
      sleep 0.15  # let Sway + Alacritty clean up
    fi
    launch_popup "$tmux_session"
  fi
}

# ── dismiss ──────────────────────────────────────────────────────────────────

cmd_dismiss() {
  local tmux_session="${1:-}"

  # Only dismiss if the stopping session matches the active popup session.
  # This prevents session A's Stop from hiding a popup showing session B.
  if [ -n "$tmux_session" ] && [ -f "$STATE_FILE" ]; then
    local active_session
    active_session=$(cat "$STATE_FILE")
    if [ "$tmux_session" != "$active_session" ]; then
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
