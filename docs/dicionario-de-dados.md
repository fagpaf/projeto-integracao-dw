# Dicionário de Dados e DDL

Esquema Estrela do CPGF (2023–2025) em **SQLite**. As decisões de modelagem estão em [decisoes_modelagem.md](decisoes_modelagem.md) e o desenho em [diagrama-estrela.png](diagrams/diagrama-estrela.png).

## Como criar o banco

Na raiz do repositório (Python 3.9+, sem dependências):

```bash
python scripts/create_database.py
```

Cria `data/database/cpgf_dw.sqlite` (não sobe para o GitHub), executa os scripts de [scripts/sql/ddl/](../scripts/sql/ddl/) e verifica o esquema. Termina com `Esquema criado e verificado com sucesso.` ou lista as falhas. Recria as tabelas do zero, então apaga dados já carregados.

| Script | Função |
|---|---|
| `01_create_star_schema.sql` | Tabelas, restrições e membros `-1` |
| `02_populate_dim_tempo.sql` | Calendário de 2022-01-01 a 2025-12-31 |
| `03_create_indexes.sql` | Índices nas FKs; rodar após a carga com `python scripts/create_database.py --indices` |

## Observações

- O SQLite só valida FKs com `PRAGMA foreign_keys = ON` em cada conexão.
- `DECIMAL` é guardado como ponto flutuante: somar com `ROUND(SUM(valor_transacao), 2)`.
- O calendário começa em 2022 porque os extratos de 2023 trazem compras desde 2022-10-12.
- A fato não impõe unicidade: repetições exatas (~21%) são mantidas, pois sob sigilo não comprovam duplicidade.
- `valor_transacao` não tem `CHECK` de sinal, pois estornos ainda não foram verificados.

Legenda: `PK` chave primária, `FK` chave estrangeira, `NK` chave natural (única). Todas as colunas são `NOT NULL`, salvo indicação.

## FATO_TRANSACAO_CPGF

Grão: 1 linha = 1 transação individual (compra ou saque).

| Coluna | Tipo | Chave | Descrição / origem no CSV |
|---|---|---|---|
| `id_transacao` | INTEGER | PK | Sequencial automático |
| `id_data_transacao` | INTEGER | FK → `DIM_TEMPO` | DATA TRANSAÇÃO (`dd/mm/aaaa` → `aaaammdd`); vazia (sigilo) → `-1` |
| `id_mes_extrato` | INTEGER | FK → `DIM_TEMPO` | ANO EXTRATO + MÊS EXTRATO → `aaaamm01` |
| `id_orgao` | INTEGER | FK → `DIM_ORGAO` | Unidade gestora da transação |
| `id_portador` | INTEGER | FK → `DIM_PORTADOR` | CPF PORTADOR vazio (sigilo) → `-1` |
| `id_favorecido` | INTEGER | FK → `DIM_FAVORECIDO` | Favorecido da transação |
| `id_tipo_transacao` | INTEGER | FK → `DIM_TIPO_TRANSACAO` | TRANSAÇÃO |
| `valor_transacao` | DECIMAL(15,2) | | VALOR TRANSAÇÃO (vírgula decimal → ponto) |
| `quantidade_transacoes` | INTEGER | | Sempre `1` (`CHECK`) |

## DIM_TEMPO

Dimensão role-playing: serve à data da transação e ao mês do extrato (dia `01`).

| Coluna | Tipo | Chave | Descrição |
|---|---|---|---|
| `id_tempo` | INTEGER | PK | `aaaammdd` (ex.: `20230115`) ou `-1` |
| `data` | DATE | NK | Texto ISO; nula só em `-1` |
| `dia`, `mes`, `ano` | INTEGER | | Partes da data |
| `nome_mes` | VARCHAR | | Em português; `Não Informado / Sigiloso` em `-1` |
| `trimestre`, `semestre` | INTEGER | | 1–4 e 1–2 |
| `dia_semana` | VARCHAR | | Em português; `Não Informado` em `-1` |
| `fim_de_semana` | BOOLEAN | | `1` sábado/domingo, `0` dia útil |

## DIM_ORGAO

| Coluna | Tipo | Chave | Origem no CSV |
|---|---|---|---|
| `id_orgao` | INTEGER | PK | |
| `codigo_unidade_gestora` | VARCHAR | NK | CÓDIGO UNIDADE GESTORA |
| `nome_unidade_gestora` | VARCHAR | | NOME UNIDADE GESTORA |
| `codigo_orgao` | VARCHAR | NK | CÓDIGO ÓRGÃO |
| `nome_orgao` | VARCHAR | | NOME ÓRGÃO |
| `codigo_orgao_superior` | VARCHAR | NK | CÓDIGO ÓRGÃO SUPERIOR |
| `nome_orgao_superior` | VARCHAR | | NOME ÓRGÃO SUPERIOR |

Códigos como texto para preservar zeros à esquerda.

## DIM_PORTADOR

| Coluna | Tipo | Chave | Origem no CSV |
|---|---|---|---|
| `id_portador` | INTEGER | PK | `-1` = `Portador Sigiloso` |
| `cpf_mascarado` | VARCHAR | NK | CPF PORTADOR (ex.: `***.562.861-**`) |
| `nome_portador` | VARCHAR | NK | NOME PORTADOR |

## DIM_FAVORECIDO

| Coluna | Tipo | Chave | Origem no CSV |
|---|---|---|---|
| `id_favorecido` | INTEGER | PK | |
| `documento` | VARCHAR | NK | CNPJ OU CPF FAVORECIDO (texto) |
| `nome_favorecido` | VARCHAR | NK | NOME FAVORECIDO |
| `tipo_pessoa` | VARCHAR | | `PJ` (14 dígitos), `PF` (11 dígitos ou máscara LGPD) ou `Especial` (`-1`, `-2`, `-11`); `CHECK` |

## DIM_TIPO_TRANSACAO

| Coluna | Tipo | Chave | Descrição |
|---|---|---|---|
| `id_tipo_transacao` | INTEGER | PK | |
| `descricao_original` | VARCHAR | NK | TRANSAÇÃO, como vem da fonte |
| `categoria` | VARCHAR | | `Compra`, `Saque`, `Sigiloso` ou `Outros` (`CHECK`) |
| `moeda` | VARCHAR | | `BRL`, `USD` ou `Não Aplicável` (`CHECK`) |
| `canal` | VARCHAR | | `Cartão / Fatura`, `Espécie / Autoatendimento`, `Sigiloso` ou `Outros` (`CHECK`) |

`Outros` acolhe descrições que mudam entre os anos (ex.: `CPP LOJISTA TRF P/FATURA - REAL` surge em 2025). A classificação de cada descrição é feita na carga.
