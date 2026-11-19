-- Recorte 2023–2025. INT$ indica exterior, não USD. Ver docs/interpretacao-moedas-cpgf.md.
-- Valores somados em centavos; grupos de operação não equivalem a moedas confirmadas.

WITH gastos_por_orgao AS (
    SELECT
        t.ano,
        o.codigo_orgao_superior,
        o.nome_orgao_superior,

        SUM(CASE
            WHEN tt.categoria IN ('Compra', 'Saque')
             AND (CASE WHEN tt.descricao_original LIKE '%INT$%' THEN 'Exterior (INT$)' WHEN tt.descricao_original LIKE '%R$%' OR tt.descricao_original = 'SAQUE CASH/ATM BB' THEN 'R$/ATM' ELSE 'Sem identificação' END) = 'R$/ATM'
            THEN CAST(ROUND(f.valor_transacao * 100) AS INTEGER) ELSE 0
        END) / 100.0 AS valor_aberto_rs_atm,

        SUM(CASE
            WHEN tt.categoria IN ('Compra', 'Saque')
             AND (CASE WHEN tt.descricao_original LIKE '%INT$%' THEN 'Exterior (INT$)' WHEN tt.descricao_original LIKE '%R$%' OR tt.descricao_original = 'SAQUE CASH/ATM BB' THEN 'R$/ATM' ELSE 'Sem identificação' END) = 'Exterior (INT$)'
            THEN CAST(ROUND(f.valor_transacao * 100) AS INTEGER) ELSE 0
        END) / 100.0 AS valor_aberto_exterior,

        SUM(CASE
            WHEN tt.categoria = 'Sigiloso'
            THEN CAST(ROUND(f.valor_transacao * 100) AS INTEGER) ELSE 0
        END) / 100.0 AS valor_sigiloso,

        SUM(CASE
            WHEN tt.categoria = 'Outros'
            THEN CAST(ROUND(f.valor_transacao * 100) AS INTEGER) ELSE 0
        END) / 100.0 AS valor_nao_classificado,

        COUNT(*) AS quantidade_total_transacoes,

        SUM(CASE
            WHEN tt.categoria IN ('Compra', 'Saque')
            THEN 1 ELSE 0
        END) AS quantidade_transacoes_abertas,

        SUM(CASE
            WHEN tt.categoria = 'Sigiloso'
            THEN 1 ELSE 0
        END) AS quantidade_transacoes_sigilosas,

        SUM(CASE
            WHEN tt.categoria = 'Outros'
            THEN 1 ELSE 0
        END) AS quantidade_transacoes_nao_classificadas

    FROM FATO_TRANSACAO_CPGF f
    JOIN DIM_ORGAO o
        ON f.id_orgao = o.id_orgao
    JOIN DIM_MES_EXTRATO t
        ON f.id_mes_extrato = t.id_mes_extrato
    JOIN DIM_TIPO_TRANSACAO tt
        ON f.id_tipo_transacao = tt.id_tipo_transacao

    WHERE t.ano BETWEEN 2023 AND 2025

    GROUP BY
        t.ano,
        o.codigo_orgao_superior,
        o.nome_orgao_superior
)

SELECT
    ano,
    codigo_orgao_superior,
    nome_orgao_superior,

    ROUND(valor_aberto_rs_atm, 2) AS valor_aberto_rs_atm,
    ROUND(valor_aberto_exterior, 2) AS valor_aberto_exterior,
    ROUND(valor_sigiloso, 2)
        AS valor_sigiloso,
    ROUND(valor_nao_classificado, 2)
        AS valor_nao_classificado,

    quantidade_total_transacoes,
    quantidade_transacoes_abertas,
    quantidade_transacoes_sigilosas,
    quantidade_transacoes_nao_classificadas,

    ROUND(
        100.0 * quantidade_transacoes_abertas
        / NULLIF(quantidade_total_transacoes, 0), 2
    ) AS percentual_transacoes_abertas,

    ROUND(
        100.0 * quantidade_transacoes_sigilosas
        / NULLIF(quantidade_total_transacoes, 0), 2
    ) AS percentual_transacoes_sigilosas,

    ROUND(
        100.0 * quantidade_transacoes_nao_classificadas
        / NULLIF(quantidade_total_transacoes, 0), 2
    ) AS percentual_transacoes_nao_classificadas

FROM gastos_por_orgao
ORDER BY ano, nome_orgao_superior;



WITH gastos_por_orgao_moeda AS (
    SELECT
        o.codigo_orgao_superior,
        o.nome_orgao_superior,

        CASE
            WHEN tt.categoria = 'Sigiloso' THEN 'Nao informada'
            ELSE (CASE WHEN tt.descricao_original LIKE '%INT$%' THEN 'Exterior (INT$)' WHEN tt.descricao_original LIKE '%R$%' OR tt.descricao_original = 'SAQUE CASH/ATM BB' THEN 'R$/ATM' ELSE 'Sem identificação' END)
        END AS grupo_operacao,

        COUNT(*) AS quantidade_transacoes,
        SUM(CAST(ROUND(f.valor_transacao * 100) AS INTEGER)) / 100.0 AS valor_total

    FROM FATO_TRANSACAO_CPGF f
    JOIN DIM_ORGAO o
        ON f.id_orgao = o.id_orgao
    JOIN DIM_MES_EXTRATO t
        ON f.id_mes_extrato = t.id_mes_extrato
    JOIN DIM_TIPO_TRANSACAO tt
        ON f.id_tipo_transacao = tt.id_tipo_transacao

    WHERE t.ano BETWEEN 2023 AND 2025
      AND tt.categoria IN ('Compra', 'Saque', 'Sigiloso')

    GROUP BY
        o.codigo_orgao_superior,
        o.nome_orgao_superior,
        CASE
            WHEN tt.categoria = 'Sigiloso' THEN 'Nao informada'
            ELSE (CASE WHEN tt.descricao_original LIKE '%INT$%' THEN 'Exterior (INT$)' WHEN tt.descricao_original LIKE '%R$%' OR tt.descricao_original = 'SAQUE CASH/ATM BB' THEN 'R$/ATM' ELSE 'Sem identificação' END)
        END
),

ranking AS (
    SELECT
        grupo_operacao,
        codigo_orgao_superior,
        nome_orgao_superior,
        quantidade_transacoes,
        valor_total,

        ROW_NUMBER() OVER (
            PARTITION BY grupo_operacao
            ORDER BY valor_total DESC
        ) AS posicao

    FROM gastos_por_orgao_moeda
)

SELECT
    grupo_operacao,
    posicao,
    codigo_orgao_superior,
    nome_orgao_superior,
    quantidade_transacoes,
    ROUND(valor_total, 2) AS valor_total

FROM ranking
WHERE posicao <= 10
ORDER BY grupo_operacao, posicao;
