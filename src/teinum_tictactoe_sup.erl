-module(teinum_tictactoe_sup).
-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    Children = [
        #{id => ttt_game,
          start => {ttt_game, start_link, []},
          restart => permanent,
          type => worker}
    ],
    {ok, {#{strategy => one_for_one, intensity => 5, period => 10}, Children}}.
