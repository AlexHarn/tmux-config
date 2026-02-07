#!/usr/bin/env bash
# Show color-coded remaining SLURM job time for tmux status bar.
# Green >3.5d, yellow 1-3.5d, red <1d.
[ -z "$SLURM_JOB_ID" ] && exit 0

remaining=$(squeue -j "$SLURM_JOB_ID" -h -o "%L" 2>/dev/null)
[ -z "$remaining" ] && exit 0

# Parse SLURM time format (D-HH:MM:SS / HH:MM:SS / MM:SS) to seconds
days=0 h=0 m=0 s=0
t="$remaining"
if [[ "$t" == *-* ]]; then
    days="${t%%-*}"
    t="${t#*-}"
fi
IFS=: read -ra p <<< "$t"
case ${#p[@]} in
    3) h="${p[0]}" m="${p[1]}" s="${p[2]}" ;;
    2) m="${p[0]}" s="${p[1]}" ;;
    1) s="${p[0]}" ;;
esac
secs=$(( 10#$days * 86400 + 10#$h * 3600 + 10#$m * 60 + 10#$s ))

# Format: "5d 12h", "23h 45m", or "45m"
d=$(( secs / 86400 ))
hr=$(( (secs % 86400) / 3600 ))
mn=$(( (secs % 3600) / 60 ))
if [ "$d" -gt 0 ]; then
    display="${d}d ${hr}h"
elif [ "$hr" -gt 0 ]; then
    display="${hr}h ${mn}m"
else
    display="${mn}m"
fi

# Color: green >3.5d, yellow 1-3.5d, red <1d
if [ "$secs" -gt 302400 ]; then
    color="colour076"
elif [ "$secs" -gt 86400 ]; then
    color="colour220"
else
    color="colour160"
fi

echo "#[fg=${color}]${display}#[default]"
