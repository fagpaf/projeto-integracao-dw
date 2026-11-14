-- DIM_FAVORECIDO: quem recebeu o pagamento. Chave natural = (documento,
-- nome_favorecido). tipo_pessoa vem do formato do documento, sem validar
-- se ele é real. Documento fora dos formatos previstos vira NULL aqui, o
-- que estoura o NOT NULL/CHECK da tabela e interrompe a carga.

DELETE FROM DIM_FAVORECIDO;

INSERT INTO DIM_FAVORECIDO (id_favorecido, documento, nome_favorecido, tipo_pessoa)
SELECT
    ROW_NUMBER() OVER (ORDER BY documento, nome_favorecido) AS id_favorecido,
    documento, nome_favorecido,
    CASE
        -- Códigos administrativos da fonte: membros regulares, não PF/PJ.
        WHEN documento IN ('-1', '-2', '-11') THEN 'Especial'
        -- CPF mascarado no padrão da LGPD: ***.XXX.XXX-**
        WHEN documento GLOB '[*][*][*].[0-9][0-9][0-9].[0-9][0-9][0-9]-[*][*]' THEN 'PF'
        WHEN digitos NOT GLOB '*[^0-9]*' AND LENGTH(digitos) = 14 THEN 'PJ'
        WHEN digitos NOT GLOB '*[^0-9]*' AND LENGTH(digitos) = 11 THEN 'PF'
        ELSE NULL
    END AS tipo_pessoa
FROM (
    SELECT DISTINCT documento, nome_favorecido,
           REPLACE(REPLACE(REPLACE(documento, '.', ''), '/', ''), '-', '') AS digitos
    FROM stg_cpgf_transacoes
);
