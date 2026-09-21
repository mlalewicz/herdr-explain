# herdr-explain

Explain or fix the most recent error in the current herdr pane with a local OpenAI-compatible LLM. Reads the pane scrollback, never reruns anything, works in any shell.

- `prefix+a` explain: explanation opens in a split pane, `q` closes.
- `prefix+f` fix: proposed command is typed into the pane, you press Enter.

Config (optional): `~/.config/herdr/plugins/config/herdr-explain/explain.conf` with bash assignments `EXPLAIN_URL`, `EXPLAIN_LINES` (100), `EXPLAIN_MAX_TOKENS` (400). Default URL is llama-server on localhost:8080.

Install: `herdr plugin link ~/infra/herdr-explain`, append the keybindings below to `~/.config/herdr/config.toml`, `herdr server reload-config`.

Test: `./test.sh` (needs the LLM up).
