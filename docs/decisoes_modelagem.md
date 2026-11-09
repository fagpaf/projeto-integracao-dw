# Decisões de Modelagem — Data Warehouse CPGF

Decisões arquiteturais aplicadas ao modelo dimensional em Esquema Estrela (*Star Schema*) do Cartão de Pagamento do Governo Federal (CPGF).

## 1. Grão da Tabela Fato
Cada linha da `FATO_TRANSACAO_CPGF` representa **uma transação individual (compra ou saque)**.
- **Chave primária:** `id_transacao` (chave substituta sequencial).
- **Medidas:** `valor_transacao` (valor financeiro da operação) e `quantidade_transacoes` (constante `1` por registro para agregações).

## 2. Dimensão Temporal (*Role-Playing Dimension*)
Uma única tabela `DIM_TEMPO` cumpre dois papéis distintos na tabela fato:
- `id_data_transacao`: data em que a compra ou saque ocorreu.
- `id_mes_extrato`: mês e ano da prestação de contas, ancorado no dia `01` do respectivo mês (ex: `2023-01-01`).

Isso evita duplicar tabelas de calendário e permite analisar transações sigilosas (que omitem a data da compra, mas informam o mês do extrato).

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
