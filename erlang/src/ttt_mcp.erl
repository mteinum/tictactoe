-module(ttt_mcp).

-export([handle_message/1]).

handle_message(JsonBin) ->
    case thoas:decode(JsonBin) of
        {ok, Msg} ->
            dispatch(Msg);
        {error, _} ->
            {reply, encode(parse_error_response())}
    end.

dispatch(#{<<"method">> := <<"initialize">>, <<"id">> := Id} = Msg) ->
    _ClientVersion = maps:get(<<"protocolVersion">>,
                              maps:get(<<"params">>, Msg, #{}), <<"2025-03-26">>),
    Result = #{
        <<"protocolVersion">> => <<"2025-03-26">>,
        <<"capabilities">> => #{
            <<"tools">> => #{}
        },
        <<"serverInfo">> => #{
            <<"name">> => <<"teinum-tictactoe">>,
            <<"version">> => <<"0.1.0">>
        }
    },
    {reply, encode(success_response(Id, Result))};

dispatch(#{<<"method">> := <<"notifications/initialized">>}) ->
    noreply;

dispatch(#{<<"method">> := <<"ping">>, <<"id">> := Id}) ->
    {reply, encode(success_response(Id, #{}))};

dispatch(#{<<"method">> := <<"tools/list">>, <<"id">> := Id}) ->
    Result = #{<<"tools">> => ttt_tools:list()},
    {reply, encode(success_response(Id, Result))};

dispatch(#{<<"method">> := <<"tools/call">>, <<"id">> := Id, <<"params">> := Params}) ->
    Name = maps:get(<<"name">>, Params, <<>>),
    Args = maps:get(<<"arguments">>, Params, #{}),
    ToolResult = ttt_tools:call(Name, Args),
    {reply, encode(success_response(Id, ToolResult))};

dispatch(#{<<"method">> := _Method, <<"id">> := Id}) ->
    {reply, encode(error_response(Id, -32601, <<"Method not found">>))};

dispatch(#{<<"method">> := _Method}) ->
    % Notification without id — no response
    noreply;

dispatch(#{<<"id">> := Id}) ->
    {reply, encode(error_response(Id, -32600, <<"Invalid request">>))};

dispatch(_) ->
    noreply.

%% JSON-RPC helpers

success_response(Id, Result) ->
    #{<<"jsonrpc">> => <<"2.0">>, <<"id">> => Id, <<"result">> => Result}.

error_response(Id, Code, Message) ->
    #{<<"jsonrpc">> => <<"2.0">>, <<"id">> => Id,
      <<"error">> => #{<<"code">> => Code, <<"message">> => Message}}.

parse_error_response() ->
    #{<<"jsonrpc">> => <<"2.0">>, <<"id">> => null,
      <<"error">> => #{<<"code">> => -32700, <<"message">> => <<"Parse error">>}}.

encode(Map) ->
    thoas:encode(Map).
