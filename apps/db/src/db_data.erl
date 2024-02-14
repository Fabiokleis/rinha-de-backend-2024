-module(db_data).

-export([obtem_cliente/1]).
-export([obtem_transacoes/1]).
-export([salva_transacao/2]).

obtem_cliente(Id) ->
    pgo:query("select id, saldo, limite from clientes where id=$1", [Id]).

obtem_transacoes(Id) ->
    pgo:query("select valor, tipo, descricao, realizada_em from transacoes where cliente_id=$1 order by id desc limit 10", [Id]).
    
salva_transacao(Id, {Valor, <<"c">>, Descricao}) ->
    pgo:transaction(fun() -> 
      pgo:query("select transacao_credito($1, 'c', $2, $3)", [Id, Valor, Descricao])
    end);

salva_transacao(Id, {Valor, <<"d">>, Descricao}) ->
    pgo:transaction(fun() -> 
      pgo:query("select transacao_debito($1, 'd', $2, $3)", [Id, Valor, Descricao])
    end).
