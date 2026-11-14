-- DIM_TEMPO: calendário completo, usado tanto pra data da transação quanto
-- pro mês do extrato. Cobre anos completos, incluindo o ano anterior quando
-- a transação cair em dezembro do ano anterior ao extrato de janeiro.
-- O membro -1 é "Não Informado / Sigiloso".

DELETE FROM DIM_TEMPO;

WITH RECURSIVE
limites AS (
    SELECT
        MIN(2023, COALESCE((SELECT MIN(CAST(SUBSTR(data_original, 7, 4) AS INTEGER))
                             FROM stg_cpgf_transacoes WHERE id_data_transacao <> -1), 2023)) AS ano_inicio,
        MAX(2025, COALESCE((SELECT MAX(CAST(SUBSTR(data_original, 7, 4) AS INTEGER))
                             FROM stg_cpgf_transacoes WHERE id_data_transacao <> -1), 2025)) AS ano_fim
),
calendario(d) AS (
    SELECT DATE(ano_inicio || '-01-01') FROM limites
    UNION ALL
    SELECT DATE(d, '+1 day') FROM calendario, limites WHERE d < DATE(ano_fim || '-12-31')
)
INSERT INTO DIM_TEMPO (id_tempo, data, dia, mes, nome_mes, trimestre, semestre, ano, dia_semana, fim_de_semana)
SELECT -1, NULL, NULL, NULL, 'Não Informado / Sigiloso', NULL, NULL, NULL, 'Não Informado', NULL
UNION ALL
SELECT
    CAST(STRFTIME('%Y%m%d', d) AS INTEGER) AS id_tempo,
    d AS data,
    CAST(STRFTIME('%d', d) AS INTEGER) AS dia,
    CAST(STRFTIME('%m', d) AS INTEGER) AS mes,
    CASE STRFTIME('%m', d)
        WHEN '01' THEN 'Janeiro' WHEN '02' THEN 'Fevereiro' WHEN '03' THEN 'Março'
        WHEN '04' THEN 'Abril'   WHEN '05' THEN 'Maio'      WHEN '06' THEN 'Junho'
        WHEN '07' THEN 'Julho'   WHEN '08' THEN 'Agosto'     WHEN '09' THEN 'Setembro'
        WHEN '10' THEN 'Outubro' WHEN '11' THEN 'Novembro'   WHEN '12' THEN 'Dezembro'
    END AS nome_mes,
    (CAST(STRFTIME('%m', d) AS INTEGER) - 1) / 3 + 1 AS trimestre,
    (CAST(STRFTIME('%m', d) AS INTEGER) - 1) / 6 + 1 AS semestre,
    CAST(STRFTIME('%Y', d) AS INTEGER) AS ano,
    -- STRFTIME('%w', d): 0 = domingo ... 6 = sábado.
    CASE STRFTIME('%w', d)
        WHEN '1' THEN 'Segunda-feira' WHEN '2' THEN 'Terça-feira'
        WHEN '3' THEN 'Quarta-feira'  WHEN '4' THEN 'Quinta-feira'
        WHEN '5' THEN 'Sexta-feira'   WHEN '6' THEN 'Sábado'
        WHEN '0' THEN 'Domingo'
    END AS dia_semana,
    CASE WHEN STRFTIME('%w', d) IN ('0', '6') THEN 1 ELSE 0 END AS fim_de_semana
FROM calendario;
