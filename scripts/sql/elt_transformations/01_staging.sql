-- Unifica os 3 anos de Raw numa tabela de staging só, já com strings limpas
-- (TRIM), nomes de negócio e as colunas derivadas que os outros scripts
-- reaproveitam (datas, valor em centavos, sigilo, portador especial).
-- Nenhuma linha é descartada ou deduplicada.

-- Esvazia a fato antes de qualquer dimensão: como ela referencia as
-- dimensões por FK, isso evita violar chave estrangeira ao reexecutar.
DELETE FROM FATO_TRANSACAO_CPGF;

DROP TABLE IF EXISTS stg_cpgf_transacoes;

CREATE TABLE stg_cpgf_transacoes (
    arquivo_origem          TEXT    NOT NULL,
    codigo_orgao_superior   TEXT    NOT NULL CHECK (codigo_orgao_superior <> ''),
    nome_orgao_superior     TEXT    NOT NULL CHECK (nome_orgao_superior <> ''),
    codigo_orgao            TEXT    NOT NULL CHECK (codigo_orgao <> ''),
    nome_orgao              TEXT    NOT NULL CHECK (nome_orgao <> ''),
    codigo_unidade_gestora  TEXT    NOT NULL CHECK (codigo_unidade_gestora <> ''),
    nome_unidade_gestora    TEXT    NOT NULL CHECK (nome_unidade_gestora <> ''),
    ano_extrato             TEXT    NOT NULL CHECK (ano_extrato GLOB '[0-9][0-9][0-9][0-9]'),
    mes_extrato             TEXT    NOT NULL CHECK (mes_extrato GLOB '[0-9][0-9]'),
    cpf_mascarado           TEXT    NOT NULL,
    nome_portador           TEXT    NOT NULL,
    documento               TEXT    NOT NULL CHECK (documento <> ''),
    nome_favorecido         TEXT    NOT NULL CHECK (nome_favorecido <> ''),
    descricao_original      TEXT    NOT NULL CHECK (descricao_original <> ''),
    data_original           TEXT    NOT NULL
        CHECK (data_original = '' OR data_original GLOB '[0-9][0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9]'),
    valor_original          TEXT    NOT NULL
        -- "1.234,56" ou "-1.234,56"; não confere se os grupos de milhar têm
        -- exatamente 3 dígitos (regex completa não compensa em SQL puro).
        CHECK (valor_original GLOB '[0-9]*,[0-9][0-9]' OR valor_original GLOB '-[0-9]*,[0-9][0-9]')
        CHECK (REPLACE(REPLACE(REPLACE(valor_original, '.', ''), ',', ''), '-', '') NOT GLOB '*[^0-9]*'),
    -- Colunas derivadas, calculadas uma única vez e reaproveitadas pelas dimensões/fato:
    valor_centavos          INTEGER NOT NULL,
    sigilosa                INTEGER NOT NULL CHECK (sigilosa IN (0, 1)),
    portador_especial       INTEGER NOT NULL CHECK (portador_especial IN (0, 1)),
    id_data_transacao       INTEGER NOT NULL,
    id_mes_extrato          INTEGER NOT NULL
);

