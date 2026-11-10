# Dicionário de Dados — Data Warehouse CPGF (2023–2025)

Mapeamento estrutural, restrições de integridade e regras de negócio do Esquema Estrela (*Star Schema*) implementado em SQLite.

---

### 1. `FATO_TRANSACAO_CPGF`
**Grão:** 1 linha por transação individual (compra ou saque) registrada no CPGF. Repetições exatas de atributos são preservadas (~21% da base), pois a omissão de data e portador em registros sigilosos impede comprovar duplicidade.

| Coluna | Tipo | Restrições | Origem (CSV) | Regra / Descrição |
| :--- | :--- | :--- | :--- | :--- |
| `id_transacao` | `INTEGER` | `PK` | *Gerado no DW* | Chave substituta sequencial automática do SQLite (`ROWID`). |
| `id_data_transacao` | `INTEGER` | `FK`, `NOT NULL` | `DATA TRANSAÇÃO` | Ref. `DIM_TEMPO(id_tempo)` no formato `YYYYMMDD`. Recebe `-1` se sigilosa/ausente. |
| `id_mes_extrato` | `INTEGER` | `FK`, `NOT NULL` | `ANO/MÊS EXTRATO` | Ref. `DIM_TEMPO(id_tempo)` ancorada no dia `01` do mês (`YYYYMM01`). |
| `id_orgao` | `INTEGER` | `FK`, `NOT NULL` | `CÓD. UG / ÓRGÃO` | Ref. `DIM_ORGAO(id_orgao)`. |
| `id_portador` | `INTEGER` | `FK`, `NOT NULL` | `CPF / NOME PORTADOR` | Ref. `DIM_PORTADOR(id_portador)`. Recebe `-1` se sigilosa/ausente. |
| `id_favorecido` | `INTEGER` | `FK`, `NOT NULL` | `CNPJ-CPF / NOME FAV.` | Ref. `DIM_FAVORECIDO(id_favorecido)`. |
| `id_tipo_transacao` | `INTEGER` | `FK`, `NOT NULL` | `TRANSAÇÃO` | Ref. `DIM_TIPO_TRANSACAO(id_tipo_transacao)`. |
| `valor_transacao` | `DECIMAL(15,2)` | `NOT NULL` | `VALOR TRANSAÇÃO` | Convertido de `1.234,56` para ponto decimal. Em agregações no SQLite, utilizar `ROUND(SUM(valor_transacao), 2)`. |
| `quantidade_transacoes`| `INTEGER` | `NOT NULL`, `DEFAULT 1`, `CHECK (= 1)` | *Derivado* | Métrica constante igual a `1` para contagem aditiva de transações. |

---

### 2. `DIM_TEMPO`
**Descrição:** Dimensão calendário (*Role-Playing Dimension*) utilizada para a data da transação e para o mês do extrato.

| Coluna | Tipo | Restrições | Descrição / Regra |
| :--- | :--- | :--- | :--- |
| `id_tempo` | `INTEGER` | `PK` | Inteiro `YYYYMMDD` ou `-1` (Não Informado / Sigiloso). |
| `data` | `DATE` | `UNIQUE` | Data em texto ISO (`YYYY-MM-DD`). `NULL` apenas para `id_tempo = -1`. |
| `dia` | `INTEGER` | — | Dia do mês (`1` a `31`). `NULL` para `-1`. |
| `mes` | `INTEGER` | `CHECK (1..12)` | Número do mês (`1` a `12`). `NULL` para `-1`. |
| `nome_mes` | `VARCHAR(30)` | `NOT NULL` | Nome do mês em português ou `'Não Informado / Sigiloso'`. |
| `trimestre` | `INTEGER` | `CHECK (1..4)` | Trimestre do ano (`1` a `4`). `NULL` para `-1`. |
| `semestre` | `INTEGER` | `CHECK (1..2)` | Semestre do ano (`1` ou `2`). `NULL` para `-1`. |
| `ano` | `INTEGER` | — | Ano com 4 dígitos (`2023` a `2025`). `NULL` para `-1`. |
| `dia_semana` | `VARCHAR(20)` | `NOT NULL` | Dia da semana em português ou `'Não Informado'`. |
| `fim_de_semana` | `BOOLEAN` | — | `1` para sábado/domingo, `0` para dia útil (`NULL` para `-1`). |

---

### 3. `DIM_ORGAO`
**Descrição:** Hierarquia administrativa federal desnormalizada. Códigos armazenados como texto para preservar zeros à esquerda.

