#!/usr/bin/env bash
# Ultrawide layout system for tmux
# Provides triple column layout with fixed-width center pane,
# auto-layout for agent teams, and dynamic focus resizing.

set -eu

COMMAND="${1:-help}"

# Side panes start with a blank screen; any keypress activates the shell.
SIDE_PANE_CMD="clear; read -n 1 -s -r || true; exec $SHELL"

# Minimum height (lines) for unfocused agent panes in auto-focus mode.
AGENT_MIN_HEIGHT=5

# =====================================================================
# ===  Helpers                                                      ===
# =====================================================================

get_option() {
    tmux show-option -gqv "$1"
}

get_window_option() {
    tmux show-option -wqv "$1"
}

get_pane_option() {
    tmux show-option -pqv -t "${1:-}" "$2" 2>/dev/null
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

tag_spacer() {
    tmux set-option -p -t "$1" @is_spacer 1
}

tag_center() {
    tmux set-option -p -t "$1" @is_center 1
}

# Equalize heights of panes in the same column.
equalize_column() {
    local -a panes=("$@")
    local count=${#panes[@]}
    if [ "$count" -le 1 ]; then return; fi

    local window_height
    window_height=$(tmux display-message -p '#{window_height}')
    local target=$(( window_height / count ))

    local i
    for i in $(seq 0 $((count - 2))); do
        tmux resize-pane -t "${panes[$i]}" -y "$target" 2>/dev/null || true
    done
}

# =====================================================================
# ===  Triple layout (standard ultrawide)                           ===
# =====================================================================

cmd_triple() {
    if ! is_ultrawide; then
        tmux split-window -h -c "#{pane_current_path}"
        return
    fi

    if [ "$(count_panes)" -ne 1 ]; then
        tmux display-message "Triple layout: start from a single pane"
        return
    fi

    local cw total_width sw
    cw=$(center_width)
    total_width=$(tmux display-message -p '#{window_width}')

    if [ "$total_width" -le "$cw" ]; then
        tmux split-window -h -c "#{pane_current_path}" -l '50%'
        tmux split-window -h -c "#{pane_current_path}" -l '50%'
        return
    fi

    sw=$(( (total_width - cw) / 2 ))

    local center_pane right_pane left_pane
    center_pane=$(tmux display-message -p '#{pane_id}')
    tag_center "$center_pane"

    tmux split-window -h -c "#{pane_current_path}" -l "$sw" -t "$center_pane" "$SIDE_PANE_CMD"
    right_pane=$(tmux display-message -p '#{pane_id}')
    tag_spacer "$right_pane"

    tmux split-window -h -b -c "#{pane_current_path}" -l "$sw" -t "$center_pane" "$SIDE_PANE_CMD"
    left_pane=$(tmux display-message -p '#{pane_id}')
    tag_spacer "$left_pane"

    tmux select-pane -t "$center_pane"
}

# Auto-apply triple layout for new windows (called from after-new-window hook).
cmd_auto() {
    if ! is_ultrawide; then
        return
    fi

    if [ "$(count_panes)" -ne 1 ]; then
        return
    fi

    local cw total_width sw
    cw=$(center_width)
    total_width=$(tmux display-message -p '#{window_width}')

    if [ "$total_width" -le "$cw" ]; then
        return
    fi

    sw=$(( (total_width - cw) / 2 ))

    local center_pane right_pane left_pane
    center_pane=$(tmux display-message -p '#{pane_id}')
    tag_center "$center_pane"

    tmux split-window -h -c "#{pane_current_path}" -l "$sw" -t "$center_pane" "$SIDE_PANE_CMD"
    right_pane=$(tmux display-message -p '#{pane_id}')
    tag_spacer "$right_pane"

    tmux split-window -h -b -c "#{pane_current_path}" -l "$sw" -t "$center_pane" "$SIDE_PANE_CMD"
    left_pane=$(tmux display-message -p '#{pane_id}')
    tag_spacer "$left_pane"

    tmux select-pane -t "$center_pane"
}

# =====================================================================
# ===  Auto-layout                                                  ===
# =====================================================================
#
# Called by after-split-window hook. Detects tagged panes and rebuilds
# the 3-column layout:
#   - @is_center pane → center column bottom
#   - @is_spacer panes → center column top (side by side or stacked)
#   - Everything else → distributed across left/right side columns
#
# Does nothing if no @is_center pane exists (unmanaged window).
# Does nothing if fewer than 2 untagged panes exist (standard triple).

cmd_auto_layout() {
    # Classify all panes by tag
    local center=""
    local -a spacers=()
    local -a others=()

    while IFS= read -r pane; do
        if [ "$(get_pane_option "$pane" @is_center)" = "1" ]; then
            center="$pane"
        elif [ "$(get_pane_option "$pane" @is_spacer)" = "1" ]; then
            spacers+=("$pane")
        else
            others+=("$pane")
        fi
    done < <(tmux list-panes -F '#{pane_id}')

    # No tagged center pane → not a managed window, skip
    if [ -z "$center" ]; then return; fi

    local n=${#others[@]}

    # Need at least 2 untagged panes to justify 3-column layout
    if [ "$n" -lt 2 ]; then return; fi

    # --- Rebuild layout ---

    # Break all non-center panes to temporary windows (pane IDs preserved)
    for pane in "${others[@]}" "${spacers[@]}"; do
        tmux break-pane -d -s "$pane"
    done

    # Calculate column widths
    local total_width cw sw
    total_width=$(tmux display-message -p '#{window_width}')
    cw=$(center_width)

    if [ "$total_width" -le "$cw" ]; then
        # Terminal too narrow; tile everything
        for pane in "${others[@]}" "${spacers[@]}"; do
            tmux join-pane -v -t "$center" -s "$pane"
        done
        tmux select-layout tiled
        tmux select-pane -t "$center"
        return
    fi

    sw=$(( (total_width - cw) / 2 ))

    # Distribute: left = floor(n/2), right = ceil(n/2)
    local left_count=$(( n / 2 ))
    local right_count=$(( n - left_count ))

    # --- Right column ---
    local right_anchor_idx=$left_count
    tmux join-pane -h -t "$center" -s "${others[$right_anchor_idx]}" -l "$sw"
    local i
    for i in $(seq $((right_anchor_idx + 1)) $((n - 1))); do
        tmux join-pane -v -t "${others[$right_anchor_idx]}" -s "${others[$i]}"
    done

    # --- Left column ---
    tmux join-pane -hb -t "$center" -s "${others[0]}" -l "$sw"
    for i in $(seq 1 $((left_count - 1))); do
        tmux join-pane -v -t "${others[0]}" -s "${others[$i]}"
    done

    # --- Spacers in center column above lead ---
    if [ "${#spacers[@]}" -ge 2 ]; then
        tmux join-pane -vb -t "$center" -s "${spacers[0]}" -l '25%'
        local spacer_split
        spacer_split=$(get_option @team_spacer_split)
        if [ "${spacer_split:-h}" = "v" ]; then
            tmux join-pane -v -t "${spacers[0]}" -s "${spacers[1]}"
        else
            tmux join-pane -h -t "${spacers[0]}" -s "${spacers[1]}"
        fi
    elif [ "${#spacers[@]}" -eq 1 ]; then
        tmux join-pane -vb -t "$center" -s "${spacers[0]}" -l '25%'
    fi

    # --- Equalize agent pane heights within each column ---
    equalize_column "${others[@]:0:$left_count}"
    equalize_column "${others[@]:$left_count:$right_count}"

    # Mark window as in team/auto-layout mode (for auto-focus)
    tmux set-option -w @team_mode 1
    tmux set-option -w @team_lead "$center"

    tmux select-pane -t "$center"
}

# =====================================================================
# ===  Manual team trigger                                          ===
# =====================================================================
#
# For windows not created with the triple layout: tags the active pane
# as center and runs auto-layout. Idempotent if tags already exist.

cmd_team() {
    # Tag active pane as center if none is tagged yet
    local has_center=""
    while IFS= read -r pane; do
        if [ "$(get_pane_option "$pane" @is_center)" = "1" ]; then
            has_center=1
            break
        fi
    done < <(tmux list-panes -F '#{pane_id}')

    if [ -z "$has_center" ]; then
        tag_center "$(tmux display-message -p '#{pane_id}')"
    fi

    cmd_auto_layout

    # Reset window styles that Claude Code may have overridden
    local accent
    if [ "${TMUX_NEST_LEVEL:-0}" -ge 3 ]; then
        accent="colour39"    # L3 blue
    else
        accent="colour166"   # L1/L2 orange
    fi
    tmux setw pane-active-border-style "fg=$accent"
    tmux setw pane-border-style "fg=colour238"
    tmux setw pane-border-status off
}

# =====================================================================
# ===  Team restore                                                 ===
# =====================================================================
#
# Restores standard ultrawide triple layout. Kills remaining agent
# panes, moves spacers back to side columns.

cmd_team_restore() {
    local center=""
    local -a spacers=()
    local -a others=()

    while IFS= read -r pane; do
        if [ "$(get_pane_option "$pane" @is_center)" = "1" ]; then
            center="$pane"
        elif [ "$(get_pane_option "$pane" @is_spacer)" = "1" ]; then
            spacers+=("$pane")
        else
            others+=("$pane")
        fi
    done < <(tmux list-panes -F '#{pane_id}')

    if [ -z "$center" ]; then
        tmux display-message "No tagged center pane found"
        return
    fi

    # Kill leftover non-tagged panes (agents)
    for pane in "${others[@]}"; do
        tmux kill-pane -t "$pane" 2>/dev/null || true
    done

    # Break spacers to temp windows
    for pane in "${spacers[@]}"; do
        tmux break-pane -d -s "$pane"
    done

    # Rebuild standard triple layout around center
    local total_width cw sw
    total_width=$(tmux display-message -p '#{window_width}')
    cw=$(center_width)
    sw=$(( (total_width - cw) / 2 ))

    if [ "${#spacers[@]}" -ge 2 ]; then
        tmux join-pane -h -t "$center" -s "${spacers[0]}" -l "$sw"
        tmux join-pane -hb -t "$center" -s "${spacers[1]}" -l "$sw"
    elif [ "${#spacers[@]}" -eq 1 ]; then
        tmux join-pane -h -t "$center" -s "${spacers[0]}" -l "$sw"
        tmux split-window -h -b -c "#{pane_current_path}" -l "$sw" -t "$center" "$SIDE_PANE_CMD"
        tag_spacer "$(tmux display-message -p '#{pane_id}')"
    else
        # No spacers left; create fresh ones
        tmux split-window -h -c "#{pane_current_path}" -l "$sw" -t "$center" "$SIDE_PANE_CMD"
        tag_spacer "$(tmux display-message -p '#{pane_id}')"
        tmux split-window -h -b -c "#{pane_current_path}" -l "$sw" -t "$center" "$SIDE_PANE_CMD"
        tag_spacer "$(tmux display-message -p '#{pane_id}')"
    fi

    # Clear team mode
    tmux set-option -wu @team_mode
    tmux set-option -wu @team_lead

    # Reset window styles that Claude Code may have overridden.
    # Apply the accent color for the current nesting level.
    local accent
    if [ "${TMUX_NEST_LEVEL:-0}" -ge 3 ]; then
        accent="colour39"    # L3 blue
    else
        accent="colour166"   # L1/L2 orange
    fi
    tmux setw pane-active-border-style "fg=$accent"
    tmux set -g mode-style "fg=default,bg=$accent"
    tmux set -g message-style "fg=$accent,bg=colour232"
    tmux setw pane-border-status off
    tmux setw automatic-rename off

    tmux select-pane -t "$center"
    tmux display-message "Triple layout restored"
}

# =====================================================================
# ===  Auto-focus (dynamic vertical resize)                         ===
# =====================================================================
#
# Called by pane-focus-in hook. Expands the focused pane vertically
# within its column; column widths are unaffected. Only active when
# @team_mode is set on the window.

cmd_auto_focus() {
    if [ "$(get_window_option @team_mode)" != "1" ]; then return; fi

    # Validate that the team lead pane still exists; clear stale state if not
    local lead
    lead=$(get_window_option @team_lead)
    if [ -n "$lead" ]; then
        if ! tmux list-panes -F '#{pane_id}' | grep -qF "$lead"; then
            tmux set-option -wu @team_mode
            tmux set-option -wu @team_lead
            return
        fi
    fi

    local current
    current=$(tmux display-message -p '#{pane_id}')

    # Collect spacer pane IDs
    local -a spacers=()
    while IFS= read -r pane; do
        if [ "$(get_pane_option "$pane" @is_spacer)" = "1" ]; then
            spacers+=("$pane")
        fi
    done < <(tmux list-panes -F '#{pane_id}')

    local window_height
    window_height=$(tmux display-message -p '#{window_height}')

    # --- Spacer focused: expand it, shrink the other spacer ---
    if [ "$(get_pane_option "$current" @is_spacer)" = "1" ]; then
        # Give spacer row 50% of center column height
        tmux resize-pane -t "$current" -y "$(( window_height * 50 / 100 ))" 2>/dev/null || true
        # Expand focused spacer horizontally, shrink the other to minimum
        local center_width
        center_width=$(get_option @center_width)
        center_width=${center_width:-120}
        tmux resize-pane -t "$current" -x "$(( center_width - 4 ))" 2>/dev/null || true
        return
    fi

    # --- Lead focused: equalize spacers, shrink spacer row back to 25% ---
    if [ "$(get_pane_option "$current" @is_center)" = "1" ]; then
        if [ "${#spacers[@]}" -ge 2 ]; then
            local center_width
            center_width=$(get_option @center_width)
            center_width=${center_width:-120}
            local half_w=$(( center_width / 2 ))
            for sp in "${spacers[@]}"; do
                tmux resize-pane -t "$sp" -x "$half_w" 2>/dev/null || true
            done
            # Shrink spacer row back to 25%
            tmux resize-pane -t "${spacers[0]}" -y "$(( window_height * 25 / 100 ))" 2>/dev/null || true
        elif [ "${#spacers[@]}" -eq 1 ]; then
            tmux resize-pane -t "${spacers[0]}" -y "$(( window_height * 25 / 100 ))" 2>/dev/null || true
        fi
        return
    fi

    # --- Agent focused: expand vertically in its column ---
    local target=$(( window_height * 60 / 100 ))

    # Clamp so siblings don't go below minimum height
    local col_x sibling_count
    col_x=$(tmux display-message -p '#{pane_left}')
    sibling_count=$(tmux list-panes -F '#{pane_id}' \
        -f "#{==:#{pane_left},${col_x}}" | wc -l)
    local max_target=$(( window_height - (sibling_count - 1) * AGENT_MIN_HEIGHT ))
    if [ "$target" -gt "$max_target" ]; then
        target=$max_target
    fi

    tmux resize-pane -y "$target" 2>/dev/null || true
}

# =====================================================================
# ===  Rebalance (simple tiled fallback)                            ===
# =====================================================================

cmd_rebalance() {
    local n
    n=$(count_panes)
    if [ "$n" -le 1 ]; then
        tmux display-message "Only 1 pane, nothing to rebalance"
        return
    fi
    tmux select-layout tiled
    tmux display-message "Rebalanced $n panes (tiled)"
}

# =====================================================================
# ===  Toggle ultrawide                                             ===
# =====================================================================

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

# =====================================================================
# ===  Dispatch                                                     ===
# =====================================================================

case "$COMMAND" in
    triple)          cmd_triple ;;
    auto)            cmd_auto ;;
    auto-layout)     cmd_auto_layout ;;
    team)            cmd_team ;;
    team-restore)    cmd_team_restore ;;
    auto-focus)      cmd_auto_focus ;;
    rebalance)       cmd_rebalance ;;
    toggle-ultrawide) cmd_toggle_ultrawide ;;
    *)
        echo "Usage: layout.sh {triple|auto|auto-layout|team|team-restore|auto-focus|rebalance|toggle-ultrawide}"
        exit 1
        ;;
esac
