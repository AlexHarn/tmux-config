#!/usr/bin/env bash
# Background daemon that updates tmux status variables without blocking.
#
# Replaces synchronous #(script) calls in status-right with pre-computed
# tmux user options (#{@slurm_info}, #{@sysstat_cpu}, #{@sysstat_mem}).
# The status bar reads these instantly instead of spawning subprocesses.
#
# Start:  ~/.tmux/status_daemon.sh &
# Stop:   kill $(tmux show -gqv @status_daemon_pid)
# The daemon exits automatically when the tmux server shuts down.

# Exit cleanly on SIGTERM so tmux doesn't report "returned 143".
trap 'exit 0' TERM

SYSSTAT_INTERVAL=5
SLURM_INTERVAL=60

SYSSTAT_DIR="$HOME/.tmux/plugins/tmux-plugin-sysstat/scripts"
CPU_SCRIPT="$SYSSTAT_DIR/cpu.sh"
MEM_SCRIPT="$SYSSTAT_DIR/mem.sh"
LOADAVG_SCRIPT="$SYSSTAT_DIR/loadavg.sh"
SLURM_SCRIPT="$HOME/.tmux/slurm_info.sh"

# Self-dedup: kill any previous instance before taking over.
# This replaces the if-shell kill guard in tmux config files, avoiding a race
# condition where async if-shell + run-shell -b can kill the wrong daemon
# (especially on tmux 3.4+ with deferred callback execution).
old_pid=$(tmux show -gqv @status_daemon_pid 2>/dev/null)
if [ -n "$old_pid" ] && [ "$old_pid" != "$$" ]; then
    kill "$old_pid" 2>/dev/null
    wait "$old_pid" 2>/dev/null
fi
tmux set -gq @status_daemon_pid "$$"

last_slurm=0

while tmux list-sessions &>/dev/null; do
    now=$(date +%s)

    if (( now - last_slurm >= SLURM_INTERVAL )); then
        tmux set -gq @slurm_info "$("$SLURM_SCRIPT" 2>/dev/null)"
        last_slurm=$now
    fi

    tmux set -gq @sysstat_cpu "$("$CPU_SCRIPT" 2>/dev/null)"
    tmux set -gq @sysstat_mem "$("$MEM_SCRIPT" 2>/dev/null)"
    [ -x "$LOADAVG_SCRIPT" ] && tmux set -gq @sysstat_loadavg "$("$LOADAVG_SCRIPT" 2>/dev/null)"

    sleep "$SYSSTAT_INTERVAL"
done

tmux set -gq @status_daemon_pid ""
