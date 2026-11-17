# Análise de tipos de transação e concentração em favorecidos

## Objetivo

Investigar os tipos de transação registrados na base, comparando compras realizadas por cartão/fatura com saques em espécie, e analisar a concentração dos valores entre os favorecidos identificados na dimensão `DIM_FAVORECIDO`.

A análise considera as categorias `Compra` e `Saque` e utiliza a moeda registrada para evitar misturar diretamente valores em BRL e USD.

## Arquivo SQL relacionado

` scripts/sql/queries/analise_tipos_transacao_favorecidos.sql `

O arquivo contém três consultas complementares:

1. Comparação entre compras e saques por moeda.
2. Ranking dos dez maiores favorecidos identificados em BRL, com quantidade de transações, valor total e percentual sobre o total identificado.
3. Distribuição das transações por moeda e tipo de favorecido, para evidenciar limitações na análise de concentração.

## Decisões metodológicas

### 1. Comparação entre compras e saques

A classificação é obtida a partir de `DIM_TIPO_TRANSACAO`:

- `Compra`: registros classificados como compras, com canal `Cartão / Fatura`.
- `Saque`: registros classificados como saques, com canal `Espécie / Autoatendimento`.

A consulta compara a quantidade de transações e a soma de `valor_transacao` para cada categoria e moeda.

### 2. Separação por moeda

As consultas mantêm BRL e USD em grupos separados. Não é feita conversão cambial.

Essa decisão evita somar valores em moedas diferentes como se fossem equivalentes. Assim, a comparação entre compras e saques deve ser feita dentro de cada moeda.

### 3. Ranking apenas de favorecidos identificados

A dimensão `DIM_FAVORECIDO` possui o atributo `tipo_pessoa`, com os seguintes tipos:

- `PF`: pessoa física.
- `PJ`: pessoa jurídica.
- `Especial`: registros que não correspondem a uma pessoa física ou jurídica identificada da mesma forma.

Para o ranking dos dez maiores favorecidos, foram considerados somente `PF` e `PJ`. Registros classificados como `Especial`, incluindo nomes como `NAO SE APLICA` e `SEM INFORMACAO`, foram excluídos do ranking porque não representam favorecidos identificados de maneira comparável a uma pessoa física ou jurídica.

Essa escolha evita que registros genéricos ou sem identificação ocupem posições no ranking de favorecidos.

### 4. Percentual de concentração

O percentual de cada favorecido é calculado em relação à soma dos valores de todos os favorecidos identificados (`PF` e `PJ`) em BRL, dentro do recorte de compras e saques.

Portanto, o percentual não representa a participação sobre todas as transações da base. Ele representa a participação dentro do universo filtrado de favorecidos identificados em BRL.

### 5. Consulta de distribuição por tipo de favorecido

A terceira consulta foi incluída para mostrar a distribuição por moeda e tipo de pessoa, inclusive os registros `Especial`.

Ela é importante para contextualizar o ranking: sem essa verificação, poderia parecer que não existem transações em USD com favorecidos, quando na realidade os registros em USD estão associados ao tipo `Especial`.

## Principais resultados observados

### Compras e saques

| Categoria | Moeda | Quantidade de transações | Valor registrado |
|---|---:|---:|---:|
| Compra | BRL | 285.215 | 146.169.574,83 |
| Saque | BRL | 37.889 | 21.977.164,00 |
| Compra | USD | 3.429 | 3.513.468,74 |
| Saque | USD | 2.059 | 2.245.473,89 |

Em quantidade de transações, as compras aparecem em maior número que os saques, tanto em BRL quanto em USD.

Os valores são apresentados na moeda original registrada na base. Não se deve comparar diretamente o total em BRL com o total em USD como se fossem a mesma unidade monetária.

### Dez maiores favorecidos identificados em BRL

| Posição | Favorecido | Tipo | Transações | Valor registrado | Percentual |
|---:|---|---|---:|---:|---:|
| 1 | PAGAR.ME S.A. | PJ | 5.317 | 4.295.670,12 | 3,19% |
| 2 | MERCADO PAGO INSTITUICAO DE PAGAMENTO LTDA | PJ | 1.436 | 901.519,58 | 0,67% |
| 3 | PAYGO ADMINISTRADORA DE MEIOS DE PAGAMENTOS LTDA | PJ | 609 | 582.362,94 | 0,43% |
| 4 | IFOOD PAGO INSTITUICAO DE PAGAMENTO S.A. | PJ | 470 | 428.951,88 | 0,32% |
| 5 | TAM LINHAS AEREAS S/A. | PJ | 174 | 370.708,56 | 0,28% |
| 6 | BMB MATERIAL DE CONSTRUCAO S.A. | PJ | 645 | 311.974,16 | 0,23% |
| 7 | FERRAGEM PARATI CONCEICAO LTDA | PJ | 696 | 279.793,30 | 0,21% |
| 8 | R M DE SOUZA | PJ | 83 | 279.087,15 | 0,21% |
| 9 | MAGALUPAY INSTITUICAO DE PAGAMENTO S.A. | PJ | 367 | 267.681,16 | 0,20% |
| 10 | GOL LINHAS AEREAS S.A. | PJ | 133 | 255.303,91 | 0,19% |

O maior favorecido identificado foi `PAGAR.ME S.A.`, com 5.317 transações e valor registrado de 4.295.670,12 BRL. Esse valor corresponde a 3,19% do total considerado no ranking (favorecidos identificados `PF` e `PJ` em BRL).

O percentual individual dos dez primeiros permite observar a participação de cada favorecido no total identificado. O ranking, sozinho, não deve ser interpretado como prova de irregularidade ou de concentração indevida.

### Distribuição por moeda e tipo de favorecido

| Moeda | Tipo de favorecido | Quantidade de transações | Valor registrado |
|---|---|---:|---:|
| BRL | Especial | 53.308 | 33.426.882,87 |
| BRL | PF | 13.077 | 9.613.152,80 |
| BRL | PJ | 256.719 | 125.106.703,16 |
| USD | Especial | 5.488 | 5.758.942,63 |

Um resultado importante é que, no conjunto analisado, todas as 5.488 transações em USD estão associadas a favorecidos do tipo `Especial`. Não aparecem registros `PF` ou `PJ` em USD nessa consulta.

Isso explica por que o ranking de favorecidos identificados foi limitado a BRL: não seria possível produzir um ranking nominal comparável de pessoas físicas e jurídicas para USD com os registros disponíveis.

## Por que as três consultas são complementares?

A primeira compara o comportamento de compras e saques por moeda. A segunda identifica os maiores favorecidos nominais e mede a participação de cada um no universo identificado em BRL. A terceira contextualiza os resultados ao mostrar a distribuição entre `PF`, `PJ` e `Especial` em cada moeda.

Juntas, as consultas permitem investigar os tipos de transação e a concentração em favorecidos sem esconder limitações importantes da identificação dos registros.
