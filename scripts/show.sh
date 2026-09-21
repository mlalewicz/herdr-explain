#!/usr/bin/env bash
# Pane entrypoint: page the last explanation. q closes the pane.
exec less -R -P 'herdr-explain (q to close)' "${HERDR_PLUGIN_STATE_DIR:-${TMPDIR:-/tmp}}/last.txt"
