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

gera_saldo({Limite, Total}) ->
    #{     
     <<"total">> => Total,
     <<"data_extrato">> => iso8601:format(calendar:universal_time()),
     <<"limite">> => Limite
    }.

formt_resp(Saldo, []) ->
    jiffy:encode(#{<<"saldo">> => gera_saldo(Saldo)});

formt_resp(Saldo, Transacoes) ->
    jiffy:encode(
      #{ 
	<<"saldo">> => gera_saldo(Saldo),
	<<"ultimas_transacoes">> => [gera_transacao(Transacao) || Transacao <- Transacoes] 
       }
     ).

manda_extrato(Req, Saldo, Transacoes) ->
    {ok, 
     cowboy_req:reply(200, 
		      #{<<"content-type">> => <<"application/json">>},
		      formt_resp(Saldo, Transacoes), Req)}.

obtem_saldo(Id) ->
    case db_data:obtem_saldo(Id) of
	#{rows := [{Saldo}]} -> {saldo, Saldo};  
	_ -> banco
    end.

init(Req0=#{method := <<"GET">>}, State) ->	    
    case db_data:obtem_cliente(cowboy_req:binding(id, Req0)) of
	#{rows := []} -> {ok, cowboy_req:reply(404, Req0), State};
	#{rows := [{Id, _, Limite}]} -> 
	    case obtem_saldo(Id) of
		{saldo, Saldo} -> 
		    case db_data:obtem_transacoes(Id) of
			#{rows := Transacoes} -> manda_extrato(Req0, {Limite, Saldo}, Transacoes);
			_ -> {ok, cowboy_req:reply(500, Req0), State}
		    end;
		banco -> {ok, cowboy_req:reply(500, Req0), State}
	    end;
	_ -> {ok, cowboy_req:reply(404, Req0), State}
    end;


init(Req, State) ->
    io:format("Req: ~p~nState: ~p~n", [Req, State]),
    {ok, cowboy_req:reply(404, Req), State}.