| Coluna | Tipo | Restrições | Origem (CSV) | Descrição |
| :--- | :--- | :--- | :--- | :--- |
| `id_orgao` | `INTEGER` | `PK` | *Gerado no DW* | Chave substituta sequencial. |
| `codigo_unidade_gestora` | `VARCHAR(20)` | `NOT NULL`, `UQ (composta)` | `CÓDIGO UNIDADE GESTORA` | Código SIAFI da Unidade Gestora (UG). |
| `nome_unidade_gestora` | `VARCHAR(255)` | `NOT NULL` | `NOME UNIDADE GESTORA` | Nome da Unidade Gestora. |
| `codigo_orgao` | `VARCHAR(20)` | `NOT NULL`, `UQ (composta)` | `CÓDIGO ÓRGÃO` | Código do órgão subordinado. |
| `nome_orgao` | `VARCHAR(255)` | `NOT NULL` | `NOME ÓRGÃO` | Nome do órgão subordinado. |
| `codigo_orgao_superior` | `VARCHAR(20)` | `NOT NULL`, `UQ (composta)` | `CÓDIGO ÓRGÃO SUPERIOR` | Código do Ministério / Órgão Superior. |
| `nome_orgao_superior` | `VARCHAR(255)` | `NOT NULL` | `NOME ÓRGÃO SUPERIOR` | Nome do Ministério / Órgão Superior. |

---

### 4. `DIM_PORTADOR`
**Descrição:** Identificação do servidor público responsável pelo cartão.

| Coluna | Tipo | Restrições | Origem (CSV) | Regra / Descrição |
| :--- | :--- | :--- | :--- | :--- |
| `id_portador` | `INTEGER` | `PK` | *Gerado no DW* | Chave substituta sequencial (`-1` para portador sigiloso). |
| `cpf_mascarado` | `VARCHAR(20)` | `NOT NULL`, `UQ (composta)` | `CPF PORTADOR` | Formato `***.XXX.XXX-**` ou `'SIGILOSO'` (para `id_portador = -1`). |
| `nome_portador` | `VARCHAR(255)` | `NOT NULL`, `UQ (composta)` | `NOME PORTADOR` | Nome do servidor ou `'Portador Sigiloso / Não Identificado'`. |

---

### 5. `DIM_FAVORECIDO`
**Descrição:** Estabelecimento, pessoa física ou marcação administrativa recebedora do pagamento.

| Coluna | Tipo | Restrições | Origem (CSV) | Regra / Descrição |
| :--- | :--- | :--- | :--- | :--- |
| `id_favorecido` | `INTEGER` | `PK` | *Gerado no DW* | Chave substituta sequencial. |
| `documento` | `VARCHAR(30)` | `NOT NULL`, `UQ (composta)` | `CNPJ OU CPF FAVORECIDO` | CNPJ, CPF mascarado ou códigos administrativos (`-1`, `-2`, `-11`). |
| `nome_favorecido` | `VARCHAR(255)` | `NOT NULL`, `UQ (composta)` | `NOME FAVORECIDO` | Razão social, nome civil ou descrição administrativa (`Sigiloso`, `NAO SE APLICA`, `SEM INFORMACAO`). |
| `tipo_pessoa` | `VARCHAR(20)` | `NOT NULL`, `CHECK IN ('PF', 'PJ', 'Especial')` | *Derivado de `documento`* | `'PJ'` (14 dígitos), `'PF'` (11 dígitos ou máscara de CPF) ou `'Especial'` (códigos `-1`, `-2`, `-11`). |

---

### 6. `DIM_TIPO_TRANSACAO`
**Descrição:** Natureza, modalidade, moeda e canal da operação realizada.

| Coluna | Tipo | Restrições | Origem (CSV) | Regra / Valores Permitidos |
| :--- | :--- | :--- | :--- | :--- |
| `id_tipo_transacao` | `INTEGER` | `PK` | *Gerado no DW* | Chave substituta sequencial. |
| `descricao_original` | `VARCHAR(255)` | `NOT NULL`, `UNIQUE` | `TRANSAÇÃO` | Descrição literal preservada da fonte. |
| `categoria` | `VARCHAR(50)` | `NOT NULL`, `CHECK` | *Derivado* | Valores: `'Compra'`, `'Saque'`, `'Sigiloso'`, `'Outros'`. |
| `moeda` | `VARCHAR(20)` | `NOT NULL`, `CHECK` | *Derivado* | Valores: `'BRL'`, `'USD'`, `'Não Aplicável'`. |
| `canal` | `VARCHAR(50)` | `NOT NULL`, `CHECK` | *Derivado* | Valores: `'Cartão / Fatura'`, `'Espécie / Autoatendimento'`, `'Sigiloso'`, `'Outros'`. |