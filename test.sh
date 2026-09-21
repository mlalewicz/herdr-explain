#!/usr/bin/env bash
# Smoke test: stub herdr, run both modes against the real local LLM, assert shape.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/state"
cat > "$tmp/bin/herdr" <<'STUB'
#!/usr/bin/env bash
case "$1 $2" in
  "pane read") printf '%s\n' '~ ❯ ls /nope' 'ls: cannot access '"'"'/nope'"'"': No such file or directory' '~ ❯ ' ;;
  "pane send-text") printf '%s' "$4" > "$STUB_LOG/sent" ;;
  "plugin pane") echo opened > "$STUB_LOG/opened"; echo "{\"result\":{\"plugin_pane\":{\"pane\":{\"pane_id\":\"test:p2\"}}}}" ;;
esac
STUB
chmod +x "$tmp/bin/herdr"
export HERDR_BIN_PATH="$tmp/bin/herdr" HERDR_PANE_ID=test:p1 HERDR_PLUGIN_STATE_DIR="$tmp/state" STUB_LOG="$tmp"

bash "$here/scripts/ask.sh" fix
sent="$(cat "$tmp/sent")"
[ -n "$sent" ] || { echo "FAIL fix: nothing sent"; exit 1; }
case "$sent" in *$'\n'*|*'`'*) echo "FAIL fix: multi-line or backticks: $sent"; exit 1;; esac
echo "fix ok: $sent"

bash "$here/scripts/ask.sh" explain
[ -s "$tmp/state/last.txt" ] && [ -f "$tmp/opened" ] || { echo "FAIL explain"; exit 1; }
echo "explain ok:"; cat "$tmp/state/last.txt"
