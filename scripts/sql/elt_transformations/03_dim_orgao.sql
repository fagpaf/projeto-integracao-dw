-- DIM_ORGAO: hierarquia administrativa desnormalizada (unidade gestora, órgão
-- e órgão superior). Chave natural = os 3 códigos. Se a mesma combinação de
-- códigos tiver nomes diferentes entre registros, a UNIQUE da tabela e a
-- conferência da seção de validação do notebook acusam o problema.

DELETE FROM DIM_ORGAO;

INSERT INTO DIM_ORGAO (
    id_orgao, codigo_unidade_gestora, nome_unidade_gestora,
    codigo_orgao, nome_orgao, codigo_orgao_superior, nome_orgao_superior
)
SELECT
    ROW_NUMBER() OVER (ORDER BY codigo_unidade_gestora, codigo_orgao, codigo_orgao_superior) AS id_orgao,
    codigo_unidade_gestora, nome_unidade_gestora,
    codigo_orgao, nome_orgao, codigo_orgao_superior, nome_orgao_superior
FROM (
    SELECT DISTINCT
        codigo_unidade_gestora, nome_unidade_gestora,
        codigo_orgao, nome_orgao, codigo_orgao_superior, nome_orgao_superior
    FROM stg_cpgf_transacoes
);
