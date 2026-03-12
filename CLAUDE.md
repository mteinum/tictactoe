# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build

```bash
rebar3 escriptize          # Build the escript binary → _build/default/bin/teinum_tictactoe
rebar3 compile             # Compile without packaging escript
```

## Test

No test framework is configured. Manual testing via piping JSON-RPC messages:

```bash
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' | _build/default/bin/teinum_tictactoe 2>/dev/null
```

## Architecture

This is an MCP (Model Context Protocol) server implementing a Tic Tac Toe game. It communicates over stdio using newline-delimited JSON-RPC 2.0.

**Message flow:** stdin → `ttt_stdio` (line reader) → `ttt_mcp` (JSON-RPC dispatch) → `ttt_tools` (tool execution) → `ttt_game` (game state) → response back through the chain to stdout.

Key design decisions:
- **Escript, not OTP release**: Runs as an escript with `-noshell`. The `ttt_game` gen_server is started directly in `main/1` (not via the application supervisor) because `application:ensure_all_started` doesn't work reliably in escript mode.
- **JSON via thoas**: Pure Erlang JSON library (v1.2.1). All map keys are binaries.
- **stdout is sacred**: All logging goes to stderr. The OTP logger is redirected to `standard_error` at startup. Never write diagnostics to stdout.
- **MCP protocol version**: `2025-03-26`. Notifications (no `"id"` field) get `noreply`; requests get `{reply, IoData}`.

## Player Agents

Two Claude Code subagents in `.claude/agents/` play against each other via the shared MCP server configured in `.mcp.json`. Both reference `tictactoe` by name to share the parent session's server connection (same game state).
