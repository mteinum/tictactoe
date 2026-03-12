defmodule TeinumTictactoeEx.Game do
  use GenServer

  defstruct board: List.duplicate(:empty, 9),
            turn: :x,
            status: :in_progress

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, Keyword.merge([name: __MODULE__], opts))
  end

  def new_game do
    GenServer.call(__MODULE__, :new_game)
  end

  def make_move(player, position) do
    GenServer.call(__MODULE__, {:make_move, player, position})
  end

  def get_board do
    GenServer.call(__MODULE__, :get_board)
  end

  def get_status do
    GenServer.call(__MODULE__, :get_status)
  end

  # Server callbacks

  @impl true
  def init(:ok) do
    {:ok, %__MODULE__{}}
  end

  @impl true
  def handle_call(:new_game, _from, _state) do
    state = %__MODULE__{}
    {:reply, {:ok, state.board}, state}
  end

  def handle_call({:make_move, player, position}, _from, state) do
    case validate_move(state, player, position) do
      :ok ->
        board = List.replace_at(state.board, position - 1, player)
        status = check_status(board)
        next_turn = if player == :x, do: :o, else: :x
        new_state = %__MODULE__{board: board, turn: next_turn, status: status}
        {:reply, {:ok, board, status}, new_state}

      {:error, _} = error ->
        {:reply, error, state}
    end
  end

  def handle_call(:get_board, _from, state) do
    {:reply, {:ok, state.board}, state}
  end

  def handle_call(:get_status, _from, state) do
    {:reply, {:ok, state.status, state.turn}, state}
  end

  # Validation

  defp validate_move(state, player, position) do
    cond do
      state.status != :in_progress -> {:error, :game_over}
      position not in 1..9 -> {:error, :invalid_position}
      player not in [:x, :o] -> {:error, :invalid_player}
      player != state.turn -> {:error, :not_your_turn}
      Enum.at(state.board, position - 1) != :empty -> {:error, :position_occupied}
      true -> :ok
    end
  end

  # Win detection

  @win_lines [
    {0, 1, 2}, {3, 4, 5}, {6, 7, 8},
    {0, 3, 6}, {1, 4, 7}, {2, 5, 8},
    {0, 4, 8}, {2, 4, 6}
  ]

  defp check_status(board) do
    case check_winner(board) do
      {:winner, _} = result -> result
      nil ->
        if Enum.any?(board, &(&1 == :empty)),
          do: :in_progress,
          else: :draw
    end
  end

  defp check_winner(board) do
    Enum.find_value(@win_lines, fn {a, b, c} ->
      va = Enum.at(board, a)
      vb = Enum.at(board, b)
      vc = Enum.at(board, c)

      if va != :empty and va == vb and vb == vc do
        {:winner, va}
      end
    end)
  end
end
