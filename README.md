# claude-commens

Claude Code plugin for the [Commens](https://github.com/peircelabs/commens) enterprise
agent governance platform.

Automatically registers sessions, records interactions, saves checkpoints, and
archives sessions on the Commens governance ledger via Claude Code's lifecycle hooks.

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
2. **COMMENS_PROJECT_ID** environment variable set to your project ID

```bash
export COMMENS_PROJECT_ID=my-project
```

## What It Does

| Hook Event | What Happens |
|------------|-------------|
| **SessionStart** (startup) | Registers a new session on the governance ledger |
| **SessionStart** (resume) | Re-activates an existing session |
| **Stop** | Parses the transcript and records the completed interaction |
| **PreCompact** | Saves a checkpoint before context compaction |
| **SessionEnd** | Archives the session with final metadata |

All hooks are fire-and-forget — they never block Claude Code operation. If the
`commens` binary is unavailable or `COMMENS_PROJECT_ID` is not set, hooks exit
silently.

## MCP Tools

The plugin also starts the Commens MCP server, providing these tools to Claude:

- `ledger_search` — Search past sessions and memories
- `ledger_remember` — Store a memory for future retrieval
- `ledger_read` / `ledger_write` / `ledger_history` — Direct ledger operations

Session lifecycle tools (`register_session`, `finalize_session`) are called
automatically by hooks — the agent does not need to invoke them manually.

## Architecture

```
Claude Code
    │
    ├── SessionStart hook ──→ commens register-session
    ├── Stop hook ──────────→ commens session interaction record
    ├── PreCompact hook ────→ commens checkpoint-session
    ├── SessionEnd hook ────→ commens finalize-session
    │
    └── MCP server ─────────→ commens serve (stdio)
```

## Related

- [peircelabs/commens](https://github.com/peircelabs/commens) — MCP server and CLI
- [peircelabs/commens-api](https://github.com/peircelabs/commens-api) — Shared type definitions
- [peircelabs/gemini-commens](https://github.com/peircelabs/gemini-commens) — Gemini CLI integration
- [peircelabs/codex-commens](https://github.com/peircelabs/codex-commens) — Codex CLI integration
- [peircelabs/opencode-commens](https://github.com/peircelabs/opencode-commens) — OpenCode integration
