# claude-commens

Claude Code plugin for the [Commens](https://github.com/peircelabs/commens) enterprise
agent governance platform.

Automatically starts sessions, records interactions, and ends sessions on the
Commens governance ledger via Claude Code's lifecycle hooks.

## Installation

### From GitHub (marketplace)

```bash
claude plugin marketplace add peircelabs/claude-commens
claude plugin install sessions@commens
```

### From local directory

```bash
git clone https://github.com/peircelabs/claude-commens.git
claude --plugin-dir ./claude-commens
```

## Prerequisites

1. **commens CLI** installed and available in PATH (or set `COMMENS_BIN`)
2. **Default project** configured via `commens config set defaultProject <name>` or a local `.commens/config.json`

## What It Does

| Hook Event | What Happens |
|------------|-------------|
| **SessionStart** (startup) | Starts a new session on the governance ledger |
| **SessionStart** (resume) | Re-activates an existing session |
| **Stop** | Parses the transcript and adds the completed interaction |
| **SessionEnd** | Ends and archives the session with final metadata |

All hooks are fire-and-forget — they never block Claude Code operation. If the
`commens` binary is unavailable, hooks exit silently.

## MCP Tools

The plugin also starts the Commens MCP server, providing these tools to Claude:

- `ledger_search` — Search past sessions and memories
- `ledger_remember` — Store a memory for future retrieval
- `ledger_read` / `ledger_write` / `ledger_history` — Direct ledger operations

Session lifecycle tools (`session_start`, `session_end`) are called automatically
by hooks — the agent does not need to invoke them manually.

## Architecture

```
Claude Code
    │
    ├── SessionStart hook ──→ commens session start
    ├── Stop hook ──────────→ commens session interaction add
    ├── SessionEnd hook ────→ commens session end
    │
    └── MCP server ─────────→ commens mcp serve (stdio)
```

## Related

- [peircelabs/commens](https://github.com/peircelabs/commens) — MCP server and CLI
- [peircelabs/commens-api](https://github.com/peircelabs/commens-api) — Shared type definitions
- [peircelabs/gemini-commens](https://github.com/peircelabs/gemini-commens) — Gemini CLI integration
- [peircelabs/codex-commens](https://github.com/peircelabs/codex-commens) — Codex CLI integration
- [peircelabs/opencode-commens](https://github.com/peircelabs/opencode-commens) — OpenCode integration
