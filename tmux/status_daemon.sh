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

SYSSTAT_INTERVAL=5
SLURM_INTERVAL=60

CPU_SCRIPT="$HOME/.tmux/plugins/tmux-plugin-sysstat/scripts/cpu.sh"
MEM_SCRIPT="$HOME/.tmux/plugins/tmux-plugin-sysstat/scripts/mem.sh"
SLURM_SCRIPT="$HOME/.tmux/slurm_info.sh"

# Store PID so the daemon can be stopped cleanly.
tmux set -gq @status_daemon_pid "$$"

last_slurm=0

while tmux has-session 2>/dev/null; do
    now=$(date +%s)

    if (( now - last_slurm >= SLURM_INTERVAL )); then
        tmux set -gq @slurm_info "$("$SLURM_SCRIPT" 2>/dev/null)"
        last_slurm=$now
    fi

    tmux set -gq @sysstat_cpu "$("$CPU_SCRIPT" 2>/dev/null)"
    tmux set -gq @sysstat_mem "$("$MEM_SCRIPT" 2>/dev/null)"

    sleep "$SYSSTAT_INTERVAL"
done

tmux set -gq @status_daemon_pid ""
