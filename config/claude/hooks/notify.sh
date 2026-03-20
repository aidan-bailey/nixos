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

# ── Load Nix-generated notification config ───────────────────────────────────
NOTIFY_CONF="${HOME}/.claude/hooks/notify.conf"
[ -f "$NOTIFY_CONF" ] && source "$NOTIFY_CONF"

# Defaults when config is missing (backwards compat)
: "${NOTIFY_DESKTOP:=1}"
: "${NOTIFY_PUSH:=1}"
: "${NOTIFY_POPUP:=1}"
: "${NOTIFY_EVENT_STOP:=1}"
: "${NOTIFY_EVENT_NOTIFICATION:=1}"

# Per-event gate
case "$event" in
  Stop)         [ "$NOTIFY_EVENT_STOP" = "1" ] || exit 0 ;;
  Notification) [ "$NOTIFY_EVENT_NOTIFICATION" = "1" ] || exit 0 ;;
esac

# ── Per-event configuration ──────────────────────────────────────────────────
case "$event" in
  Stop)
    urgency="critical"
    title="Claude Code — Task Complete"
    icon="dialog-information"
    expire_ms=15000
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
if [ "$NOTIFY_DESKTOP" = "1" ] && command -v notify-send &>/dev/null; then
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
      # Use the tmux session name (via $TMUX_PANE) so claude-focus can
      # reliably find the correct Sway window via PID tree walking.
      # Claude's session_id is a UUID that doesn't match anything.
      focus_target="$session"
      if [ -n "${TMUX_PANE:-}" ]; then
        focus_target=$(tmux list-panes -t "$TMUX_PANE" -F "#{session_name}" 2>/dev/null | head -1) || focus_target="$session"
      fi
      claude-focus "$focus_target" 2>/dev/null || true
    fi
  ) &>/dev/null &
fi

# ── Push notification via ntfy ───────────────────────────────────────────────
if [ "$NOTIFY_PUSH" = "1" ] && [ -n "${NTFY_TOPIC:-}" ]; then
  ntfy_actions="view, Open Topic, https://ntfy.sh/${NTFY_TOPIC}"

  curl -sf \
    -H "Title: $title" \
    -H "Priority: $ntfy_priority" \
    -H "Tags: $ntfy_tags" \
    -H "Actions: $ntfy_actions" \
    -d "$display_msg" \
    "https://ntfy.sh/$NTFY_TOPIC" &>/dev/null &
fi

# ── Scratchpad popup (Notification = show, Stop = dismiss) ───────────────────
# Resolve the actual tmux session name via $TMUX_PANE (inherited from the tmux
# pane where Claude Code runs). This is reliable — unlike Claude's session_id
# (an internal UUID) which can't be mapped to claudesquad_ tmux sessions.
popup_session=""
if [ -n "${TMUX_PANE:-}" ]; then
  popup_session=$(tmux list-panes -t "$TMUX_PANE" -F "#{session_name}" 2>/dev/null | head -1) || true
fi

if [ "$NOTIFY_POPUP" = "1" ] && [ -n "$popup_session" ] && command -v claude-popup &>/dev/null; then
  case "$event" in
    Notification) claude-popup show "$popup_session" &>/dev/null & ;;
    Stop)         claude-popup dismiss "$popup_session" &>/dev/null & ;;
  esac
fi
