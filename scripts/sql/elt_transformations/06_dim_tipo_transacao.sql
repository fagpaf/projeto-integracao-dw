-- DIM_TIPO_TRANSACAO: natureza, moeda e canal da operação. Descrições fora
-- do dicionário conhecido ficam em 'Outros' / 'Não Aplicável' / 'Outros' e
-- devem ser revisadas (não interrompem a carga).

DELETE FROM DIM_TIPO_TRANSACAO;

INSERT INTO DIM_TIPO_TRANSACAO (id_tipo_transacao, descricao_original, categoria, moeda, canal)
SELECT
    ROW_NUMBER() OVER (ORDER BY descricao_original) AS id_tipo_transacao,
    descricao_original,
    CASE descricao_original
        WHEN 'COMPRA A/V - R$ - APRES'            THEN 'Compra'
        WHEN 'COMPRA A/V - INT$ - APRES'          THEN 'Compra'
        WHEN 'SAQUE CASH/ATM BB'                  THEN 'Saque'
        WHEN 'SAQUE - R$ - APRES'                 THEN 'Saque'
        WHEN 'SAQUE - INT$ - APRES'               THEN 'Saque'
        WHEN 'Informações protegidas por sigilo'  THEN 'Sigiloso'
        ELSE 'Outros'
    END AS categoria,
    CASE descricao_original
        WHEN 'COMPRA A/V - R$ - APRES'            THEN 'BRL'
        WHEN 'COMPRA A/V - INT$ - APRES'          THEN 'USD'
        WHEN 'SAQUE CASH/ATM BB'                  THEN 'BRL'
        WHEN 'SAQUE - R$ - APRES'                 THEN 'BRL'
        WHEN 'SAQUE - INT$ - APRES'               THEN 'USD'
        WHEN 'Informações protegidas por sigilo'  THEN 'Não Aplicável'
        ELSE 'Não Aplicável'
    END AS moeda,
    CASE descricao_original
        WHEN 'COMPRA A/V - R$ - APRES'            THEN 'Cartão / Fatura'
        WHEN 'COMPRA A/V - INT$ - APRES'          THEN 'Cartão / Fatura'
        WHEN 'SAQUE CASH/ATM BB'                  THEN 'Espécie / Autoatendimento'
        WHEN 'SAQUE - R$ - APRES'                 THEN 'Espécie / Autoatendimento'
        WHEN 'SAQUE - INT$ - APRES'               THEN 'Espécie / Autoatendimento'
        WHEN 'Informações protegidas por sigilo'  THEN 'Sigiloso'
        ELSE 'Outros'
    END AS canal
FROM (SELECT DISTINCT descricao_original FROM stg_cpgf_transacoes);
