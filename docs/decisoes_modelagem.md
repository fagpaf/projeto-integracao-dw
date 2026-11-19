# Decisões de Modelagem — Data Warehouse CPGF

Decisões arquiteturais aplicadas ao modelo dimensional em Esquema Estrela (*Star Schema*) do Cartão de Pagamento do Governo Federal (CPGF).

## 1. Grão da Tabela Fato
Cada linha da `FATO_TRANSACAO_CPGF` representa **uma transação individual (compra ou saque)**.
- **Chave primária:** `id_transacao` (chave substituta sequencial).
- **Medida armazenada:** `valor_transacao` (valor financeiro da operação).
- **Quantidade de transações:** calculada nas consultas com `COUNT(*)`.
  A coluna constante `quantidade_transacoes` foi removida por ser redundante.
  O `CHECK (= 1)` apenas restringia seu valor; não garantia a granularidade
  da fato, que depende da carga e de suas validações.

## 2. Dimensões Temporais

O modelo separa a data da transação do período mensal do extrato:

- `id_data_transacao` referencia `DIM_TEMPO(id_tempo)`, com chave
  `YYYYMMDD`. Essa dimensão contém os atributos diários, como dia,
  dia da semana e indicação de fim de semana.
- `id_mes_extrato` referencia `DIM_MES_EXTRATO(id_mes_extrato)`, com
  chave `YYYYMM`. Essa dimensão contém ano, mês, nome do mês,
  trimestre e semestre.

A dimensão mensal possui os doze meses de cada ano de extrato presente
na origem. Ano e mês são preservados juntos para distinguir períodos
de anos diferentes.

Essa separação evita atribuir ao extrato os atributos diários de uma
data artificial. Por exemplo, uma compra em 31/12/2022 com extrato de
janeiro de 2023 terá `id_data_transacao = 20221231` e
`id_mes_extrato = 202301`.

Transações sigilosas continuam incluídas nas análises pelo mês do
extrato, mesmo quando a data da compra não está disponível.

## 3. Dimensão de Favorecido (`DIM_FAVORECIDO`)
Identificada pelo par `(documento, nome_favorecido)`. O campo `documento` é mantido como texto para preservar zeros à esquerda e máscaras.
O atributo `tipo_pessoa` é derivado do formato do documento após limpeza de pontuação:
- **PJ:** 14 dígitos numéricos (CNPJ).
- **PF:** 11 dígitos numéricos (CPF completo) ou padrão de máscara da LGPD (`***.XXX.XXX-**`, com 6 dígitos visíveis).
- **Especial:** valores administrativos da fonte (`"-1"` / `"SEM INFORMACAO"`, `"-2"` / `"NAO SE APLICA"` e `"-11"` / `"Sigiloso"`) são preservados em suas próprias categorias, sem classificá-los incorretamente como PF ou PJ.

## 4. Dimensão de Órgão (`DIM_ORGAO`)
Reúne os 3 níveis da hierarquia administrativa (**Unidade Gestora**, **Órgão** e **Órgão Superior**) desnormalizados em uma única tabela dimensão, mantendo o *Star Schema* puro e evitando *JOINs* em cascata (*Snowflake*).

## 5. Dimensão de Portador (`DIM_PORTADOR`)
A chave natural de negócio combina `(cpf_mascarado, nome_portador)`, pois o CPF parcialmente oculto (`***.XXX.XXX-**`) isoladamente pode se repetir entre servidores homônimos ou distintos.

## 6. Dimensão de Tipo de Transação (`DIM_TIPO_TRANSACAO`)
Preserva a `descricao_original` da fonte e deriva três atributos analíticos: `categoria` (*Compra*, *Saque*, *Sigiloso*), `moeda` (*BRL*, *USD*, *Não Aplicável*) e `canal` (*Cartão / Fatura*, *Espécie / Autoatendimento*, *Sigiloso*).

## 7. Chaves Substitutas (*Surrogate Keys*)
Todas as dimensões utilizam chaves primárias inteiras (`id_...`), referenciadas como chaves estrangeiras na `FATO_TRANSACAO_CPGF`.

## 8. Transações Sigilosas e Valores Ausentes
Cerca de 25% dos registros (110.172 transações) são sigilosos e não informam data da transação nem portador. Esses registros são mantidos para preservar a soma real dos gastos por órgão e período.
- Criou-se o membro especial **`-1`** em `DIM_TEMPO` (*Não Informado / Sigiloso*) e em `DIM_PORTADOR` (*Portador Sigiloso*).
- Nas transações sob sigilo, `id_data_transacao` e `id_portador` apontam para `-1`, enquanto `id_mes_extrato` aponta normalmente para o mês do extrato.
- Em `DIM_FAVORECIDO` e `DIM_TIPO_TRANSACAO`, as marcações `"Sigiloso"`, `"NAO SE APLICA"` e `"SEM INFORMACAO"` já vêm preenchidas na fonte e são tratadas como membros regulares.
