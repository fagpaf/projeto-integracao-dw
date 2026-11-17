# Análise de gastos por órgão e proporção de despesas sigilosas

## Objetivo

Analisar os maiores órgãos gastadores no período de 2023 a 2025 e comparar, em cada ano, a proporção dos valores classificados como **abertos**, **sigilosos** e **não classificados**.

A análise utiliza a dimensão `DIM_ORGAO` para identificar os órgãos e seus níveis hierárquicos, e a dimensão `DIM_TEMPO` para agrupar os valores por ano.

## Arquivo SQL relacionado

` scripts/sql/queries/analise_gastos_por_orgao.sql `

Esse arquivo contém duas consultas complementares:

1. **Evolução anual por órgão superior:** aapresenta os valores de compras e saques separados por BRL e USD, os valores sigilosos sem moeda informada e os valores da categoria Outros. Também apresenta a quantidade e o percentual de transações abertas, sigilosas e não classificadas.
2. **Ranking acumulado dos dez maiores órgãos:** apresenta rankings independentes para BRL, USD e valores sigilosos cuja moeda não foi informada.

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

### 4. Percentuais da evolução anual
Como a moeda dos registros sigilosos não está informada, não é correto calcular o percentual do valor sigiloso sobre um total monetário que misture BRL e USD.

Por isso, a consulta anual calcula os percentuais de transações abertas, sigilosas e não classificadas com base na quantidade de transações de cada grupo em relação à quantidade total de transações daquele órgão superior naquele ano.

Os valores monetários são apresentados separadamente por grupo de moeda, sem calcular uma proporção monetária entre gastos abertos e sigilosos.

### 5. Separação por moeda
As consultas não somam valores em BRL e USD como se fossem uma única moeda.
- BRL: valores de compras e saques cuja moeda está identificada como real.
- USD: valores de compras e saques cuja moeda está identificada como dólar.
- Moeda não informada: valores de transações classificadas como Sigiloso, pois esses registros não apresentam identificação da moeda na dimensão.
A categoria Outros é apresentada separadamente como não aplicável, conforme o valor de moeda registrado na dimensão.

Essa separação evita atribuir uma moeda sem evidência na fonte e impede que valores em reais e dólares sejam somados em um único total.

## Por que as duas consultas são complementares?

A consulta anual mostra como a quantidade de transações abertas, sigilosas e não classificadas se distribui em cada órgão ao longo de 2023 a 2025, além de apresentar os valores separados por moeda.

Já os rankings mostram quais órgãos têm os maiores valores registrados em BRL, USD e transações sigilosas sem moeda informada.

Dessa forma, as consultas permitem analisar o volume e a composição das transações sem misturar moedas ou atribuir uma moeda não identificada aos registros sigilosos.
