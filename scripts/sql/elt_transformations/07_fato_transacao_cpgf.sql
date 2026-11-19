-- FATO_TRANSACAO_CPGF: 1 linha por transação, associada às 5 dimensões pela
-- chave natural. Nenhuma linha de stg_cpgf_transacoes é perdida ou duplicada:
-- se alguma transação não encontrar membro em uma dimensão, o INSERT falha
-- (NOT NULL), equivalente ao validate='many_to_one' do ETL em pandas.

INSERT INTO FATO_TRANSACAO_CPGF (
    id_data_transacao, id_mes_extrato, id_orgao, id_portador,
    id_favorecido, id_tipo_transacao, valor_transacao
)
SELECT
    s.id_data_transacao,
    s.id_mes_extrato,
    o.id_orgao,
    CASE WHEN s.portador_especial THEN -1 ELSE p.id_portador END AS id_portador,
    f.id_favorecido,
    t.id_tipo_transacao,
    s.valor_centavos / 100.0 AS valor_transacao
FROM stg_cpgf_transacoes AS s
JOIN DIM_ORGAO AS o
    ON o.codigo_unidade_gestora = s.codigo_unidade_gestora
   AND o.codigo_orgao           = s.codigo_orgao
   AND o.codigo_orgao_superior  = s.codigo_orgao_superior
LEFT JOIN DIM_PORTADOR AS p
    ON s.portador_especial = 0
   AND p.cpf_mascarado = s.cpf_mascarado
   AND p.nome_portador = s.nome_portador
JOIN DIM_FAVORECIDO AS f
    ON f.documento = s.documento
   AND f.nome_favorecido = s.nome_favorecido
JOIN DIM_TIPO_TRANSACAO AS t
    ON t.descricao_original = s.descricao_original
ORDER BY s.arquivo_origem, s.rowid;
