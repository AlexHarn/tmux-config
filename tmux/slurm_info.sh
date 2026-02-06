#!/usr/bin/env bash
[ -n "$SLURM_JOB_ID" ] && echo "job:$SLURM_JOB_ID"
