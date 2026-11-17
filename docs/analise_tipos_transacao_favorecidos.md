# Análise 3 — Compras, saques e favorecidos

## Objetivo e consultas

O [SQL](../scripts/sql/queries/analise_tipos_transacao_favorecidos.sql) restringe as três consultas a 2023–2025 pelo ano do extrato:

1. Quantidade e valor registrado por categoria, canal e grupo operacional.
2. Top 10 favorecidos PF/PJ no recorte de compras/saques R$/ATM.
3. Distribuição por grupo operacional e tipo de favorecido, incluindo Especial.

O [script](../scripts/analise_tipos_transacao_favorecidos.py) gera dois PNGs separados, com dois painéis cada: o primeiro compara compras × saques em quantidade para R$/ATM e Exterior (INT$); o segundo mostra o ranking de favorecidos e a distribuição por tipo de favorecido no recorte R$/ATM.

## Interpretação

INT$ indica operações no exterior e não comprova USD. A [nota de interpretação](interpretacao-moedas-cpgf.md) registra as fontes e a pendência de confirmação da unidade monetária. O script não utiliza a classificação legada `moeda` e não realiza conversão cambial.

A comparação entre modalidades utiliza **quantidade de transações**. As somas dos valores ficam disponíveis nos CSVs por grupo operacional. Os dois painéis de valores mantêm o recorte R$/ATM.

O percentual no ranking é calculado sobre **todos os favorecidos PF/PJ do recorte R$/ATM**, não sobre todo o CPGF nem apenas sobre os dez primeiros. Especial, sigilo, INT$ e Outros não entram nesse denominador. O favorecido é o membro da dimensão (documento e nome), não necessariamente o fornecedor final ou um grupo econômico consolidado.

Não há frase fixa afirmando que todos os favorecidos do exterior são Especial: a distribuição deve ser conferida na saída de cada execução. A descrição Compra corresponde à classificação do projeto e não comprova financiamento ou parcelamento no crédito.

## Execução e saídas

Na raiz do projeto, com pandas e matplotlib instalados:

```bash
python scripts/analise_tipos_transacao_favorecidos.py
```

O banco padrão `data/database/cpgf_dw.sqlite` é aberto somente para leitura. Banco e pasta podem ser informados como argumentos posicionais.

Saídas em `docs/analises/03_analise/`:

- [compras_saques.png](analises/03_analise/compras_saques.png): comparação das modalidades;
- [concentracao_favorecidos.png](analises/03_analise/concentracao_favorecidos.png): concentração e perfil dos favorecidos;
- `compras_saques.csv`;
- `ranking_favorecidos.csv`;
- `distribuicao_favorecidos.csv`.

Os CSVs preservam os resultados completos das consultas. As somas usam centavos antes da apresentação decimal. Compare resultados somente com o mesmo período e recorte; o ranking não é evidência de irregularidade.
