#!/usr/bin/env bash
# Pane entrypoint: print the last explanation, wait for a key, exit (closes the pane).
# ponytail: plain cat instead of less — less drew nothing until the pane got focus
# (PTY unsized at spawn); answers are ≤400 tokens so paging is not needed.
fold -s -w "${COLUMNS:-$(tput cols 2>/dev/null || echo 80)}" "${HERDR_PLUGIN_STATE_DIR:-${TMPDIR:-/tmp}}/last.txt"
printf '\n[any key closes]'
read -rsn1
