-module(api_app).
-behaviour(application).

-export([start/2]).
-export([stop/1]).

start(_Type, _Args) ->
    Dispatch = cowboy_router:compile([
        %% {HostMatchm list({PatchMatch, Constraints, Handler, InitialState})}
        {'_', [
	       {"/clientes/:id/transacoes", [{id, int}], transacoes, #{}},
	       {"/clientes/:id/extrato", [{id, int}], extrato, #{}}
	       %% {'_', hello_handler, #{}}
	      ]
	}
    ]),

    persistent_term:put(erlang_rinher_dispatch, Dispatch),
    {ok, _} = cowboy:start_clear(erlang_rinher, [{port, 6969}],
        #{env => #{dispatch => {persistent_term, erlang_rinher_dispatch}}}
    ),
    api_sup:start_link().


stop(_State) ->
    ok = cowboy:stop_listener(erlang_rinher).
