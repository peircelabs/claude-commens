# AGENTS.md — claude-commens

Canonical guidance for AI coding agents working in this repository.

## Project Identity

- **Project:** claude-commens
- **Tagline:** Claude Code plugin for Commens enterprise agent governance
- **Repository:** https://github.com/peircelabs/claude-commens
- **Version:** 0.2.1

## Overview

A self-contained Claude Code plugin that integrates with the Commens governance
ledger via lifecycle hooks and MCP tools. Session registration, interaction
recording, checkpointing, and finalization are all handled automatically by
hook scripts — no manual MCP tool calls required from the agent.

## Repository Layout

    claude-commens/
    ├── .claude-plugin/
    │   ├── plugin.json           # Plugin manifest
    │   └── marketplace.json      # Marketplace catalog entry
    ├── .mcp.json                 # MCP server config (commens mcp serve)
    ├── hooks/
    │   └── hooks.json            # Hook event → script bindings
    ├── scripts/
    │   ├── lib/
    │   │   └── commens-hooks.sh  # Tailored bash library (Claude-specific)
    │   ├── launch-server.sh      # MCP server launcher
    │   ├── session-start.sh      # SessionStart (startup) → register-session
    │   ├── session-resume.sh     # SessionStart (resume) → register-session
    │   ├── session-end.sh        # SessionEnd → finalize-session
    │   ├── pre-compact.sh        # PreCompact → checkpoint-session
    │   └── record-interaction.sh # Stop → parse transcript, record interaction
    ├── CLAUDE.md                 # Context document for agent sessions
    ├── AGENTS.md                 # This file
    └── README.md                 # Installation and usage

## Hook Events

| Event | Matcher | Script | Purpose |
|-------|---------|--------|---------|
| SessionStart | startup | session-start.sh | Register new session on ledger |
| SessionStart | resume | session-resume.sh | Re-activate existing session |
| SessionEnd | * | session-end.sh | Archive session to ledger |
| PreCompact | * | pre-compact.sh | Save checkpoint before compaction |
| Stop | — | record-interaction.sh | Record each completed interaction |

## Environment Variables

| Variable | Required | Purpose |
|----------|----------|---------|
| COMMENS_BIN | No | Override path to commens binary |

## Code Style

- `set -euo pipefail` in all hook scripts
- Exit 0 on non-fatal errors (hooks must not crash Claude Code)
- Use `commens_log` for stderr logging (never echo to stdout except JSON output)
- All output JSON must be valid for Claude Code's hook response parser

## Related Repositories

| Repository | Description |
|------------|-------------|
| [peircelabs/commens](https://github.com/peircelabs/commens) | MCP server and CLI |
| [peircelabs/commens-api](https://github.com/peircelabs/commens-api) | Shared Go type definitions |
| [peircelabs/opencode-commens](https://github.com/peircelabs/opencode-commens) | OpenCode integration |
| [peircelabs/gemini-commens](https://github.com/peircelabs/gemini-commens) | Gemini CLI integration |
| [peircelabs/codex-commens](https://github.com/peircelabs/codex-commens) | Codex CLI integration |
