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

salva_transacao(Id, Transacao) ->
    case catch db_data:salva_transacao(Id, Transacao) of
	#{rows := [{{Id, <<"nao_encontrado">>}}]} -> nao_encontrou;
	#{rows := [{{Id, <<"inconsistente">>}}]} -> inconsistente;
	#{rows := [{{Saldo, Limite}}]} -> {salvo, {Saldo, Limite}};
	{error, none_available} -> banco
    end.

faz_transacao(Id, [Body]) ->
    case Body of
	{Info, true} -> 
	    case valida_transacao(Info) of
		{transacao, T} -> salva_transacao(Id, T);
		invalido -> invalido
	    end;
	{_, false} -> vazio
    end.

init(Req0=#{method := <<"POST">>, headers := #{<<"content-type">> := <<"application/json">>}}, State) ->
    {ok, Body, Req} = cowboy_req:read_urlencoded_body(Req0),
    case faz_transacao(cowboy_req:binding(id, Req), Body) of
	{salvo, Json} -> {ok, cowboy_req:reply(200, #{<<"content-type">> => <<"application/json">>}, formt_resp(Json), Req)};
	nao_encontrou -> {ok, cowboy_req:reply(404, Req0), State};
	inconsistente -> {ok, cowboy_req:reply(422, Req0), State};
	invalido -> {ok, cowboy_req:reply(422, Req0), State};
	vazio -> {ok, cowboy_req:reply(422, Req0), State};
	banco -> {ok, cowboy_req:reply(500, Req0), State}
    end;

init(Req, State) ->
    {ok, cowboy_req:reply(404, Req), State}.

