-module(transacoes).
-behavior(cowboy_handler).

-export([init/2]).

-define(BYTES_DESC, 10).

%% Requisição
%% POST /clientes/[id]/transacoes
%% {
%%     "valor": 1000,
%%     "tipo" : "c",
%%     "descricao" : "descricao"
%% }

%% Resposta - HTTP 200 OK
%% {
%%    "limite" : 100000,
%%    "saldo" : -9098
%% }

formt_resp({Saldo, Limite}) ->
    jiffy:encode(#{<<"saldo">> => Saldo, <<"limite">> => Limite}).


valida_transacao(Limite,
 #{<<"valor">> := Valor, <<"tipo">> := Tipo, <<"descricao">> := Descricao}) 
  when 
      is_integer(Valor) andalso Valor > 0
      andalso bit_size(Descricao) =< (8 * ?BYTES_DESC)
      andalso (Tipo =:= <<"c">> orelse (Tipo =:= <<"d">> andalso Limite >= Valor)) ->
    {transacao, {Valor, Tipo, Descricao}};

valida_transacao(Limite, Info) ->
    case catch jiffy:decode(Info, [return_maps]) of
       {'EXIT', _} -> invalido;
       MapTransacao -> valida_transacao(Limite, MapTransacao)
    end.

salva_transacao(Id, Limite, {_, <<"c">>, _} = T) ->
    case db_data:salva_transacao(Id, T) of
	#{rows := [{Saldo}]} -> {salvo, formt_resp({Saldo, Limite})};
	_ -> inconsistente
    end;

salva_transacao(Id, Limite, {Valor, <<"d">>, _} = T) ->
    case db_data:obtem_saldo(Id) of
	#{rows := [{Saldo}]} -> 
	    if (Saldo - Valor) >= -Limite ->
		    case db_data:salva_transacao(Id, T) of
			#{rows := [{NovoSaldo}]} -> {salvo, formt_resp({NovoSaldo, Limite})};
			_ -> inconsistente
		    end;
	       true -> inconsistente
	    end;
	_ -> inconsistente
    end.

faz_transacao({Id, _, Limite}, [Body]) ->
    case Body of
	{Info, true} -> 
	    case valida_transacao(Limite, Info) of
		{transacao, T} -> salva_transacao(Id, Limite, T);
		invalido -> invalido
	    end;
	{_, false} -> vazio
    end.

init(Req0=#{method := <<"POST">>}, State) ->
    case db_data:obtem_cliente(cowboy_req:binding(id, Req0)) of
	#{rows := [Cliente]} -> 
	    {ok, Body, Req} = cowboy_req:read_urlencoded_body(Req0),
	    case faz_transacao(Cliente, Body) of
		{salvo, Json} -> 
		    io:format("~p~n", [Json]),
		    {ok, cowboy_req:reply(200, #{<<"content-type">> => <<"application/json">>}, Json, Req)};
		vazio -> 
		    io:format("req vazio~n"),
		    {ok, cowboy_req:reply(404, Req), State};
		invalido -> 
		    io:format("transacao invalida~n"),
		    {ok, cowboy_req:reply(404, Req), State};
		inconsistente -> 
		    io:format("transacao inconsistente~n"),
		    {ok, cowboy_req:reply(422, Req), State}
            end;
	_ -> {ok, cowboy_req:reply(404, Req0), State}
    end;

init(Req, State) ->
    io:format("Req: ~p~nState: ~p~n", [Req, State]),
    {ok, Req, State}.

