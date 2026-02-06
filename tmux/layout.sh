#!/usr/bin/env bash
# Ultrawide layout system for tmux
# Provides triple column layout with fixed-width center pane.

set -eu

COMMAND="${1:-help}"

# Side panes start with a blank screen; any keypress activates the shell.
SIDE_PANE_CMD="clear; read -n 1 -s -r || true; exec $SHELL"

get_option() {
    tmux show-option -gqv "$1"
}

center_width() {
    local w
    w=$(get_option @center_width)
    echo "${w:-120}"
}

is_ultrawide() {
    local mode
    mode=$(get_option @ultrawide_mode)
    [ "${mode:-on}" = "on" ]
}

count_panes() {
    tmux list-panes -F '#{pane_id}' | wc -l
}

cmd_triple() {
    if ! is_ultrawide; then
        # In laptop mode, just do a standard 50/50 split
        tmux split-window -h -c "#{pane_current_path}"
        return
    fi

    if [ "$(count_panes)" -ne 1 ]; then
        tmux display-message "Triple layout: start from a single pane"
        return
    fi

    local cw total_width side_width
    cw=$(center_width)
    total_width=$(tmux display-message -p '#{window_width}')

    if [ "$total_width" -le "$cw" ]; then
        # Terminal too narrow; just split in thirds
        tmux split-window -h -c "#{pane_current_path}" -l '50%'
        tmux split-window -h -c "#{pane_current_path}" -l '50%'
        return
    fi

    side_width=$(( (total_width - cw) / 2 ))

    local center_pane
    center_pane=$(tmux display-message -p '#{pane_id}')

    # Create right side pane (blank until activated)
    tmux split-window -h -c "#{pane_current_path}" -l "$side_width" -t "$center_pane" "$SIDE_PANE_CMD"

    # Create left side pane (blank until activated)
    tmux split-window -h -b -c "#{pane_current_path}" -l "$side_width" -t "$center_pane" "$SIDE_PANE_CMD"

    # Focus the center pane
    tmux select-pane -t "$center_pane"
}

# Auto-apply triple layout for new windows (called from after-new-window hook).
# Does nothing if ultrawide mode is off or terminal is too narrow.
cmd_auto() {
    if ! is_ultrawide; then
        return
    fi

    if [ "$(count_panes)" -ne 1 ]; then
        return
    fi

    local cw total_width side_width
    cw=$(center_width)
    total_width=$(tmux display-message -p '#{window_width}')

    if [ "$total_width" -le "$cw" ]; then
        return
    fi

    side_width=$(( (total_width - cw) / 2 ))

    local center_pane
    center_pane=$(tmux display-message -p '#{pane_id}')

    tmux split-window -h -c "#{pane_current_path}" -l "$side_width" -t "$center_pane" "$SIDE_PANE_CMD"
    tmux split-window -h -b -c "#{pane_current_path}" -l "$side_width" -t "$center_pane" "$SIDE_PANE_CMD"
    tmux select-pane -t "$center_pane"
}

cmd_toggle_ultrawide() {
    local current
    current=$(get_option @ultrawide_mode)
    if [ "${current:-on}" = "on" ]; then
        tmux set-option -g @ultrawide_mode off
        tmux display-message "Ultrawide mode [OFF]"
    else
        tmux set-option -g @ultrawide_mode on
        tmux display-message "Ultrawide mode [ON]"
    fi
}

case "$COMMAND" in
    triple)
        cmd_triple
        ;;
    auto)
        cmd_auto
        ;;
    toggle-ultrawide)
        cmd_toggle_ultrawide
        ;;
    *)
        echo "Usage: layout.sh {triple|auto|toggle-ultrawide}"
        exit 1
        ;;
esac