INSERT INTO stg_cpgf_transacoes (
    arquivo_origem, codigo_orgao_superior, nome_orgao_superior, codigo_orgao, nome_orgao,
    codigo_unidade_gestora, nome_unidade_gestora, ano_extrato, mes_extrato,
    cpf_mascarado, nome_portador, documento, nome_favorecido,
    descricao_original, data_original, valor_original,
    valor_centavos, sigilosa, portador_especial, id_data_transacao, id_mes_extrato
)
WITH brutos AS (
    SELECT 'raw_cpgf_2023' AS arquivo_origem,
           TRIM("CÓDIGO ÓRGÃO SUPERIOR")   AS codigo_orgao_superior,
           TRIM("NOME ÓRGÃO SUPERIOR")     AS nome_orgao_superior,
           TRIM("CÓDIGO ÓRGÃO")            AS codigo_orgao,
           TRIM("NOME ÓRGÃO")              AS nome_orgao,
           TRIM("CÓDIGO UNIDADE GESTORA")  AS codigo_unidade_gestora,
           TRIM("NOME UNIDADE GESTORA")    AS nome_unidade_gestora,
           TRIM("ANO EXTRATO")             AS ano_extrato,
           TRIM("MÊS EXTRATO")             AS mes_extrato,
           TRIM("CPF PORTADOR")            AS cpf_mascarado,
           TRIM("NOME PORTADOR")           AS nome_portador,
           TRIM("CNPJ OU CPF FAVORECIDO")  AS documento,
           TRIM("NOME FAVORECIDO")         AS nome_favorecido,
           TRIM("TRANSAÇÃO")               AS descricao_original,
           TRIM("DATA TRANSAÇÃO")          AS data_original,
           TRIM("VALOR TRANSAÇÃO")         AS valor_original
    FROM raw_cpgf_2023
    UNION ALL
    SELECT 'raw_cpgf_2024', TRIM("CÓDIGO ÓRGÃO SUPERIOR"), TRIM("NOME ÓRGÃO SUPERIOR"),
           TRIM("CÓDIGO ÓRGÃO"), TRIM("NOME ÓRGÃO"), TRIM("CÓDIGO UNIDADE GESTORA"),
           TRIM("NOME UNIDADE GESTORA"), TRIM("ANO EXTRATO"), TRIM("MÊS EXTRATO"),
           TRIM("CPF PORTADOR"), TRIM("NOME PORTADOR"), TRIM("CNPJ OU CPF FAVORECIDO"),
           TRIM("NOME FAVORECIDO"), TRIM("TRANSAÇÃO"), TRIM("DATA TRANSAÇÃO"), TRIM("VALOR TRANSAÇÃO")
    FROM raw_cpgf_2024
    UNION ALL
    SELECT 'raw_cpgf_2025', TRIM("CÓDIGO ÓRGÃO SUPERIOR"), TRIM("NOME ÓRGÃO SUPERIOR"),
           TRIM("CÓDIGO ÓRGÃO"), TRIM("NOME ÓRGÃO"), TRIM("CÓDIGO UNIDADE GESTORA"),
           TRIM("NOME UNIDADE GESTORA"), TRIM("ANO EXTRATO"), TRIM("MÊS EXTRATO"),
           TRIM("CPF PORTADOR"), TRIM("NOME PORTADOR"), TRIM("CNPJ OU CPF FAVORECIDO"),
           TRIM("NOME FAVORECIDO"), TRIM("TRANSAÇÃO"), TRIM("DATA TRANSAÇÃO"), TRIM("VALOR TRANSAÇÃO")
    FROM raw_cpgf_2025
),
-- Marcadores administrativos exatos de sigilo (não é uma busca por substring).
marcados AS (
    SELECT *,
           (LOWER(descricao_original) IN ('sigiloso', 'informações protegidas por sigilo')
            OR LOWER(nome_portador)   IN ('sigiloso', 'informações protegidas por sigilo')
            OR LOWER(nome_favorecido) IN ('sigiloso', 'informações protegidas por sigilo')
            OR documento = '-11') AS sigilosa
    FROM brutos
)
SELECT
    arquivo_origem, codigo_orgao_superior, nome_orgao_superior, codigo_orgao, nome_orgao,
    codigo_unidade_gestora, nome_unidade_gestora, ano_extrato, mes_extrato,
    cpf_mascarado, nome_portador, documento, nome_favorecido,
    descricao_original, data_original, valor_original,
    -- tira o separador de milhar e a vírgula, sobra o inteiro em centavos.
    CAST(REPLACE(REPLACE(valor_original, '.', ''), ',', '') AS INTEGER) AS valor_centavos,
    sigilosa,
    -- portador_especial: sigiloso OU com CPF e nome ambos ausentes.
    (sigilosa OR (cpf_mascarado = '' AND nome_portador = '')) AS portador_especial,
    -- id_data_transacao: dd/mm/aaaa -> YYYYMMDD; sigilosa ou vazia -> -1.
    CASE WHEN sigilosa OR data_original = '' THEN -1
         ELSE CAST(
             SUBSTR(data_original, 7, 4) || SUBSTR(data_original, 4, 2) || SUBSTR(data_original, 1, 2)
         AS INTEGER)
    END AS id_data_transacao,
    -- id_mes_extrato: ano e mês do extrato (YYYYMM).
    CAST(ano_extrato AS INTEGER) * 100 + CAST(mes_extrato AS INTEGER) AS id_mes_extrato
FROM marcados;
