defmodule TeinumTictactoeEx.Tools do
  alias TeinumTictactoeEx.Game

  def list do
    [
      %{
        "name" => "new_game",
        "description" => "Start a new tic tac toe game. Resets the board. X always goes first.",
        "inputSchema" => %{"type" => "object", "properties" => %{}}
      },
      %{
        "name" => "make_move",
        "description" => "Make a move on the tic tac toe board.",
        "inputSchema" => %{
          "type" => "object",
          "properties" => %{
            "player" => %{
              "type" => "string",
              "description" => "Player making the move: X or O",
              "enum" => ["X", "O"]
            },
            "position" => %{
              "type" => "integer",
              "description" => "Board position (1-9)",
              "minimum" => 1,
              "maximum" => 9
            }
          },
          "required" => ["player", "position"]
        }
      },
      %{
        "name" => "get_board",
        "description" => "Get the current board state as a visual grid.",
        "inputSchema" => %{"type" => "object", "properties" => %{}}
      },
      %{
        "name" => "get_status",
        "description" => "Get the current game status: in_progress, winner (X or O), or draw.",
        "inputSchema" => %{"type" => "object", "properties" => %{}}
      }
    ]
  end

  def call("new_game", _args) do
    {:ok, board} = Game.new_game()
    text_result("New game started! X goes first.\n\n#{format_board(board)}")
  end

  def call("make_move", args) do
    player = parse_player(args["player"])
    position = args["position"]

    case {player, position} do
      {:error, _} ->
        error_result("Invalid player. Must be X or O.")

      {p, pos} when is_integer(pos) ->
        case Game.make_move(p, pos) do
          {:ok, board, status} ->
            text_result("#{format_board(board)}\n\n#{format_status(status)}")

          {:error, reason} ->
            error_result(format_error(reason))
        end

      _ ->
        error_result("Invalid position. Must be an integer 1-9.")
    end
  end

  def call("get_board", _args) do
    {:ok, board} = Game.get_board()
    text_result(format_board(board))
  end

  def call("get_status", _args) do
    {:ok, status, turn} = Game.get_status()

    msg =
      case status do
        :in_progress ->
          turn_str = turn |> Atom.to_string() |> String.upcase()
          "Game in progress. #{turn_str}'s turn."

        {:winner, player} ->
          player_str = player |> Atom.to_string() |> String.upcase()
          "#{player_str} wins!"

        :draw ->
          "It's a draw!"
      end

    text_result(msg)
  end

  def call(_name, _args) do
    error_result("Unknown tool.")
  end

  # Helpers

  defp parse_player(p) when p in ["X", "x"], do: :x
  defp parse_player(p) when p in ["O", "o"], do: :o
  defp parse_player(_), do: :error

  defp text_result(text) do
    %{"content" => [%{"type" => "text", "text" => text}]}
  end

  defp error_result(text) do
    %{"content" => [%{"type" => "text", "text" => text}], "isError" => true}
  end

  defp format_board(board) do
    board
    |> Enum.with_index(1)
    |> Enum.map(fn
      {:empty, i} -> " #{i} "
      {:x, _} -> " X "
      {:o, _} -> " O "
    end)
    |> Enum.chunk_every(3)
    |> Enum.map(&Enum.join(&1, "|"))
    |> Enum.join("\n---+---+---\n")
  end

  defp format_status(:in_progress), do: "Game in progress."
  defp format_status({:winner, :x}), do: "X wins!"
  defp format_status({:winner, :o}), do: "O wins!"
  defp format_status(:draw), do: "It's a draw!"

  defp format_error(:game_over), do: "Game is already over."
  defp format_error(:invalid_position), do: "Invalid position. Must be 1-9."
  defp format_error(:invalid_player), do: "Invalid player. Must be X or O."
  defp format_error(:not_your_turn), do: "Not your turn."
  defp format_error(:position_occupied), do: "Position already occupied."
end
