-- Comparacao entre compras e saques por moeda

SELECT
    tt.categoria,
    tt.canal,
    tt.moeda,
    COUNT(*) AS quantidade_transacoes,
    ROUND(SUM(f.valor_transacao), 2) AS valor_total

FROM FATO_TRANSACAO_CPGF f

JOIN DIM_TIPO_TRANSACAO tt
    ON f.id_tipo_transacao = tt.id_tipo_transacao

WHERE tt.categoria IN ('Compra', 'Saque')

GROUP BY
    tt.categoria,
    tt.canal,
    tt.moeda

ORDER BY
    tt.moeda,
    tt.categoria;

-- Ranking dos 10 maiores favorecidos em BRL. Considera apenas pessoas fisicas e juridicas identificadas.

WITH gastos_por_favorecido AS (
    SELECT
        fav.id_favorecido,
        fav.nome_favorecido,
        fav.tipo_pessoa,
        tt.moeda,

        COUNT(*) AS quantidade_transacoes,

        SUM(f.valor_transacao) AS valor_total

    FROM FATO_TRANSACAO_CPGF f

    JOIN DIM_FAVORECIDO fav
        ON f.id_favorecido = fav.id_favorecido

    JOIN DIM_TIPO_TRANSACAO tt
        ON f.id_tipo_transacao = tt.id_tipo_transacao

    WHERE tt.categoria IN ('Compra', 'Saque')
      AND fav.tipo_pessoa IN ('PJ', 'PF')
      AND tt.moeda = 'BRL'

    GROUP BY
        fav.id_favorecido,
        fav.nome_favorecido,
        fav.tipo_pessoa,
        tt.moeda
),

concentracao AS (
    SELECT
        *,

        SUM(valor_total) OVER () AS total_identificado,

        ROW_NUMBER() OVER (
            ORDER BY valor_total DESC
        ) AS ranking

    FROM gastos_por_favorecido
)

SELECT
    ranking,
    nome_favorecido,
    tipo_pessoa,
    quantidade_transacoes,
    ROUND(valor_total, 2) AS valor_total,

    ROUND(
        100.0 * valor_total / NULLIF(total_identificado, 0),
        2
    ) AS percentual_do_total

FROM concentracao

WHERE ranking <= 10

ORDER BY ranking;

-- Distribuicao das transacoes por moeda e tipo de favorecido. 
SELECT
    tt.moeda,
    fav.tipo_pessoa,

    COUNT(*) AS quantidade_transacoes,

    ROUND(
        SUM(f.valor_transacao),
        2
    ) AS valor_total

FROM FATO_TRANSACAO_CPGF f

JOIN DIM_FAVORECIDO fav
    ON f.id_favorecido = fav.id_favorecido

JOIN DIM_TIPO_TRANSACAO tt
    ON f.id_tipo_transacao = tt.id_tipo_transacao

WHERE tt.categoria IN ('Compra', 'Saque')

GROUP BY
    tt.moeda,
    fav.tipo_pessoa

ORDER BY
    tt.moeda,
    fav.tipo_pessoa;