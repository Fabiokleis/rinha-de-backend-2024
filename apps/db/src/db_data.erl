-module(db_data).

-export([obtem_cliente/1]).
-export([obtem_saldo/1, obtem_saldo/2]).
-export([salva_transacao/2]).
-export([obtem_transacoes/1]).

obtem_cliente(Id) ->
    pgo:query("select * from clientes where id=$1", [Id]).

obtem_saldo(Id) ->
    pgo:query("select valor from saldos where cliente_id=$1", [Id]).

obtem_saldo(Id, {limite}) ->
    pgo:query("select limite, valor from clientes inner join saldos on saldos.cliente_id = clientes.id where clientes.id=$1", [Id]).

salva_transacao(Id, {Valor, <<"c">>, Descricao}) ->
    pgo:transaction(fun () -> 
         pgo:query("insert into transacoes (id, cliente_id, valor, tipo, descricao, realizada_em) values (default, $1, $2, 'c', $3, now())", [Id, Valor, Descricao]),
	 pgo:query("update saldos set valor = valor + $2 where cliente_id=$1 returning valor", [Id, Valor])
    end);
    
salva_transacao(Id, {Valor, <<"d">>, Descricao}) ->
    pgo:transaction(fun () -> 
        pgo:query("insert into transacoes (id, cliente_id, valor, tipo, descricao, realizada_em) values (default, $1, $2, 'd', $3, now())", [Id, Valor, Descricao]),			  
        pgo:query("update saldos set valor = valor + $2 where cliente_id=$1 returning valor", [Id, -Valor])
    end).

obtem_transacoes(Id) ->
    pgo:query("select valor, tipo, descricao, realizada_em from transacoes where cliente_id=$1 order by id desc limit 10", [Id]).
