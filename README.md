# Teinum Tictactoe

[![Build](https://github.com/mteinum/tictactoe/actions/workflows/build.yml/badge.svg)](https://github.com/mteinum/tictactoe/actions/workflows/build.yml)

A Tic Tac Toe MCP (Model Context Protocol) server written in Erlang, with two Claude Code subagents that play against each other.

## Prerequisites

- Erlang/OTP (with `escript` and `rebar3`)
- [Claude Code](https://claude.com/claude-code)

## Build

```bash
rebar3 escriptize
```

The escript binary is output to `_build/default/bin/teinum_tictactoe`.

## MCP Server

The server communicates over stdio using JSON-RPC 2.0 and exposes four tools:

| Tool | Description |
|------|-------------|
| `new_game` | Start a new game. Resets the board. X goes first. |
| `make_move` | Make a move. Takes `player` ("X" or "O") and `position` (1-9). |
| `get_board` | Get the current board as an ASCII grid. |
| `get_status` | Get the game status: in progress, winner, or draw. |

Board positions are laid out as:

```
 1 | 2 | 3
---+---+---
 4 | 5 | 6
---+---+---
 7 | 8 | 9
```

### Add to an MCP client

```json
{
  "mcpServers": {
    "tictactoe": {
      "type": "stdio",
      "command": "escript",
      "args": ["/path/to/teinum-tictactoe/_build/default/bin/teinum_tictactoe"]
    }
  }
}
```

## Player Agents

Two Claude Code subagents are included in `.claude/agents/` that can play against each other using the MCP server:

- **player-x** -- Plays as X (always goes first). Uses Haiku for fast responses.
- **player-o** -- Plays as O. Uses Haiku for fast responses.

Both agents share the same tictactoe MCP server instance (configured in `.mcp.json`) so they play on the same board. Each agent follows the same strategy priority:

1. Win if possible
2. Block the opponent from winning
3. Take the center
4. Take a corner
5. Take a side

### Play a game

Start a Claude Code session from the project directory, then:

```
Use player-x to start a new game and make the first move,
then use player-o to respond, and keep alternating until the game ends.
```

## Project Structure

```
teinum-tictactoe/
  rebar.config                     # Build config (thoas JSON dependency)
  .mcp.json                        # Shared MCP server config
  .claude/agents/
    player-x.md                    # Player X subagent
    player-o.md                    # Player O subagent
  src/
    teinum_tictactoe.app.src       # OTP application descriptor
    teinum_tictactoe.erl           # Escript entry point
    teinum_tictactoe_app.erl       # Application behaviour
    teinum_tictactoe_sup.erl       # Supervisor
    ttt_game.erl                   # Game state gen_server
    ttt_tools.erl                  # MCP tool definitions and execution
    ttt_mcp.erl                    # JSON-RPC / MCP protocol dispatch
    ttt_stdio.erl                  # Stdio read/write loop
```
