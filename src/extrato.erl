-module(extrato).
-behavior(cowboy_handler).

-export([init/2]).

init(Req0=#{method := <<"GET">>}, State) ->
    Id = cowboy_req:binding(id, Req0),
    io:format("Req: ~p~nState: ~p~n", [Req0, State]),
    Req = cowboy_req:reply(200, #{<<"content-type">> => <<"text/plain">>}, <<"Hello, World!">>, Req0),
    {ok, Req, State};

init(Req, State) ->
    io:format("Req: ~p~nState: ~p~n", [Req, State]),
    {ok, Req, State}.

