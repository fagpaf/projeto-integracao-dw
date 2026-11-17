# Análise 1 — Evolução temporal e sazonalidade de gastos

Como os gastos do CPGF evoluem de 2023 a 2025 e se existe um padrão que se repete a cada ano.

- Consulta: [01_evolucao_temporal.sql](../../../scripts/sql/queries/01_evolucao_temporal.sql)
- Script que executa a consulta e gera o gráfico: [analise_evolucao_temporal.py](../../../scripts/analise_evolucao_temporal.py)

```bash
python -m pip install -r requirements.txt
python scripts/analise_evolucao_temporal.py
```

![Valor mensal e índice sazonal por ano](01_evolucao-temporal.png)

## Decisão de método: mês do extrato, não data da transação

O eixo de tempo é `id_mes_extrato`. Cerca de 25% das transações são sigilosas e não informam a data da compra (`id_data_transacao = -1`), e elas respondem por cerca de metade do valor. Todas informam o mês do extrato, então esse eixo mantém 100% do valor e os 36 meses completos. Agrupar apenas por datas conhecidas excluiria 46,45% do valor. Não há compras com data de dezembro de 2025 no banco consultado; o deslocamento para extratos posteriores é uma hipótese, não uma conclusão desta análise.

## Resultados

| Ano | Transações | Valor total (R$) | Var. valor | Var. quantidade | Ticket médio (R$) |
|---|---:|---:|---:|---:|---:|
| 2023 | 134.122 | 90.717.210,79 | — | — | 676 |
| 2024 | 143.849 | 111.802.599,28 | +23,2% | +7,3% | 777 |
| 2025 | 160.800 | 122.254.704,02 | +9,3% | +11,8% | 760 |

## Interpretação

1. **Crescimento desacelerando.** O valor sobe 23,2% de 2023 para 2024 e 9,3% de 2024 para 2025. Em 2024 o salto vem sobretudo do ticket médio (+15%), porque a quantidade cresce só 7,3%. Em 2025 a quantidade cresce mais que o valor (+11,8% contra +9,3%) e o ticket médio recua ligeiramente.
2. **Pico no fim do ano.** Novembro e dezembro concentram 23% do valor de 2023 e cerca de 26% em 2024 e 2025. Os maiores valores mensais da série são dezembro de 2025 (R$ 19,5 mi, índice sazonal 1,91) e novembro de 2024 (R$ 15,3 mi, índice 1,64). Nesses meses sobem a quantidade e o ticket médio ao mesmo tempo (R$ 890 em dez/2025 e R$ 921 em nov/2024, contra tickets entre aproximadamente R$ 611 e R$ 842 nos demais meses da série).
3. **Fevereiro é um vale nos três anos.** Fevereiro fica em torno de 0,18–0,22 da média do ano, com só 1,8 mil a 2,7 mil transações, contra 6 mil a 22 mil nos outros meses. Janeiro e março também ficam abaixo da média (índice 0,58–0,84). O padrão se repete nos três anos observados, mas **a causa não foi investigada**. Uma hipótese a confirmar é o calendário de fechamento das faturas e prestação de contas. O que vale é que, em `id_mes_extrato`, os meses do primeiro trimestre ficam abaixo da média anual nos três anos observados.
4. **Meio do ano estável.** De abril a outubro os valores ficam perto da média do ano (índice 0,89–1,23), com oscilações pequenas e sem tendência clara dentro do ano.

## Limites e ressalvas

- Os totais mensais são por **mês do extrato**. O mês em que a compra ocorreu pode ser anterior (um extrato de janeiro inclui compras de dezembro).
- A parcela sigilosa do valor varia de 29% a 58% por mês (participação de 46,45% no valor total do período, não média simples dos percentuais mensais). Ela não é uniforme: em 2025 ficou entre 33% e 48%, abaixo dos picos de 2023 e 2024. A classificação como sigilosa limita o detalhamento das despesas, mas sua mudança, isoladamente, não altera o total agregado, pois ambos os grupos estão incluídos.
- Valores e taxas de crescimento são **nominais**, sem correção pela inflação.
- O índice é descritivo: valor mensal dividido pela média dos 12 meses do mesmo ano. Não foi realizado teste estatístico nem decomposição de sazonalidade; três anos permitem descrever recorrência, sem comprovar suas causas.
- Resultados conferidos em 17/11/2026 no banco completo `data/database/cpgf_dw.sqlite`: 438.771 transações e 36 meses. A tabela foi atualizada para incluir a diferença de uma transação de R$ 2.201,72 em 2025 em relação à versão anterior do documento. Novas cargas podem mudar os resultados.

## Reprodução e conferência

Execute os comandos acima na raiz do projeto, com a `.venv` ativa. O script abre o banco somente para leitura e interrompe a execução se faltar algum dos 36 meses. Não preenche meses ausentes com zero.

Além do PNG, são geradas as tabelas [mensal](01_evolucao-temporal_mensal.csv), [anual](01_evolucao-temporal_anual.csv) e de [índice sazonal](01_evolucao-temporal_sazonalidade.csv). O arquivo [de identificação da execução](01_evolucao-temporal.json) registra o nome e o SHA-256 do banco, horário de geração e quantidade de transações. Ao trocar a base, regenere os artefatos e revise esta interpretação.

Para usar outro banco sem sobrescrever o gráfico da apresentação:

```bash
python scripts/analise_evolucao_temporal.py caminho/banco.sqlite --saida /tmp/evolucao-temporal.png
```

Amostras não devem substituir os resultados da base completa na apresentação.
