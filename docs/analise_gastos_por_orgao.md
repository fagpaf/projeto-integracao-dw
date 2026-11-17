# Análise 2 — Órgãos e sigilo

## Objetivo e recorte

O [SQL](../scripts/sql/queries/analise_gastos_por_orgao.sql) analisa 2023–2025 pelo ano do extrato e agrupa as unidades pelo código e nome do órgão superior.

O ranking exibido considera somente compras e saques do grupo operacional R$/ATM. **Exclui transações sigilosas, INT$ e Outros; não é um ranking do gasto total.** Os quatro órgãos usados no painel temporal são selecionados nesse mesmo ranking.

O indicador de sigilo é `quantidade de transações sigilosas / quantidade total de transações do órgão no ano × 100`. O denominador inclui abertas, sigilosas e não classificadas. **Não é participação no valor financeiro.** Uma transação de valor alto pesa tanto quanto uma de valor baixo nesse percentual.

A categoria de sigilo é a registrada em `DIM_TIPO_TRANSACAO`. Essa interpretação deve acompanhar a legenda em qualquer apresentação.

## Moedas e valores

As consultas não usam o atributo legado `moeda`. INT$ identifica exterior, não USD comprovado. Consulte a [evidência e decisão metodológica](interpretacao-moedas-cpgf.md). As somas são realizadas em centavos antes da apresentação decimal, sem conversão cambial.

## Execução e resultados

Na raiz do projeto, com pandas e matplotlib instalados:

```bash
python scripts/analise_gastos_por_orgao.py
```

O banco padrão é `data/database/cpgf_dw.sqlite`, aberto somente para leitura. É possível informar outro banco e pasta como argumentos posicionais.

Saídas em `docs/analises/02_analise/`:

- `analise_gastos_por_orgao.png`: ranking restrito e evolução do percentual da quantidade sigilosa.
- `gastos_por_orgao_anual.csv`: todas as linhas da consulta anual, incluindo os valores por grupo.
- `gastos_por_orgao_ranking.csv`: rankings separados por grupo operacional.

A ausência de um órgão no gráfico não significa gasto baixo no total: ele pode concentrar despesas nos grupos excluídos. A consulta também não mede irregularidade nem avalia a justificativa legal do sigilo.
