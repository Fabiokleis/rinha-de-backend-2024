-module(hello_handler).
-behavior(cowboy_handler).

-export([init/2]).

init(Req0=#{method := <<"GET">>}, State) ->
    io:format("Req: ~p~nState: ~p~n", [Req0, State]),
    Req = cowboy_req:reply(200, 
			   #{<<"content-type">> => <<"text/plain">>},
			    <<"Hello, World!">>, Req0),
    {ok, Req, State};
    
init(Req0, State) ->
    io:format("Req: ~p~nState: ~p~n", [Req0, State]),
    Req = cowboy_req:reply(405, #{<<"allow">> => <<"GET">>}, Req0),
    {ok, Req, State}.
