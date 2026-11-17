
-- Analise da proporcao de gastos abertos, sigilosos e nao classificados por orgao superior e ano (2023 a 2025). Os valores representam os registros originais, sem conversao de moeda.

WITH gastos_por_orgao AS (
    SELECT
        t.ano,
        o.codigo_orgao_superior,
        o.nome_orgao_superior,

        SUM(CASE
            WHEN tt.categoria IN ('Compra', 'Saque')
            THEN f.valor_transacao ELSE 0
        END) AS valor_aberto,

        SUM(CASE
            WHEN tt.categoria = 'Sigiloso'
            THEN f.valor_transacao ELSE 0
        END) AS valor_sigiloso,

        SUM(CASE
            WHEN tt.categoria = 'Outros'
            THEN f.valor_transacao ELSE 0
        END) AS valor_nao_classificado,

        SUM(f.valor_transacao) AS valor_total

    FROM FATO_TRANSACAO_CPGF f
    JOIN DIM_ORGAO o
        ON f.id_orgao = o.id_orgao
    JOIN DIM_TEMPO t
        ON f.id_mes_extrato = t.id_tempo
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
    ROUND(valor_aberto, 2) AS valor_aberto,
    ROUND(valor_sigiloso, 2) AS valor_sigiloso,
    ROUND(valor_nao_classificado, 2) AS valor_nao_classificado,
    ROUND(valor_total, 2) AS valor_total,

    ROUND(100.0 * valor_aberto / NULLIF(valor_total, 0), 2)
        AS percentual_aberto,

    ROUND(100.0 * valor_sigiloso / NULLIF(valor_total, 0), 2)
        AS percentual_sigiloso,

    ROUND(100.0 * valor_nao_classificado / NULLIF(valor_total, 0), 2)
        AS percentual_nao_classificado

FROM gastos_por_orgao

ORDER BY ano, valor_total DESC;

-- Ranking dos 10 orgaos superiores com maior gasto acumulado entre 2023 e 2025, incluindo a proporcao de gastos sigilosos. Valores sem conversao de moeda.

WITH gastos_acumulados AS (
    SELECT
        o.codigo_orgao_superior,
        o.nome_orgao_superior,

        SUM(CASE
            WHEN tt.categoria IN ('Compra', 'Saque')
            THEN f.valor_transacao ELSE 0
        END) AS valor_aberto,

        SUM(CASE
            WHEN tt.categoria = 'Sigiloso'
            THEN f.valor_transacao ELSE 0
        END) AS valor_sigiloso,

        SUM(CASE
            WHEN tt.categoria = 'Outros'
            THEN f.valor_transacao ELSE 0
        END) AS valor_nao_classificado,

        SUM(f.valor_transacao) AS valor_total

    FROM FATO_TRANSACAO_CPGF f
    JOIN DIM_ORGAO o
        ON f.id_orgao = o.id_orgao
    JOIN DIM_TEMPO t
        ON f.id_mes_extrato = t.id_tempo
    JOIN DIM_TIPO_TRANSACAO tt
        ON f.id_tipo_transacao = tt.id_tipo_transacao

    WHERE t.ano BETWEEN 2023 AND 2025

    GROUP BY
        o.codigo_orgao_superior,
        o.nome_orgao_superior
)

SELECT
    codigo_orgao_superior,
    nome_orgao_superior,
    ROUND(valor_aberto, 2) AS valor_aberto,
    ROUND(valor_sigiloso, 2) AS valor_sigiloso,
    ROUND(valor_nao_classificado, 2) AS valor_nao_classificado,
    ROUND(valor_total, 2) AS valor_total,

    ROUND(100.0 * valor_aberto / NULLIF(valor_total, 0), 2)
        AS percentual_aberto,

    ROUND(100.0 * valor_sigiloso / NULLIF(valor_total, 0), 2)
        AS percentual_sigiloso

FROM gastos_acumulados

ORDER BY valor_total DESC
LIMIT 10;