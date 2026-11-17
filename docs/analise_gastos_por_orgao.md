# Análise de gastos por órgão e proporção de despesas sigilosas

## Objetivo

Analisar os maiores órgãos gastadores no período de 2023 a 2025 e comparar, em cada ano, a proporção dos valores classificados como **abertos**, **sigilosos** e **não classificados**.

A análise utiliza a dimensão `DIM_ORGAO` para identificar os órgãos e seus níveis hierárquicos, e a dimensão `DIM_TEMPO` para agrupar os valores por ano.

## Arquivo SQL relacionado

` scripts/sql/queries/analise_gastos_por_orgao.sql `

Esse arquivo contém duas consultas complementares:

1. **Evolução anual por órgão superior:** apresenta os valores e percentuais de gastos abertos, sigilosos e não classificados para cada órgão superior em cada ano.
2. **Ranking acumulado dos dez maiores órgãos:** identifica os dez órgãos superiores com maiores valores acumulados no período de 2023 a 2025 e apresenta a divisão entre gastos abertos, sigilosos e não classificados.

## Decisões metodológicas

### 1. Agrupamento por órgão superior

A dimensão de órgãos representa uma hierarquia organizacional. Um órgão pode conter unidades subordinadas, então agrupar apenas pelo órgão/unidade poderia fragmentar os gastos de uma mesma estrutura administrativa.

Por isso, a análise agrupa os registros por **código e nome do órgão superior**. Assim, os gastos das unidades vinculadas são consolidados no nível superior, permitindo uma comparação mais abrangente entre ministérios e demais estruturas.

### 2. Classificação dos gastos

A classificação utiliza a categoria registrada em `DIM_TIPO_TRANSACAO`:

- **Abertos:** categorias `Compra` e `Saque`.
- **Sigilosos:** categoria `Sigiloso`.
- **Não classificados:** categoria `Outros`.

A categoria `Outros` foi mantida separada. Ela não deve ser somada automaticamente aos gastos abertos ou sigilosos, pois representa registros que não se encaixam nessas duas classificações.

### 3. Uso do mês do extrato para identificar o ano

O ano da análise é obtido a partir de `id_mes_extrato`, relacionado a `DIM_TEMPO`, e não da data individual da transação.

Essa escolha é importante porque transações protegidas por sigilo podem apresentar `id_data_transacao = -1`, já que a data exata não está disponível. O mês do extrato continua sendo uma referência temporal utilizável para agrupar esses registros.

### 4. Percentuais calculados dentro de cada órgão e ano

Na consulta anual, os percentuais são calculados em relação ao valor total daquele órgão superior naquele ano. Dessa forma, é possível comparar a composição dos gastos de um órgão ao longo do tempo, mesmo quando o volume total varia.

Na consulta do ranking, a divisão entre aberto, sigiloso e não classificado é calculada sobre o total acumulado de cada órgão no período analisado.

### 5. Valores monetários e moedas

Os valores são somados conforme estão registrados na base. Não é realizada conversão cambial entre BRL e USD.

Portanto, caso existam valores em moedas diferentes dentro do mesmo agrupamento, o total numérico não deve ser interpretado como um valor financeiro convertido para uma moeda única. A análise de proporções também deve ser interpretada considerando essa limitação.

## Principais resultados observados

O ranking acumulado identificou, entre os dez maiores órgãos superiores:

1. Ministério da Justiça e Segurança Pública — 94.286.292,01 em valores numéricos registrados.
2. Presidência da República — 74.071.334,32.
3. Ministério da Defesa — 43.256.761,57.
4. Ministério da Educação — 34.827.106,00.
5. Ministério do Planejamento e Orçamento — 23.471.705,18.
6. Ministério do Meio Ambiente e Mudança do Clima — 9.926.519,45.
7. Ministério da Fazenda — 9.075.553,77.
8. Ministério da Saúde — 5.814.226,76.
9. Ministério do Desenvolvimento Agrário e Agricultura Familiar — 5.443.666,53.
10. Ministério da Agricultura e Pecuária — 5.253.682,03.

**Atenção:** esses valores representam os números armazenados na base, sem conversão de USD para BRL. Não devem ser apresentados como um total consolidado em reais caso incluam valores em dólar.

A comparação anual também mostrou diferenças relevantes na composição dos gastos. Por exemplo:

- No Ministério da Justiça e Segurança Pública, a participação dos gastos sigilosos foi de 80,12% em 2023, 82,25% em 2024 e 76,75% em 2025.
- Na Presidência da República, a participação sigilosa ficou próxima de 99% nos três anos.
- No Ministério da Defesa, a participação sigilosa foi pequena: aproximadamente 0,15% em 2023, 0,11% em 2024 e 0,08% em 2025.
- No Ministério da Fazenda, a participação sigilosa passou de 26,95% em 2023 para 28,44% em 2024 e 31,00% em 2025.

Esses resultados ajudam a observar não apenas quais órgãos apresentam maiores valores registrados, mas também como a composição entre gastos abertos e sigilosos varia entre órgãos e ao longo dos anos.

## Por que as duas consultas são complementares?

A consulta anual permite acompanhar a evolução da composição dos gastos de cada órgão entre 2023 e 2025. Já o ranking acumulado oferece uma visão geral dos órgãos com maiores valores no conjunto dos três anos.

Assim, uma consulta responde **como a composição dos gastos mudou ao longo do tempo**, enquanto a outra responde **quais órgãos concentram os maiores valores registrados no período**.
