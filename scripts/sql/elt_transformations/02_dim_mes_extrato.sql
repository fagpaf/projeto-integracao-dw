-- Doze meses para cada ano de extrato presente na origem.
-- Não armazena dia nem atributos diários.
DELETE FROM DIM_MES_EXTRATO;

WITH RECURSIVE meses(mes) AS (
    SELECT 1
    UNION ALL
    SELECT mes + 1
    FROM meses
    WHERE mes < 12
),
anos AS (
    SELECT DISTINCT CAST(ano_extrato AS INTEGER) AS ano
    FROM stg_cpgf_transacoes
)
INSERT INTO DIM_MES_EXTRATO (
    id_mes_extrato, ano, mes, nome_mes, trimestre, semestre
)
SELECT
    ano * 100 + mes,
    ano,
    mes,
    CASE mes
        WHEN 1 THEN 'Janeiro'
        WHEN 2 THEN 'Fevereiro'
        WHEN 3 THEN 'Março'
        WHEN 4 THEN 'Abril'
        WHEN 5 THEN 'Maio'
        WHEN 6 THEN 'Junho'
        WHEN 7 THEN 'Julho'
        WHEN 8 THEN 'Agosto'
        WHEN 9 THEN 'Setembro'
        WHEN 10 THEN 'Outubro'
        WHEN 11 THEN 'Novembro'
        WHEN 12 THEN 'Dezembro'
    END,
    (mes - 1) / 3 + 1,
    (mes - 1) / 6 + 1
FROM anos CROSS JOIN meses
ORDER BY ano, mes;