#!/usr/bin/env bash
# Claude Code notification hook — interactive desktop + push notifications
# Sends notifications with action buttons via notify-send, sound via swaync,
# and optional push via ntfy.

set -euo pipefail

# Read hook event JSON from stdin (guard against malformed input)
input=$(cat)
event=$(echo "$input" | jq -r '.hook_event_name // empty' 2>/dev/null) || exit 0
message=$(echo "$input" | jq -r '.message // empty' 2>/dev/null) || true
session=$(echo "$input" | jq -r '.session_id // "claude"' 2>/dev/null) || session="claude"

[ -z "$event" ] && exit 0

# ── Per-event configuration ──────────────────────────────────────────────────
case "$event" in
  Stop)
    urgency="critical"
    title="Claude Code — Task Complete"
    icon="dialog-information"
    expire_ms=0 # persistent until dismissed
    ntfy_priority="high"
    ntfy_tags="white_check_mark,robot"
    show_actions=1
    ;;
  Notification)
    urgency="normal"
    title="Claude Code — Notification"
    icon="dialog-information"
    expire_ms=15000
    ntfy_priority="default"
    ntfy_tags="robot"
    show_actions=1
    ;;
  SubagentStop)
    urgency="low"
    title="Claude Code — Subagent Done"
    icon="emblem-system"
    expire_ms=5000
    ntfy_priority="low"
    ntfy_tags="gear,robot"
    show_actions=0
    ;;
  *)
    urgency="low"
    title="Claude Code — $event"
    icon="dialog-information"
    expire_ms=5000
    ntfy_priority="min"
    ntfy_tags="robot"
    show_actions=0
    ;;
esac

display_msg="${message:0:200}"

# ── Desktop notification with action buttons ─────────────────────────────────
# notify-send --action implies --wait (blocks until user acts or notification
# expires). We run in a background subshell so the hook returns immediately.
# When the user clicks "Focus Terminal", we call claude-focus to raise the
# correct Sway window.
if command -v notify-send &>/dev/null; then
  (
    args=(
      --urgency="$urgency"
      --app-name="Claude Code"
      --icon="$icon"
      --expire-time="$expire_ms"
    )

    if [ "$show_actions" = "1" ]; then
      args+=(--action="focus=Focus Terminal")
    fi

    action=$(notify-send "${args[@]}" "$title" "$display_msg" 2>/dev/null || true)

    if [ "$action" = "focus" ] && command -v claude-focus &>/dev/null; then
      claude-focus "$session" 2>/dev/null || true
    fi
  ) &>/dev/null &
fi

# ── Push notification via ntfy ───────────────────────────────────────────────
if [ -n "${NTFY_TOPIC:-}" ]; then
  ntfy_actions="view, Open Topic, https://ntfy.sh/${NTFY_TOPIC}"

  curl -sf \
    -H "Title: $title" \
    -H "Priority: $ntfy_priority" \
    -H "Tags: $ntfy_tags" \
    -H "Actions: $ntfy_actions" \
    -d "$display_msg" \
    "https://ntfy.sh/$NTFY_TOPIC" &>/dev/null &
fi
