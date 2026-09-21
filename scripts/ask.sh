#!/usr/bin/env bash
# Explain or fix the most recent error visible in the current herdr pane.
# Mode comes from the invoking action id (explain|fix); $1 overrides for testing.
# Config: $HERDR_PLUGIN_CONFIG_DIR/explain.conf may set EXPLAIN_URL, EXPLAIN_LINES,
# EXPLAIN_MAX_TOKENS (plain bash assignments).
set -euo pipefail

herdr="${HERDR_BIN_PATH:-herdr}"
mode="${1:-${HERDR_PLUGIN_ACTION_ID:-explain}}"
pane="${HERDR_PANE_ID:?HERDR_PANE_ID not set}"
state="${HERDR_PLUGIN_STATE_DIR:-${TMPDIR:-/tmp}}"
conf="${HERDR_PLUGIN_CONFIG_DIR:-$HOME/.config/herdr/plugins/config/herdr-explain}/explain.conf"
[ -f "$conf" ] && . "$conf"
: "${EXPLAIN_URL:=http://localhost:8080/v1/chat/completions}"
: "${EXPLAIN_LINES:=100}"
: "${EXPLAIN_MAX_TOKENS:=400}"

notify() { "$herdr" notification show "$1" >/dev/null 2>&1 || true; }

case "$mode" in
  fix) system="You are a shell assistant. The user pastes the last lines of their terminal.
Find the most recent failed command and its error message. If nothing failed, reply with the single line: no error found.
Reply with ONLY the single shell command that fixes it. No explanation, no markdown, no code fences." ;;
  explain) system="You are a shell assistant. The user pastes the last lines of their terminal.
Find the most recent failed command and its error message. If nothing failed, reply with the single line: no error found.
Explain the cause in 2-4 sentences, then give the fix command on its own line prefixed by 'Fix: '.
Plain text, no markdown." ;;
  *) echo "unknown mode: $mode" >&2; exit 2 ;;
esac

notify "explain: thinking…"
scrollback="$("$herdr" pane read "$pane" --source recent-unwrapped --lines "$EXPLAIN_LINES")"

# enable_thinking=false is a llama-server chat_template_kwargs knob; other
# OpenAI-compatible servers ignore or reject it.
answer="$(jq -n --arg s "$system" --arg u "$scrollback" --argjson n "$EXPLAIN_MAX_TOKENS" \
    '{messages:[{role:"system",content:$s},{role:"user",content:$u}],
      max_tokens:$n, temperature:0.2, chat_template_kwargs:{enable_thinking:false}}' \
  | curl -sS -m 60 "$EXPLAIN_URL" -H 'content-type: application/json' -d @- \
  | jq -r '.choices[0].message.content // empty')" \
  || { notify "explain: request to $EXPLAIN_URL failed"; exit 1; }
[ -n "$answer" ] || { notify "explain: empty answer from $EXPLAIN_URL"; exit 1; }

case "$mode" in
  fix)
    # first non-empty line, code fences and wrapping backticks stripped
    cmd="$(printf '%s\n' "$answer" | sed -e '/^```/d' -e 's/^`\(.*\)`$/\1/' | grep -m1 .)"
    "$herdr" pane send-text "$pane" "$cmd" ;;
  explain)
    printf '%s\n' "$answer" > "$state/last.txt"
    "$herdr" plugin pane open --plugin herdr-explain --entrypoint result \
      --placement split --direction down --target-pane "$pane" --focus >/dev/null ;;
esac
