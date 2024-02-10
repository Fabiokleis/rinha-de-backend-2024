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

valida_transacao(#{<<"tipo">> := Tipo}) 
  when Tipo =/= <<"c">> andalso Tipo =/= <<"d">> -> invalido;

valida_transacao(#{<<"valor">> := Valor}) 
  when not is_integer(Valor) orelse Valor =< 0 -> invalido;

valida_transacao(#{<<"descricao">> := Descricao}) 
  when 
      not is_bitstring(Descricao) orelse
      bit_size(Descricao) =< 0 orelse
      bit_size(Descricao) > (8 * (?BYTES_DESC)) -> invalido;

valida_transacao(#{<<"valor">> := Valor, <<"tipo">> := Tipo, <<"descricao">> := Descricao}) ->
    {transacao, {Valor, Tipo, Descricao}};

valida_transacao(Info) ->
    case catch jiffy:decode(Info, [return_maps]) of
       {'EXIT', _} -> invalido;
       Transacao -> valida_transacao(Transacao)
    end.

salva_transacao(Id, Limite, {_, <<"c">>, _} = T) ->
    case db_data:salva_transacao(Id, T) of
	#{rows := [{Saldo}]} -> {salvo, {Saldo, Limite}};
	_ -> banco
    end;

salva_transacao(Id, Limite, {Valor, <<"d">>, _} = T) ->
    case db_data:obtem_saldo(Id) of
	#{rows := [{Saldo}]} -> 
	    if (Saldo - Valor) >= (-1 * Limite) ->
		    case db_data:salva_transacao(Id, T) of
			#{rows := [{NovoSaldo}]} -> {salvo, {NovoSaldo, Limite}};
			_ -> banco
		    end;
	       true -> inconsistente
	    end;
	_ -> banco
    end.

faz_transacao({Id, _, Limite}, [Body]) ->
    case Body of
	{Info, true} -> 
	    case valida_transacao(Info) of
		{transacao, T} -> salva_transacao(Id, Limite, T);
		invalido -> invalido
	    end;
	{_, false} -> vazio
    end.

init(Req0=#{method := <<"POST">>, headers := #{<<"content-type">> := <<"application/json">>}}, State) ->
    case db_data:obtem_cliente(cowboy_req:binding(id, Req0)) of
	#{rows := [Cliente]} -> 
	    {ok, Body, Req} = cowboy_req:read_urlencoded_body(Req0),
	    case faz_transacao(Cliente, Body) of
		{salvo, Json} -> 
		    {ok, cowboy_req:reply(200, #{<<"content-type">> => <<"application/json">>}, formt_resp(Json), Req)};
		vazio -> 
		    %%io:format("req vazio~n"),
		    {ok, cowboy_req:reply(422, Req), State};
		invalido -> 
		    io:format("transacao invalida~n"),
		    {ok, cowboy_req:reply(422, Req), State};
		inconsistente -> 
		    %%io:format("transacao inconsistente~n"),
		    {ok, cowboy_req:reply(422, Req), State};
	        banco ->
		    {ok, cowboy_req:reply(500, Req), State}
            end;
	#{rows := []} -> {ok, cowboy_req:reply(404, Req0), State};
	_ -> {ok, cowboy_req:reply(404, Req0), State}
    end;

init(Req, State) ->
    {ok, cowboy_req:reply(404, Req), State}.

