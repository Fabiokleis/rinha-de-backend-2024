-module(opa).
-behavior(cowboy_handler).

-export([init/2]).

init(Req, State) ->
    {ok, cowboy_req:reply(200, Req), State}.
