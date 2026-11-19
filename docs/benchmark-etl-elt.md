# Validação de qualidade e benchmark ETL × ELT

## Objetivo

O notebook [Benchmark_ETL_ELT.ipynb](../notebooks/Benchmark_ETL_ELT.ipynb), anteriormente chamado `Validacao_qualidade_comparativo.ipynb`, executa os pipelines [ETL](../notebooks/ETL.ipynb) e [ELT](../notebooks/ELT.ipynb), mede seus recursos e compara os bancos resultantes do CPGF de 2023, 2024 e 2025.

A validação segue o [modelo dimensional](decisoes_modelagem.md): seis dimensões, uma fato por transação e preservação das repetições da origem. O comparativo fornece evidências para o relatório do projeto; não substitui as três análises de negócio nem a discussão das vantagens e desvantagens das abordagens.

## Entradas e configuração

| Parâmetro | Valor atual | Finalidade |
|---|---|---|
| `RAMO_REPOSITORIO` | `refactor` | Branch clonada ou atualizada no Colab. Após a integração, ajustar para a branch que contém a versão desejada. |
| `MODO_AMOSTRA` | `False` | `False` utiliza os CSVs completos; `True` utiliza as amostras versionadas. |
| `REPETICOES` | `3` | Quantidade de execuções de cada pipeline. |
| `ANOS` | `(2023, 2024, 2025)` | Anos dos arquivos de entrada. |
| `TIMEOUT_S` | `3600` | Limite por célula executada pelo nbconvert, não por notebook inteiro. |
| `RAIZ_CONFIGURADA` | Automática | Pasta do projeto; pode ser informada explicitamente em execução local. |

As amostras estão em `data/raw/amostras/AAAA_amostra.csv`, com 100 registros de cada ano. A base completa utiliza `data/raw/2023_CPGF.csv`, `2024_CPGF.csv` e `2025_CPGF.csv`. Os arquivos anuais devem ser os gerados pelo script de coleta, em UTF-8, separados por ponto e vírgula.

## Execução no Colab

1. Abra o notebook e confira `RAMO_REPOSITORIO`. As alterações necessárias devem estar publicadas nessa branch.
2. Para uma primeira conferência, configure `MODO_AMOSTRA = True`.
3. Selecione **Ambiente de execução → Executar tudo**.
4. Confira o resumo das verificações e as tabelas de medição.
5. Para avaliar a base completa, altere `MODO_AMOSTRA = False` e execute tudo novamente. Se os CSVs estiverem ausentes, envie os três arquivos pelo botão de upload.

Para obter os arquivos completos, execute na raiz do projeto, em seu computador:

```bash
python scripts/extract_cpgf.py
```

O upload ocorre antes das medições. Arquivos já presentes são reutilizados. Ao encerrar a sessão do Colab, baixe os relatórios e bancos que deseja preservar.

## Execução local

Use um ambiente Python com as dependências abaixo e Git disponível:

```bash
python -m pip install pandas psutil jupyter nbconvert ipykernel
python -m ipykernel install --user --name python3 --display-name "Python 3 (CPGF)"
python -m jupyter notebook
```

Registre o kernel a partir do ambiente que contém as dependências: os notebooks dos pipelines são executados em processos separados. Abra `notebooks/Benchmark_ETL_ELT.ipynb`, ajuste o modo e execute todas as células na ordem.

Na base completa, coloque previamente os três CSVs em `data/raw/`; o botão de upload só está disponível no Colab. Se a localização automática falhar, configure `RAIZ_CONFIGURADA` com o caminho da raiz do repositório.

## Funcionamento do benchmark

O notebook cria cópias temporárias dos pipelines em `notebooks/_bench_*`, ajusta o modo de execução e desativa a preparação automática do Colab nessas cópias. Os arquivos originais dos pipelines não são editados.

Cada cópia é executada pelo `jupyter nbconvert --execute`. A ordem alterna entre ETL/ELT e ELT/ETL. A medição inclui a inicialização do kernel, a execução das células, as validações internas dos pipelines e suas saídas; não corresponde exclusivamente ao tempo de transformação.

| Medida | Interpretação |
|---|---|
| Tempo total | Tempo decorrido por execução, resumido em mínimo, mediana e máximo. |
| Tempo por seção | Tempos das células agrupados pelos títulos do notebook, apenas da última repetição. |
| Pico de memória | Maior soma de RSS dos processos descendentes do nbconvert, amostrada aproximadamente a cada 50 ms. O processo principal do nbconvert é excluído. |
| Tamanho do banco | Espaço ocupado pelo arquivo SQLite após a execução. |
| Características | Número de tabelas, presença da camada Raw, uso de pandas e quantidade de código Python/SQL. |

O ELT preserva Raw e staging além do esquema estrela. Seu tamanho de arquivo, portanto, não representa apenas o mesmo conteúdo armazenado pelo ETL.

**A execução recria os dados dos bancos de destino do modo selecionado.** A etapa posterior de comparação abre os bancos somente para leitura. Os arquivos temporários são removidos na conclusão normal; uma interrupção pode deixá-los disponíveis para diagnóstico.

