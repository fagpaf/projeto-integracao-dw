# Projeto de Integração: Data Warehouse CPGF (ETL vs ELT)

> Projeto de Integração, disciplina de Banco de Dados, CIn/UFPE

Este projeto integra três anos de dados do Cartão de Pagamento do Governo Federal (CPGF) em um Data Warehouse dimensional (Esquema Estrela), implementado e validado por duas arquiteturas de pipeline em paralelo: ETL clássico (Python/pandas) e ELT (SQL dentro do próprio banco).

O CPGF funciona de forma parecida com um cartão de crédito corporativo, usado pelo governo para pagar despesas que se enquadram como suprimento de fundos. Os dados são públicos, publicados mensalmente no [Portal da Transparência](https://portaldatransparencia.gov.br/download-de-dados/cpgf).

-----

## Objetivo e Desafio

O objetivo é comparar, sobre a mesma base de dados, duas formas de construir um data warehouse: transformar em memória antes de carregar (ETL) ou carregar bruto e transformar dentro do banco (ELT), além de extrair insights de negócio do resultado final.

* **Fonte:** [Portal da Transparência, CPGF](https://portaldatransparencia.gov.br/download-de-dados/cpgf).
* **Dados brutos:** um CSV por ano (2023, 2024, 2025), 15 colunas idênticas nos três anos, totalizando 438.771 registros (134.122 em 2023, 143.849 em 2024 e 160.800 em 2025).
* **Desafios principais:** cerca de 25% das linhas são sigilosas (sem data da compra nem portador identificado), entre 21% e 23% são repetições exatas que não podem ser descartadas automaticamente, o mês do extrato nem sempre coincide com o mês da compra, e a lista de descrições de transação muda ligeiramente entre os anos.

## Arquitetura da Solução

Os dois pipelines partem dos mesmos três CSVs e aplicam as mesmas regras de negócio (documentadas em [docs/decisoes_modelagem.md](docs/decisoes_modelagem.md)); o que muda é onde a transformação acontece.

### 1. Pipeline ETL (Python/pandas)

Implementado em [notebooks/ETL.ipynb](notebooks/ETL.ipynb). Toda a limpeza, conversão de valores e datas, tratamento de sigilo e geração das chaves substitutas acontece em memória, com pandas. Só os dados já transformados chegam ao banco (`data/database/cpgf_dw.sqlite`).

### 2. Pipeline ELT (SQL no banco)

Implementado em [notebooks/ELT.ipynb](notebooks/ELT.ipynb). Os CSVs são carregados primeiro sem nenhuma transformação, em tabelas `raw_cpgf_*`. Em seguida, os sete scripts de [scripts/sql/elt_transformations/](scripts/sql/elt_transformations/) montam o Esquema Estrela inteiramente em SQL, lendo apenas das tabelas brutas já carregadas, no banco `data/database/cpgf_elt.sqlite`.

A comparação quantitativa entre os dois (tempo, memória, tamanho do banco e 46 verificações de equivalência) é feita pelo notebook [notebooks/Benchmark_ETL_ELT.ipynb](notebooks/Benchmark_ETL_ELT.ipynb) e detalhada em [docs/benchmark-etl-elt.md](docs/benchmark-etl-elt.md).

## Modelagem de Dados (Esquema Estrela)

| Tabela | Tipo | Descrição |
| :--- | :--- | :--- |
| `FATO_TRANSACAO_CPGF` | Fato | Uma linha por transação (compra ou saque). Medidas: `valor_transacao` e `quantidade_transacoes`. |
| `DIM_TEMPO` | Dimensão | Calendário com dois papéis na fato: data da transação e mês do extrato. |
| `DIM_ORGAO` | Dimensão | Hierarquia administrativa: unidade gestora, órgão e órgão superior. |
| `DIM_PORTADOR` | Dimensão | Servidor público responsável pelo cartão. |
| `DIM_FAVORECIDO` | Dimensão | Quem recebeu o pagamento, classificado em PF, PJ ou Especial. |
| `DIM_TIPO_TRANSACAO` | Dimensão | Descrição original da transação e os atributos derivados categoria, moeda e canal. |

O racional completo de cada decisão está em [docs/decisoes_modelagem.md](docs/decisoes_modelagem.md), e o dicionário de dados em [docs/dicionario-de-dados.md](docs/dicionario-de-dados.md).

## Tecnologias Utilizadas

* **Python 3.9+**: coleta, profiling e scripts de análise (pandas, matplotlib).
* **SQLite**: banco de dados dos dois pipelines.
* **Jupyter / Google Colab**: execução dos notebooks de ETL, ELT e benchmark.
* **psutil, nbconvert**: medição de tempo e memória no benchmark.
* **Git/GitHub**: versionamento e revisão em pull requests.

## Estrutura do Repositório

```
data/
  raw/              CSVs originais baixados do portal (não versionados)
  raw/amostras/     amostra de 100 linhas por ano (versionada)
  processed/        relatórios de benchmark (JSON)
  database/         cpgf_dw.sqlite e cpgf_elt.sqlite (não versionados)
docs/
  report/           relatório final do projeto (relatorio.tex)
  analises/         gráficos e CSVs gerados pelas três análises
  diagrams/         diagrama do esquema estrela e do fluxo ETL/ELT
  *.md              documentação de cada etapa (coleta, profiling, modelagem, ETL, ELT, benchmark, análises)
notebooks/
  ETL.ipynb             pipeline ETL completo
  ELT.ipynb             pipeline ELT completo
  Benchmark_ETL_ELT.ipynb   comparativo e validação de qualidade
scripts/
  extract_cpgf.py       coleta dos dados
  profile_cpgf.py       perfilamento dos CSVs brutos
  analise_*.py          geração dos gráficos das três análises
  sql/
    ddl/                 criação do esquema e dicionário de dados
    elt_transformations/ transformações SQL do pipeline ELT
    queries/             consultas usadas nas três análises
```

## Como Executar

### No Google Colab

1. Abra o notebook desejado (`ETL.ipynb`, `ELT.ipynb` ou `Benchmark_ETL_ELT.ipynb`) no Colab.
2. Confira a variável `RAMO_REPOSITORIO` na primeira célula de configuração: ela define de qual branch o notebook clona o repositório, e precisa apontar para uma branch publicada no GitHub com a versão desejada (normalmente `main`).
3. Em **Ambiente de execução**, escolha **Executar tudo**.
4. Se a base completa ainda não estiver no ambiente, envie os três CSVs de `data/raw/` pelo botão de upload quando solicitado, ou gere-os localmente com `python scripts/extract_cpgf.py` e faça o upload.

### Localmente

Pré-requisitos: Python 3.9 ou mais recente e Git.

```bash
python -m pip install -r requirements.txt
```

1. **Coleta:** `python scripts/extract_cpgf.py` (baixa e consolida os CSVs de 2023 a 2025 em `data/raw/`).
2. **Perfilamento (opcional):** `python scripts/profile_cpgf.py` (gera o diagnóstico em `docs/relatorio-profiling.txt`).
3. **Carga:** abra `notebooks/ETL.ipynb` e/ou `notebooks/ELT.ipynb` com Jupyter (`python -m jupyter notebook`) e execute todas as células, para gerar os bancos em `data/database/`.
4. **Benchmark (opcional):** abra `notebooks/Benchmark_ETL_ELT.ipynb` para medir tempo, memória e validar a equivalência entre os dois bancos.
5. **Análises:** com os bancos gerados, rode `python scripts/analise_evolucao_temporal.py`, `python scripts/analise_gastos_por_orgao.py` e `python scripts/analise_tipos_transacao_favorecidos.py`, que salvam os gráficos em `docs/analises/`.

## Resultados e Insights

As três análises, detalhadas em [docs/report/relatorio.tex](docs/report/relatorio.tex), usam o data warehouse já carregado:

1. **Evolução temporal:** o valor gasto cresce todo ano (+23,2% em 2024, +9,3% em 2025), mas o crescimento desacelera; novembro e dezembro concentram entre 23% e 26% do valor anual, e fevereiro é sistematicamente o mês mais fraco.
2. **Gastos por órgão:** no recorte de compras e saques em reais, Defesa, Educação e Planejamento concentram os maiores valores com sigilo praticamente nulo, enquanto o Ministério da Justiça e Segurança Pública tem entre 75% e 80% de suas transações classificadas como sigilosas em todos os anos observados.
3. **Tipos de transação e favorecidos:** compras superam saques com folga em quantidade; o maior favorecido identificado é a PAGAR.ME S.A., com 5.317 transações.

> **Nota sobre a qualidade dos dados:** cerca de um quarto da base é sigiloso (sem data da compra nem portador) e precisou de um tratamento de modelagem explícito em vez de ser descartado; e a classificação legada de moeda (`BRL`/`USD`) em `DIM_TIPO_TRANSACAO` não é confiável para as análises 2 e 3, que passaram a agrupar pela descrição original da transação (ver [docs/interpretacao-moedas-cpgf.md](docs/interpretacao-moedas-cpgf.md)).

## Documentação

- [Coleta dos dados](docs/coleta-de-dados.md): como baixar os arquivos do portal e o que fica salvo em `data/raw/`.
- [Inspeção dos dados](docs/data-profiling.md): etapas realizadas e instruções da auditoria dos dados.
- [Decisões de modelagem](docs/decisoes_modelagem.md): racional de cada escolha do Esquema Estrela.
- [Pipeline ETL](docs/ETL.md) e [Pipeline ELT](docs/ELT.md): como executar cada um.
- [Validação e benchmark ETL × ELT](docs/benchmark-etl-elt.md): execução, verificações de qualidade e interpretação das medições.
- [Relatório final](docs/report/relatorio.tex): consolida todas as etapas e as três análises.

## Contribuição da Equipe

| Nome | Login | Principais contribuições |
| :--- | :--- | :--- |
| Flávio Araújo Filho | fagpaf | Data profiling e auditoria temporal, notebooks ETL e ELT (Extract & Load), análise 1 (evolução temporal e sazonalidade), auditoria final e simulação de defesa. |
| João Pedro A. de Moraes | jpam | Coleta e ingestão dos dados do CPGF, scripts DDL e dicionário de dados, scripts SQL de transformação do ELT, redação do relatório técnico e documentação do README. |
| Maria Cláudia Rocha | mcsr | Modelagem dimensional (Star Schema), validação cruzada e comparativo ETL x ELT, análises 2 e 3 (órgãos/sigilo e favorecidos/transações), slides da apresentação. |
