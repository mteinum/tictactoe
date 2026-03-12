-module(teinum_tictactoe_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    teinum_tictactoe_sup:start_link().

stop(_State) ->
    ok.
