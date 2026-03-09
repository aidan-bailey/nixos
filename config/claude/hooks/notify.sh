#!/usr/bin/env bash
# Claude Code notification hook
# Sends desktop notifications via notify-send and optional push via ntfy

set -euo pipefail

# Read hook event JSON from stdin
input=$(cat)
event=$(echo "$input" | jq -r '.hook_event_name // empty')
message=$(echo "$input" | jq -r '.message // empty')
session=$(echo "$input" | jq -r '.session_id // "claude"')

# Skip if no event
[ -z "$event" ] && exit 0

# Set urgency and title based on event type
case "$event" in
  Stop)
    urgency="critical"
    title="Claude Code — Task Complete"
    ;;
  Notification)
    urgency="normal"
    title="Claude Code — Notification"
    ;;
  *)
    urgency="low"
    title="Claude Code — $event"
    ;;
esac

# Truncate long messages for notification display
display_msg="${message:0:200}"

# Desktop notification via notify-send (swaync)
if command -v notify-send &>/dev/null; then
  notify-send -u "$urgency" -a "Claude Code" "$title" "$display_msg"
fi

# Push notification via ntfy (if topic is configured)
if [ -n "${NTFY_TOPIC:-}" ]; then
  priority="default"
  [ "$urgency" = "critical" ] && priority="high"

  curl -sf \
    -H "Title: $title" \
    -H "Priority: $priority" \
    -H "Tags: robot" \
    -d "$display_msg" \
    "https://ntfy.sh/$NTFY_TOPIC" &>/dev/null &
fi
