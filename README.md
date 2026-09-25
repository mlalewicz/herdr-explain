# herdr-explain

Explain or fix the most recent error in the current herdr pane with a local OpenAI-compatible LLM. Reads the pane scrollback, never reruns anything, works in any shell, including SSH sessions to other hosts (the remote never sees the plugin).

- `prefix+e` explain: explanation opens in a split pane, `q` closes.
- `prefix+f` fix: proposed command is typed into the pane, you press Enter.

Config (optional): `explain.conf` in `$(herdr plugin config-dir herdr-explain)`, bash assignments:

- `EXPLAIN_URL` — OpenAI-compatible chat completions endpoint, default llama-server `http://localhost:8080/v1/chat/completions`
- `EXPLAIN_LINES` — scrollback lines sent, default 100
- `EXPLAIN_MAX_TOKENS` — default 400
- `EXPLAIN_OUTPUT` — `pane` (default) opens a split; `inline` types the explanation into the pane as one `# ` comment line, no Enter

Install: `herdr plugin link ~/infra/herdr-explain`, append the keybindings below to `~/.config/herdr/config.toml`, `herdr server reload-config`.

Test: `./test.sh` (needs the LLM up). Nothing checks the LLM at install; the first keypress with it down notifies "no LLM at <url>", so `curl <url>` once after setup.

```toml
[[keys.command]]
key = "prefix+e"
type = "plugin_action"
command = "herdr-explain.explain"
description = "Explain last error"

[[keys.command]]
key = "prefix+f"
type = "plugin_action"
command = "herdr-explain.fix"
description = "Fix last error"
```

## Possible todos

- Multi-line fixes: fix mode types only the first non-empty line, so a `cmd1 &&`-continued or heredoc answer is truncated. The prompt asks for one line but nothing enforces it. Options: reject multi-line answers with a notification, or send them joined with `;`.
- Other providers: `EXPLAIN_URL` only speaks OpenAI chat completions. Claude/Codex subscriptions are not HTTP endpoints; an `EXPLAIN_BACKEND=claude|codex` would swap the curl for `claude -p --bare --system-prompt … --tools ""` / `codex exec --ephemeral -s read-only`. Unmeasured: CLI startup latency vs the local model.
- Exit code and command boundaries: the scrollback is text only, herdr does not parse OSC 133. A `fish_postexec` hook writing command + `$status` to a per-pane file would give both for shells that opt in.
