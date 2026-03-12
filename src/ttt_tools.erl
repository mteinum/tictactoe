-module(ttt_tools).

-export([list/0, call/2]).

list() ->
    [
        #{<<"name">> => <<"new_game">>,
          <<"description">> => <<"Start a new tic tac toe game. Resets the board. X always goes first.">>,
          <<"inputSchema">> => #{<<"type">> => <<"object">>, <<"properties">> => #{}}},

        #{<<"name">> => <<"make_move">>,
          <<"description">> => <<"Make a move on the tic tac toe board.">>,
          <<"inputSchema">> => #{
              <<"type">> => <<"object">>,
              <<"properties">> => #{
                  <<"player">> => #{
                      <<"type">> => <<"string">>,
                      <<"description">> => <<"Player making the move: 'X' or 'O'">>,
                      <<"enum">> => [<<"X">>, <<"O">>]
                  },
                  <<"position">> => #{
                      <<"type">> => <<"integer">>,
                      <<"description">> => <<"Board position 1-9. Layout:\n 1 | 2 | 3\n---+---+---\n 4 | 5 | 6\n---+---+---\n 7 | 8 | 9">>
                  }
              },
              <<"required">> => [<<"player">>, <<"position">>]
          }},

        #{<<"name">> => <<"get_board">>,
          <<"description">> => <<"Get the current board state as a visual grid.">>,
          <<"inputSchema">> => #{<<"type">> => <<"object">>, <<"properties">> => #{}}},

        #{<<"name">> => <<"get_status">>,
          <<"description">> => <<"Get the current game status: in_progress, winner (X or O), or draw.">>,
          <<"inputSchema">> => #{<<"type">> => <<"object">>, <<"properties">> => #{}}}
    ].

call(<<"new_game">>, _Args) ->
    {ok, Board} = ttt_game:new_game(),
    text_result(iolist_to_binary([
        <<"New game started! X goes first.\n\n">>,
        format_board(Board)
    ]));

call(<<"make_move">>, Args) ->
    Player = parse_player(maps:get(<<"player">>, Args, undefined)),
    Position = maps:get(<<"position">>, Args, undefined),
    case {Player, Position} of
        {error, _} ->
            error_result(<<"Invalid player. Must be 'X' or 'O'.">>);
        {_, undefined} ->
            error_result(<<"Missing 'position' argument.">>);
        {_, P} when not is_integer(P) ->
            error_result(<<"Position must be an integer 1-9.">>);
        {Pl, Pos} ->
            case ttt_game:make_move(Pl, Pos) of
                {ok, Board, Status} ->
                    text_result(iolist_to_binary([
                        format_board(Board),
                        <<"\n">>,
                        format_status(Status)
                    ]));
                {error, Reason} ->
                    error_result(format_error(Reason))
            end
    end;

call(<<"get_board">>, _Args) ->
    {ok, Board} = ttt_game:get_board(),
    text_result(iolist_to_binary(format_board(Board)));

call(<<"get_status">>, _Args) ->
    {ok, Status, Turn} = ttt_game:get_status(),
    Msg = case Status of
        in_progress ->
            iolist_to_binary([<<"Game in progress. ">>, atom_to_upper(Turn), <<"'s turn.">>]);
        _ ->
            format_status(Status)
    end,
    text_result(Msg);

call(_Unknown, _Args) ->
    error_result(<<"Unknown tool.">>).

%% Internal helpers

parse_player(<<"X">>) -> x;
parse_player(<<"x">>) -> x;
parse_player(<<"O">>) -> o;
parse_player(<<"o">>) -> o;
parse_player(_) -> error.

text_result(Text) ->
    #{<<"content">> => [#{<<"type">> => <<"text">>, <<"text">> => Text}]}.

error_result(Text) ->
    #{<<"content">> => [#{<<"type">> => <<"text">>, <<"text">> => Text}],
      <<"isError">> => true}.

format_board(Board) ->
    Cells = [cell_char(C, I) || {C, I} <- lists:zip(Board, lists:seq(1, 9))],
    [R1, R2, R3, R4, R5, R6, R7, R8, R9] = Cells,
    iolist_to_binary([
        <<" ">>, R1, <<" | ">>, R2, <<" | ">>, R3, <<"\n">>,
        <<"---+---+---\n">>,
        <<" ">>, R4, <<" | ">>, R5, <<" | ">>, R6, <<"\n">>,
        <<"---+---+---\n">>,
        <<" ">>, R7, <<" | ">>, R8, <<" | ">>, R9
    ]).

cell_char(empty, I) -> integer_to_binary(I);
cell_char(x, _) -> <<"X">>;
cell_char(o, _) -> <<"O">>.

atom_to_upper(x) -> <<"X">>;
atom_to_upper(o) -> <<"O">>.

format_status(in_progress) -> <<"Game in progress.">>;
format_status({winner, x}) -> <<"X wins!">>;
format_status({winner, o}) -> <<"O wins!">>;
format_status(draw) -> <<"It's a draw!">>.

format_error(game_over) -> <<"Game is already over.">>;
format_error(invalid_position) -> <<"Invalid position. Must be 1-9.">>;
format_error(invalid_player) -> <<"Invalid player. Must be X or O.">>;
format_error(not_your_turn) -> <<"Not your turn.">>;
format_error(position_occupied) -> <<"That position is already taken.">>;
format_error(Other) -> iolist_to_binary(io_lib:format("Error: ~p", [Other])).
