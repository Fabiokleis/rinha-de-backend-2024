-module(api_app).
-behaviour(application).

-export([start/2]).
-export([stop/1]).

start(_Type, _Args) ->
    Dispatch = cowboy_router:compile([
        {'_', [{"/", hello_handler, []}]}
    ]),
    {ok, _} = cowboy:start_clear(erlang_rinher,
        [{port, 6969}],
        #{env => #{dispatch => Dispatch}}
    ),
    api_sup:start_link().


stop(_State) ->
    ok = cowboy:stop_listener(erlang_rinher).
