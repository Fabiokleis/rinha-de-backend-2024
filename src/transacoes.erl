-module(transacoes).
-behavior(cowboy_handler).

-export([init/2]).

init(Req0=#{method := <<"POST">>}, State) ->
    Id = cowboy_req:binding(id, Req0),
    {ok, Body, Req} = cowboy_req:read_urlencoded_body(Req0),
    io:format("req: ~p~nbody: ~p~n", [Req, Body]),

    Res = cowboy_req:reply(200, #{<<"content-type">> => <<"text/plain">>}, <<"Hello, World!">>, Req0),
    {ok, Res, State};

init(Req, State) ->
    io:format("Req: ~p~nState: ~p~n", [Req, State]),
    {ok, Req, State}.

