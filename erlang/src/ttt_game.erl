-module(ttt_game).
-behaviour(gen_server).

-export([start_link/0, new_game/0, make_move/2, get_board/0, get_status/0]).
-export([init/1, handle_call/3, handle_cast/2]).

-record(state, {
    board :: tuple(),
    turn :: x | o,
    status :: in_progress | {winner, x | o} | draw
}).

%% API

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

new_game() ->
    gen_server:call(?MODULE, new_game).

make_move(Player, Position) ->
    gen_server:call(?MODULE, {make_move, Player, Position}).

get_board() ->
    gen_server:call(?MODULE, get_board).

get_status() ->
    gen_server:call(?MODULE, get_status).

%% gen_server callbacks

init([]) ->
    {ok, fresh_state()}.

handle_call(new_game, _From, _State) ->
    New = fresh_state(),
    {reply, {ok, board_to_list(New#state.board)}, New};

handle_call({make_move, Player, Position}, _From, State) ->
    case validate_move(Player, Position, State) of
        ok ->
            Board1 = setelement(Position, State#state.board, Player),
            Status = check_status(Board1),
            NextTurn = case Player of x -> o; o -> x end,
            New = State#state{board = Board1, turn = NextTurn, status = Status},
            {reply, {ok, board_to_list(Board1), Status}, New};
        {error, Reason} ->
            {reply, {error, Reason}, State}
    end;

handle_call(get_board, _From, State) ->
    {reply, {ok, board_to_list(State#state.board)}, State};

handle_call(get_status, _From, State) ->
    {reply, {ok, State#state.status, State#state.turn}, State};

handle_call(_Request, _From, State) ->
    {reply, {error, unknown_request}, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

%% Internal

fresh_state() ->
    #state{
        board = {empty, empty, empty, empty, empty, empty, empty, empty, empty},
        turn = x,
        status = in_progress
    }.

board_to_list(Board) ->
    tuple_to_list(Board).

validate_move(Player, Position, State) ->
    if
        State#state.status =/= in_progress ->
            {error, game_over};
        Position < 1 orelse Position > 9 ->
            {error, invalid_position};
        Player =/= x andalso Player =/= o ->
            {error, invalid_player};
        Player =/= State#state.turn ->
            {error, not_your_turn};
        element(Position, State#state.board) =/= empty ->
            {error, position_occupied};
        true ->
            ok
    end.

check_status(Board) ->
    Lines = [
        {1,2,3}, {4,5,6}, {7,8,9},  % rows
        {1,4,7}, {2,5,8}, {3,6,9},  % columns
        {1,5,9}, {3,5,7}            % diagonals
    ],
    case check_winner(Board, Lines) of
        {winner, W} -> {winner, W};
        none ->
            case lists:any(fun(I) -> element(I, Board) =:= empty end, lists:seq(1, 9)) of
                true -> in_progress;
                false -> draw
            end
    end.

check_winner(_Board, []) ->
    none;
check_winner(Board, [{A, B, C} | Rest]) ->
    VA = element(A, Board),
    VB = element(B, Board),
    VC = element(C, Board),
    case VA =/= empty andalso VA =:= VB andalso VB =:= VC of
        true -> {winner, VA};
        false -> check_winner(Board, Rest)
    end.
