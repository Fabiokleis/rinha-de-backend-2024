-module(extrato).
-behavior(cowboy_handler).

-export([init/2]).

gera_transacao({Valor, Tipo, Descricao, Data}) ->
    #{
      <<"valor">> => Valor,
      <<"tipo">> => Tipo,
      <<"descricao">> => Descricao,
      <<"realizada_em">> => iso8601:format(Data)
     }.

formt_resp({Limite, Total}, Info) ->
    jiffy:encode(
      #{ 
	<<"saldo">> => #{<<"total">> => Total, <<"data_extrato">> => iso8601:format(calendar:universal_time()), <<"limite">> => Limite},
	<<"ultimas_transacoes">> => [gera_transacao(Transacao) || Transacao <- Info] 
       }
     ).

manda_extrato(Req, Saldo, Info) ->
    {ok, cowboy_req:reply(200, #{<<"content-type">> => <<"application/json">>}, formt_resp(Saldo, Info), Req)}.

gera_saldo(Id) ->
    case db_data:obtem_saldo(Id, {limite}) of
	#{rows := [Saldo]} -> {saldo, Saldo};  
	_ -> banco
    end.

init(Req0=#{method := <<"GET">>}, State) ->	    
    Id = cowboy_req:binding(id, Req0),
    case db_data:obtem_transacoes(Id) of
	#{rows := []} -> {ok, cowboy_req:reply(404, Req0), State};
	#{rows := Info} -> 
	    case gera_saldo(Id) of
		{saldo, Saldo} -> manda_extrato(Req0, Saldo, Info);
		banco -> {ok, cowboy_req:reply(500, Req0), State} 
	    end;
	_ -> {ok, cowboy_req:reply(500, Req0), State} 
    end.

%%init(Req, State) ->
%%    io:format("Req: ~p~nState: ~p~n", [Req, State]),
%%    {ok, Req, State}.