## Verificações de qualidade

Na estrutura atual, uma execução completa sem divergências de esquema produz **49 verificações**:

| Bloco | Quantidade | O que verifica |
|---|---:|---|
| Contagem | 10 | Fatos, Raw e staging contra o total dos CSVs; quantidade de membros das seis dimensões. |
| Soma financeira | 4 | Totais em centavos entre CSVs, ETL e ELT, incluindo comparação por ano do extrato. |
| Integridade | 16 | Integridade SQLite, FKs declaradas e ausência de órfãos nas seis relações da fato, em cada banco. |
| Equivalência | 13 | Colunas e conteúdo das dimensões, mais conteúdo e multiplicidade das transações. |
| Sigilo | 6 | Contagens de datas/portadores especiais contra os CSVs e aplicação das chaves especiais aos marcadores de sigilo identificados no banco. |

### Equivalência sem depender das SKs

Chaves substitutas diferentes podem representar o mesmo membro. Por isso, as dimensões são comparadas pelos atributos, excluindo a chave primária. A fato é associada às dimensões e comparada pelas informações de negócio e medidas.

As consultas usam agrupamento com `COUNT(*)` e diferenças nos dois sentidos (`EXCEPT`). Assim, duas transações iguais continuam contando duas vezes. A comparação detecta associações diferentes entre os pipelines, mesmo quando o total financeiro e a quantidade de linhas permanecem iguais.

### Valores e sigilo

Os valores armazenados são arredondados individualmente para centavos antes da soma, evitando comparar diretamente totais em ponto flutuante. Isso não realiza conversão cambial.

A referência dos CSVs considera os marcadores de sigilo e o documento administrativo `-11`. Datas ausentes ou sigilosas e portadores sigilosos ou inteiramente ausentes devem apontar para o membro `-1`. Nas transações identificadas por marcadores de sigilo no banco, o mês do extrato não deve receber `-1`.

## Resultados e arquivos gerados

| Modo | Banco ETL | Banco ELT |
|---|---|---|
| Amostra | `data/database/cpgf_dw_amostra.sqlite` | `data/database/cpgf_elt_amostra.sqlite` |
| Completo | `data/database/cpgf_dw.sqlite` | `data/database/cpgf_elt.sqlite` |

Cada execução concluída grava um relatório com nome próprio:

```text
data/processed/benchmark_etl_elt_<amostra ou completo>_<data e horário>.json
```

O JSON contém modo, repetições, commit, hashes SHA-256 dos CSVs, versões do ambiente, contagens, total em centavos, medições e resultados das verificações. O commit identifica o HEAD; não registra alterações locais ainda sem commit.

O resultado esperado, com a estrutura atual e dados consistentes, é:

```text
Resumo: 49 OK | 0 FALHA
```

Uma `FALHA` aparece no relatório com seu bloco, descrição e detalhe. O notebook não lança uma exceção apenas por existir esse status: é necessário conferir o resumo. Erros de execução dos pipelines, arquivos ausentes ou consultas inválidas podem interromper o notebook antes da geração do JSON.

### Medições históricas

Os resultados de desempenho anteriores à inclusão de `DIM_MES_EXTRATO` são registros históricos do modelo com cinco dimensões e 46 verificações. Seus valores de tempo, memória e tamanho do banco devem ser preservados, inclusive no arquivo `data/processed/benchmark_etl_elt_completo.json` e nos relatórios que citam essa execução.

Esses resultados não representam uma medição do modelo atual. A atualização para seis dimensões e 49 verificações exige uma nova execução do benchmark para obter novas medições de desempenho. Até lá, os números anteriores devem ser identificados como históricos, sem substituí-los por estimativas ou resultados das amostras.

## Diagnóstico e limites

- **Contagem ou soma divergente:** confira os arquivos utilizados, o modo e as regras de transformação; não exclua repetições automaticamente.
- **Órfãos:** revise a carga das dimensões e a associação de chaves na fato.
- **Equivalência divergente:** revise atributos e associações, mesmo que contagens e totais financeiros estejam iguais. O número apresentado conta grupos divergentes nos dois sentidos, não necessariamente transações individuais.
- **Sigilo divergente:** confira os marcadores, as ausências e os membros especiais nas dimensões.
- **Falha do nbconvert:** consulte o arquivo temporário `_bench_<pipeline>.log` e confirme as dependências do kernel `python3`.

As medições da amostra não devem ser extrapoladas para a base completa: em poucos registros, a inicialização do ambiente pode dominar o tempo. Cache, carga da máquina e versões das dependências também afetam os resultados. A amostragem de RSS pode não observar picos muito curtos, e a soma de RSS pode contabilizar memória compartilhada mais de uma vez.

A comparação final considera os bancos da última repetição. A equivalência entre ETL e ELT não comprova, isoladamente, que ambos interpretaram corretamente toda regra de negócio: erros iguais nas duas implementações podem passar. As referências independentes de contagem, soma e sigilo reduzem esse risco, mas não substituem a revisão das transformações.
