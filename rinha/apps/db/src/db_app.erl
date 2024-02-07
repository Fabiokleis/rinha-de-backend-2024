%%%-------------------------------------------------------------------
%% @doc db public API
%% @end
%%%-------------------------------------------------------------------

-module(db_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    Val = application:get_env(db, pools, []),
    io:format("~p~n", [Val]),
    {Name, PoolConfig} = hd(Val),
    db_sup:start_link([Name, PoolConfig]).

stop(_State) ->
    ok.

%% internal functions
