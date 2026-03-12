# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Layout

The repo contains two implementations of the same MCP server — one in Erlang, one in Elixir:

```
erlang/          # Erlang implementation (rebar3 + thoas)
elixir/          # Elixir implementation (mix + jason)
run_server.sh    # Launcher script — picks implementation via TTT_SERVER env var
.mcp.json        # MCP config — uses run_server.sh
```

## Build

```bash
# Erlang
cd erlang && rebar3 escriptize    # → erlang/_build/default/bin/teinum_tictactoe

# Elixir
cd elixir && mix deps.get && mix escript.build   # → elixir/teinum_tictactoe_ex
```

## Choosing the Server

Set `TTT_SERVER` in `.mcp.json` (or as an env var) to `erlang` (default) or `elixir`:

```json
{ "env": { "TTT_SERVER": "elixir" } }
```

## Test

No test framework is configured. Manual testing via piping JSON-RPC messages:

```bash
# Erlang
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' | escript erlang/_build/default/bin/teinum_tictactoe 2>/dev/null

# Elixir
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' | ./elixir/teinum_tictactoe_ex 2>/dev/null
```

## Architecture

This is an MCP (Model Context Protocol) server implementing a Tic Tac Toe game. It communicates over stdio using newline-delimited JSON-RPC 2.0.

**Message flow:** stdin → stdio reader → JSON-RPC dispatch → tool execution → game state → response back through the chain to stdout.

Key design decisions:
- **Escript, not OTP release**: Both implementations run as escripts. The game GenServer is started directly in the main entry point.
- **stdout is sacred**: All logging goes to stderr. Never write diagnostics to stdout.
- **MCP protocol version**: `2025-03-26`. Notifications (no `"id"` field) get `noreply`; requests get `{reply, IoData}`.

## Player Agents

Two Claude Code subagents in `.claude/agents/` play against each other via the shared MCP server configured in `.mcp.json`. Both reference `tictactoe` by name to share the parent session's server connection (same game state).
