#!/usr/bin/env bash
# Select pane in a direction, skipping spacer panes.
# Usage: select_pane.sh {-L|-R|-U|-D}

set -eu

DIR="$1"

tmux select-pane "$DIR"

# If we landed on a spacer, keep going in the same direction
if [ "$(tmux show-option -pqv @is_spacer)" = "1" ]; then
    tmux select-pane "$DIR" 2>/dev/null || tmux select-pane -t '{last}'
fi
