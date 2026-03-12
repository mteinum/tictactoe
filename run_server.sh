#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVER="${TTT_SERVER:-elixir}"

case "$SERVER" in
  erlang)
    exec escript "$SCRIPT_DIR/erlang/_build/default/bin/teinum_tictactoe" "$@"
    ;;
  elixir)
    exec "$SCRIPT_DIR/elixir/teinum_tictactoe_ex" "$@"
    ;;
  *)
    echo "Unknown server: $SERVER. Use TTT_SERVER=erlang or TTT_SERVER=elixir" >&2
    exit 1
    ;;
esac
