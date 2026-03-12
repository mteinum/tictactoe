-module(ttt_stdio).

-export([main/1]).

main(_Args) ->
    try
        %% Redirect logger to stderr so stdout stays clean for JSON-RPC
        logger:set_handler_config(default, config, #{type => standard_error}),

        %% Start the game server directly (no OTP app in escript mode)
        {ok, _} = ttt_game:start_link(),

        %% Set stdin/stdout to binary mode
        io:setopts(standard_io, [binary]),

        %% Enter the read loop
        loop()
    catch
        Class:Reason:Stack ->
            io:format(standard_error, "CRASH: ~p:~p~n~p~n", [Class, Reason, Stack]),
            erlang:halt(1)
    end.

loop() ->
    case io:get_line(standard_io, <<>>) of
        eof ->
            erlang:halt(0);
        {error, _} ->
            erlang:halt(1);
        Line when is_binary(Line) ->
            Trimmed = string:trim(Line, trailing),
            handle_line(Trimmed),
            loop();
        Line when is_list(Line) ->
            Trimmed = string:trim(list_to_binary(Line), trailing),
            handle_line(Trimmed),
            loop()
    end.

handle_line(<<>>) ->
    ok;
handle_line(JsonBin) ->
    case ttt_mcp:handle_message(JsonBin) of
        noreply ->
            ok;
        {reply, ResponseIoData} ->
            ResponseBin = iolist_to_binary(ResponseIoData),
            io:put_chars(standard_io, [ResponseBin, $\n])
    end.
