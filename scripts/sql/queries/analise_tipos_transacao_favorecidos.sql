-- Recorte 2023–2025. INT$ indica exterior, não USD. Ver docs/interpretacao-moedas-cpgf.md.
-- Valores somados em centavos; grupos de operação não equivalem a moedas confirmadas.

SELECT
    tt.categoria,
    tt.canal,
    (CASE WHEN tt.descricao_original LIKE '%INT$%' THEN 'Exterior (INT$)' WHEN tt.descricao_original LIKE '%R$%' OR tt.descricao_original = 'SAQUE CASH/ATM BB' THEN 'R$/ATM' ELSE 'Sem identificação' END) AS grupo_operacao,
    COUNT(*) AS quantidade_transacoes,
    ROUND(SUM(CAST(ROUND(f.valor_transacao * 100) AS INTEGER)) / 100.0, 2) AS valor_total

FROM FATO_TRANSACAO_CPGF f

JOIN DIM_TIPO_TRANSACAO tt
    ON f.id_tipo_transacao = tt.id_tipo_transacao

WHERE tt.categoria IN ('Compra', 'Saque')
  AND f.id_mes_extrato IN (
    SELECT id_mes_extrato
    FROM DIM_MES_EXTRATO
    WHERE ano BETWEEN 2023 AND 2025
)

GROUP BY
    tt.categoria,
    tt.canal,
    (CASE WHEN tt.descricao_original LIKE '%INT$%' THEN 'Exterior (INT$)' WHEN tt.descricao_original LIKE '%R$%' OR tt.descricao_original = 'SAQUE CASH/ATM BB' THEN 'R$/ATM' ELSE 'Sem identificação' END)

ORDER BY
    (CASE WHEN tt.descricao_original LIKE '%INT$%' THEN 'Exterior (INT$)' WHEN tt.descricao_original LIKE '%R$%' OR tt.descricao_original = 'SAQUE CASH/ATM BB' THEN 'R$/ATM' ELSE 'Sem identificação' END),
    tt.categoria;


WITH gastos_por_favorecido AS (
    SELECT
        fav.id_favorecido,
        fav.nome_favorecido,
        fav.tipo_pessoa,
        (CASE WHEN tt.descricao_original LIKE '%INT$%' THEN 'Exterior (INT$)' WHEN tt.descricao_original LIKE '%R$%' OR tt.descricao_original = 'SAQUE CASH/ATM BB' THEN 'R$/ATM' ELSE 'Sem identificação' END) AS grupo_operacao,

        COUNT(*) AS quantidade_transacoes,

        SUM(CAST(ROUND(f.valor_transacao * 100) AS INTEGER)) / 100.0 AS valor_total

    FROM FATO_TRANSACAO_CPGF f

    JOIN DIM_FAVORECIDO fav
        ON f.id_favorecido = fav.id_favorecido

    JOIN DIM_TIPO_TRANSACAO tt
        ON f.id_tipo_transacao = tt.id_tipo_transacao

    WHERE tt.categoria IN ('Compra', 'Saque')
    AND f.id_mes_extrato IN (
        SELECT id_mes_extrato
        FROM DIM_MES_EXTRATO
        WHERE ano BETWEEN 2023 AND 2025
    )
      AND fav.tipo_pessoa IN ('PJ', 'PF')
      AND (CASE WHEN tt.descricao_original LIKE '%INT$%' THEN 'Exterior (INT$)' WHEN tt.descricao_original LIKE '%R$%' OR tt.descricao_original = 'SAQUE CASH/ATM BB' THEN 'R$/ATM' ELSE 'Sem identificação' END) = 'R$/ATM'

    GROUP BY
        fav.id_favorecido,
        fav.nome_favorecido,
        fav.tipo_pessoa,
        (CASE WHEN tt.descricao_original LIKE '%INT$%' THEN 'Exterior (INT$)' WHEN tt.descricao_original LIKE '%R$%' OR tt.descricao_original = 'SAQUE CASH/ATM BB' THEN 'R$/ATM' ELSE 'Sem identificação' END)
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

SELECT
    (CASE WHEN tt.descricao_original LIKE '%INT$%' THEN 'Exterior (INT$)' WHEN tt.descricao_original LIKE '%R$%' OR tt.descricao_original = 'SAQUE CASH/ATM BB' THEN 'R$/ATM' ELSE 'Sem identificação' END) AS grupo_operacao,
    fav.tipo_pessoa,

    COUNT(*) AS quantidade_transacoes,

    ROUND(
        SUM(CAST(ROUND(f.valor_transacao * 100) AS INTEGER)) / 100.0,
        2
    ) AS valor_total

FROM FATO_TRANSACAO_CPGF f

JOIN DIM_FAVORECIDO fav
    ON f.id_favorecido = fav.id_favorecido

JOIN DIM_TIPO_TRANSACAO tt
    ON f.id_tipo_transacao = tt.id_tipo_transacao

WHERE tt.categoria IN ('Compra', 'Saque')
  AND f.id_mes_extrato IN (
    SELECT id_mes_extrato
    FROM DIM_MES_EXTRATO
    WHERE ano BETWEEN 2023 AND 2025
  )

GROUP BY
    (CASE WHEN tt.descricao_original LIKE '%INT$%' THEN 'Exterior (INT$)' WHEN tt.descricao_original LIKE '%R$%' OR tt.descricao_original = 'SAQUE CASH/ATM BB' THEN 'R$/ATM' ELSE 'Sem identificação' END),
    fav.tipo_pessoa

ORDER BY
    (CASE WHEN tt.descricao_original LIKE '%INT$%' THEN 'Exterior (INT$)' WHEN tt.descricao_original LIKE '%R$%' OR tt.descricao_original = 'SAQUE CASH/ATM BB' THEN 'R$/ATM' ELSE 'Sem identificação' END),
    fav.tipo_pessoa;
