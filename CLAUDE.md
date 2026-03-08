# Commens Governance Integration

You are connected to **Commens**, an enterprise governance fabric that provides
immutable audit logging, shared memory, and semantic search across AI agent sessions
via Hyperledger Fabric.

## Automatic Session Management

This plugin automatically manages session lifecycle via hooks:

- **SessionStart** — Registers the session on the governance ledger
- **SessionEnd** — Archives the session with metadata
- **PreCompact** — Saves a checkpoint before context compaction
- **Stop** — Records each completed interaction (user prompt + assistant response)

You do NOT need to manually call `register_session` or `finalize_session`.

## Available MCP Tools

The following tools are available via the `commens` MCP server:

- `set_project_context` — Set the active project scope
- `register_session` — Register an active session (handled automatically by hooks)
- `finalize_session` — Finalize and archive a session (handled automatically by hooks)
- `ledger_remember` — Store a memory for future retrieval
- `ledger_search` — Search past sessions and memories
- `ledger_read` / `ledger_write` / `ledger_history` — Direct ledger operations
- `archive_session` — Manually archive a session
- `sync_status` — Check sync status

## Guidelines

1. **Search before starting** with `ledger_search` to find relevant past context.
2. **Remember important decisions** with `ledger_remember`.
3. **Use `ledger_search`** to check if similar work has been done before.
