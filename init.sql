CREATE TABLE clientes (
	id SERIAL PRIMARY KEY,
	saldo INTEGER NOT NULL,
	limite INTEGER NOT NULL
);

CREATE TABLE transacoes (
	id SERIAL PRIMARY KEY,
	cliente_id INTEGER NOT NULL,
	valor INTEGER NOT NULL,
	tipo CHAR(1) NOT NULL,
	descricao VARCHAR(10) NOT NULL,
	realizada_em TIMESTAMP NOT NULL DEFAULT NOW(),
	CONSTRAINT fk_clientes_transacoes_id
		FOREIGN KEY (cliente_id) REFERENCES clientes(id)
);

DO $$
BEGIN
        INSERT INTO clientes (saldo, limite)
        VALUES (0, 1000 * 100),
               (0, 800 * 100),
               (0, 10000 * 100),
               (0, 100000 * 100),
               (0, 5000 * 100);
END;
$$;

CREATE FUNCTION transacao_credito(
    id_cliente integer,
    tipo_salva char(1),
    valor_salva integer,
    descricao_salva varchar(10)
) RETURNS RECORD AS $$ 
DECLARE
    cliente clientes%ROWTYPE;
    retorno RECORD;
BEGIN
    SELECT * INTO cliente FROM clientes WHERE id = id_cliente;

    IF NOT FOUND THEN
       RETORNO := (id_cliente, 'nao_encontrado');
       RETURN retorno;
    END IF;

    UPDATE clientes
    SET saldo = saldo + valor_salva
    WHERE id = id_cliente
    RETURNING saldo, limite INTO retorno;

    INSERT INTO transacoes (id, cliente_id, valor, tipo, descricao, realizada_em)
    VALUES (DEFAULT, id_cliente, valor_salva, tipo_salva, descricao_salva, NOW());

    RETURN retorno;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION transacao_debito(
    id_cliente integer,
    tipo_salva char(1),
    valor_salva integer,
    descricao_salva varchar(10)
) RETURNS RECORD AS $$ 
DECLARE
   cliente clientes%ROWTYPE;
   retorno RECORD;
BEGIN
    SELECT * INTO cliente FROM clientes WHERE id = id_cliente;

    IF NOT FOUND THEN
        RETORNO := (id_cliente, 'nao_encontrado');
	RETURN retorno;
    END IF;

    IF (cliente.saldo - valor_salva) >= (-1 * cliente.limite) THEN
        UPDATE clientes
        SET saldo = saldo + valor_salva
        WHERE id = id_cliente
        RETURNING saldo, limite INTO retorno;
    ELSE
	RETORNO := (id_cliente, 'inconsistente');
	RETURN retorno;
    END IF;

    INSERT INTO transacoes (id, cliente_id, valor, tipo, descricao, realizada_em)
    VALUES (DEFAULT, id_cliente, valor_salva, tipo_salva, descricao_salva, NOW());

    RETURN retorno;
END;
$$ LANGUAGE plpgsql;
