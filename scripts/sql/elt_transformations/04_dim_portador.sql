-- DIM_PORTADOR: servidor responsável pelo cartão. Chave natural = (cpf
-- mascarado, nome do portador); CPF mascarado isoladamente pode se repetir
-- entre pessoas distintas. O membro -1 cobre portadores sigilosos ou com
-- CPF e nome ambos ausentes fora do sigilo.

DELETE FROM DIM_PORTADOR;

INSERT INTO DIM_PORTADOR (id_portador, cpf_mascarado, nome_portador)
SELECT -1, 'SIGILOSO', 'Portador Sigiloso / Não Identificado'
UNION ALL
SELECT
    ROW_NUMBER() OVER (ORDER BY cpf_mascarado, nome_portador) AS id_portador,
    cpf_mascarado, nome_portador
FROM (
    SELECT DISTINCT cpf_mascarado, nome_portador
    FROM stg_cpgf_transacoes
    WHERE portador_especial = 0
);
