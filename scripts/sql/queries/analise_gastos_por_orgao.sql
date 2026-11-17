-- Analise anual dos gastos por orgao superior (2023 a 2025). Os valores sao separados por moeda: BRL e USD para compras/saques, "Nao informada" para transacoes sigilosas. Os percentuais representam quantidade de transacoes, nao valor monetario, pois a moeda das transacoes sigilosas nao esta identificada na fonte.

WITH gastos_por_orgao AS (
    SELECT
        t.ano,
        o.codigo_orgao_superior,
        o.nome_orgao_superior,

        SUM(CASE
            WHEN tt.categoria IN ('Compra', 'Saque')
             AND tt.moeda = 'BRL'
            THEN f.valor_transacao ELSE 0
        END) AS valor_aberto_brl,

        SUM(CASE
            WHEN tt.categoria IN ('Compra', 'Saque')
             AND tt.moeda = 'USD'
            THEN f.valor_transacao ELSE 0
        END) AS valor_aberto_usd,

        SUM(CASE
            WHEN tt.categoria = 'Sigiloso'
            THEN f.valor_transacao ELSE 0
        END) AS valor_sigiloso_moeda_nao_informada,

        SUM(CASE
            WHEN tt.categoria = 'Outros'
            THEN f.valor_transacao ELSE 0
        END) AS valor_nao_classificado_moeda_nao_aplicavel,

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

    ROUND(valor_aberto_brl, 2) AS valor_aberto_brl,
    ROUND(valor_aberto_usd, 2) AS valor_aberto_usd,
    ROUND(valor_sigiloso_moeda_nao_informada, 2)
        AS valor_sigiloso_moeda_nao_informada,
    ROUND(valor_nao_classificado_moeda_nao_aplicavel, 2)
        AS valor_nao_classificado_moeda_nao_aplicavel,

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


-- Ranking dos 10 maiores orgaos superiores em cada grupo monetario no periodo de 2023 a 2025. BRL e USD consideram compras/saques, "Nao informada" considera sigilosos. Os rankings sao separados para nao somar moedas diferentes.

WITH gastos_por_orgao_moeda AS (
    SELECT
        o.codigo_orgao_superior,
        o.nome_orgao_superior,

        CASE
            WHEN tt.categoria = 'Sigiloso' THEN 'Nao informada'
            ELSE tt.moeda
        END AS moeda_analise,

        COUNT(*) AS quantidade_transacoes,
        SUM(f.valor_transacao) AS valor_total

    FROM FATO_TRANSACAO_CPGF f
    JOIN DIM_ORGAO o
        ON f.id_orgao = o.id_orgao
    JOIN DIM_TEMPO t
        ON f.id_mes_extrato = t.id_tempo
    JOIN DIM_TIPO_TRANSACAO tt
        ON f.id_tipo_transacao = tt.id_tipo_transacao

    WHERE t.ano BETWEEN 2023 AND 2025
      AND tt.categoria IN ('Compra', 'Saque', 'Sigiloso')

    GROUP BY
        o.codigo_orgao_superior,
        o.nome_orgao_superior,
        CASE
            WHEN tt.categoria = 'Sigiloso' THEN 'Nao informada'
            ELSE tt.moeda
        END
),

ranking AS (
    SELECT
        moeda_analise,
        codigo_orgao_superior,
        nome_orgao_superior,
        quantidade_transacoes,
        valor_total,

        ROW_NUMBER() OVER (
            PARTITION BY moeda_analise
            ORDER BY valor_total DESC
        ) AS posicao

    FROM gastos_por_orgao_moeda
)

SELECT
    moeda_analise,
    posicao,
    codigo_orgao_superior,
    nome_orgao_superior,
    quantidade_transacoes,
    ROUND(valor_total, 2) AS valor_total

FROM ranking
WHERE posicao <= 10
ORDER BY moeda_analise, posicao;
