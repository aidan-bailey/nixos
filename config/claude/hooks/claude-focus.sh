#!/usr/bin/env bash
# Focus the Sway window hosting a Claude Code / claude-squad session.
# Usage: claude-focus SESSION_ID
#
# Tries three strategies in order:
# 1. Find a Sway window whose title contains the session ID
# 2. Find the tmux session by name and walk the PID tree to the terminal window
# 3. Fall back to focusing any Alacritty window

set -euo pipefail

SESSION_ID="${1:-}"
[ -z "$SESSION_ID" ] && exit 0

# Strategy 1: Match window title against session ID
if command -v swaymsg &>/dev/null && command -v jq &>/dev/null; then
  con_id=$(swaymsg -t get_tree | jq -r --arg sid "$SESSION_ID" '
    .. | objects | select(.type? == "con" and .name? != null) |
    select(.name | ascii_downcase | contains($sid | ascii_downcase)) | .id
  ' 2>/dev/null | head -1)

  if [ -n "$con_id" ]; then
    swaymsg "[con_id=$con_id] focus" &>/dev/null
    exit 0
  fi
fi

# Strategy 2: Find tmux session -> pane PID -> walk ancestors to Sway window
if command -v tmux &>/dev/null && command -v swaymsg &>/dev/null; then
  tmux_pid=$(tmux list-panes -t "$SESSION_ID" -F "#{pane_pid}" 2>/dev/null | head -1)
  if [ -n "$tmux_pid" ]; then
    # Get all Sway window PIDs
    while IFS=' ' read -r cid pid; do
      # Walk up the process tree from tmux_pid to see if this window is an ancestor
      check="$tmux_pid"
      for _ in $(seq 1 15); do
        if [ "$check" = "$pid" ]; then
          swaymsg "[con_id=$cid] focus" &>/dev/null
          exit 0
        fi
        check=$(awk '/^PPid:/{print $2}' "/proc/$check/status" 2>/dev/null) || break
        [ -z "$check" ] && break
        [ "$check" = "1" ] && break
      done
    done < <(swaymsg -t get_tree | jq -r '
      .. | objects | select(.type? == "con" and .pid? != null) |
      "\(.id) \(.pid)"
    ' 2>/dev/null)
  fi
fi

# Strategy 3: Focus any Alacritty window
if command -v swaymsg &>/dev/null; then
  swaymsg '[app_id="Alacritty"] focus' &>/dev/null || true
fi
