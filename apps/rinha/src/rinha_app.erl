%%%-------------------------------------------------------------------
%% @doc rinha public API
%% @end
%%%-------------------------------------------------------------------

-module(rinha_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_Type, _Args) ->
    application:ensure_all_started(pgo, db),
    {ok, Porta} = application:get_env(rinha, porta),
    io:format("~p~n", [Porta]),
    Dispatch = cowboy_router:compile([
        %% {HostMatchm list({PatchMatch, Constraints, Handler, InitialState})}
        {'_', [
	       {"/", opa, #{}},
	       {"/clientes/:id/transacoes", [{id, int}], transacoes, #{}},
	       {"/clientes/:id/extrato", [{id, int}], extrato, #{}}
	      ]
	}
    ]),

    persistent_term:put(erlang_rinher_dispatch, Dispatch),
    {ok, _} = cowboy:start_clear(erlang_rinher, [Porta],
        #{env => #{dispatch => {persistent_term, erlang_rinher_dispatch}}}
    ),

    %application:set_env(pg_types, timestamp_config, integer_system_time_seconds),
    rinha_sup:start_link().


stop(_State) ->
    ok = cowboy:stop_listener(erlang_rinher).

%% internal functions
