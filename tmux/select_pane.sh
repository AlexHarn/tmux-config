#!/usr/bin/env bash
# Select pane in a direction, skipping spacer panes in team mode.
# In normal triple layout, spacers are the user's terminals and navigable.
# Usage: select_pane.sh {-L|-R|-U|-D}

set -eu

DIR="$1"

tmux select-pane "$DIR"

# Auto-focus: expand the focused agent pane vertically in team mode.
# Runs here (not on a hook) to avoid conflicts with Claude Code's
# own pane management --- only triggers on manual navigation.
if [ "$(tmux show-option -wqv @team_mode)" = "1" ]; then
    ~/.tmux/layout.sh auto-focus 2>/dev/null || true
fi
