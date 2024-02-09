%%%-------------------------------------------------------------------
%% @doc db public API
%% @end
%%%-------------------------------------------------------------------

-module(db_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    application:ensure_all_started(pgo),
    [{Name, PoolConfig}] = application:get_env(db, pools, []),
    io:format("~p: ~p~n", [Name, PoolConfig]),
    db_sup:start_link([Name, PoolConfig]).

stop(_State) ->
    ok.

%% internal functions
