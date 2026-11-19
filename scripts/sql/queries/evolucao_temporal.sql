-- Análise 1 — Evolução temporal e sazonalidade de gastos (CPGF 2023–2025)
--
-- Eixo de tempo: MÊS DO EXTRATO (id_mes_extrato), não a data da transação.
-- Motivo: transações sem data informada continuam incluídas pelo mês do extrato.
-- O período é fixado em 2023–2025; o script valida a presença dos 36 meses.
-- Esta é uma comparação descritiva, sem teste estatístico de sazonalidade.

-- name: mensal
-- Valor, quantidade, ticket médio e parcela sigilosa por mês de extrato.
SELECT
    t.ano,
    t.mes,
    t.nome_mes,
    COUNT(*)                                              AS qtd_transacoes,
    ROUND(SUM(f.valor_transacao), 2)                      AS valor_total,
    ROUND(AVG(f.valor_transacao), 2)                      AS ticket_medio,
    ROUND(100.0 * SUM(CASE WHEN f.id_data_transacao = -1 THEN f.valor_transacao ELSE 0 END)
          / NULLIF(SUM(f.valor_transacao), 0), 1)                    AS pct_valor_sigiloso
FROM FATO_TRANSACAO_CPGF AS f
JOIN DIM_MES_EXTRATO AS t
    ON t.id_mes_extrato = f.id_mes_extrato
WHERE t.ano BETWEEN 2023 AND 2025
GROUP BY t.ano, t.mes, t.nome_mes
ORDER BY t.ano, t.mes;

-- name: sazonalidade
-- Índice sazonal: valor do mês dividido pela média mensal do mesmo ano.
-- 1,00 = mês na média do ano; 1,50 = 50% acima da média.
WITH mensal AS (
    SELECT t.ano, t.mes, SUM(f.valor_transacao) AS valor_total
    FROM FATO_TRANSACAO_CPGF AS f
    JOIN DIM_MES_EXTRATO AS t
        ON t.id_mes_extrato = f.id_mes_extrato
    WHERE t.ano BETWEEN 2023 AND 2025
GROUP BY t.ano, t.mes
)
SELECT
    ano,
    mes,
    ROUND(1.0 * valor_total / NULLIF(AVG(valor_total) OVER (PARTITION BY ano), 0), 3) AS indice_sazonal
FROM mensal
ORDER BY ano, mes;

-- name: anual
-- Total por ano e variação sobre o ano anterior.
WITH anual AS (
    SELECT t.ano,
           COUNT(*)                         AS qtd_transacoes,
           SUM(f.valor_transacao)           AS valor_total
    FROM FATO_TRANSACAO_CPGF AS f
    JOIN DIM_MES_EXTRATO AS t 
        ON t.id_mes_extrato = f.id_mes_extrato
    WHERE t.ano BETWEEN 2023 AND 2025
GROUP BY t.ano
)
SELECT
    ano,
    qtd_transacoes,
    ROUND(1.0 * valor_total / NULLIF(qtd_transacoes, 0), 2) AS ticket_medio,
    ROUND(valor_total, 2)                                            AS valor_total,
    ROUND(100.0 * (1.0 * valor_total / NULLIF(LAG(valor_total) OVER (ORDER BY ano), 0) - 1), 1)
                                                                     AS var_valor_pct,
    ROUND(100.0 * (1.0 * qtd_transacoes / NULLIF(LAG(qtd_transacoes) OVER (ORDER BY ano), 0) - 1), 1)
                                                                     AS var_qtd_pct
FROM anual
ORDER BY ano;
