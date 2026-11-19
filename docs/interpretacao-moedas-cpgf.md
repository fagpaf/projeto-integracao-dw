# Interpretação dos grupos de operação do CPGF

Verificação realizada em 17/11/2026 para as análises 2 e 3.

## Evidência e limite da confirmação

O [dicionário oficial do CPGF](https://portaldatransparencia.gov.br/dicionario-de-dados/cpgf) define `COMPRA A/V - INT$ - APRES` e `SAQUE - INT$ - APRES` como operações efetuadas no exterior. Não define INT$ como dólar. A descrição de `Valor Transação` não explicita a moeda.

Uma [nota publicada pela Casa Civil](https://www.gov.br/casacivil/pt-br/acesso-a-informacao/informacoes-classificadas/informacoes-classificadas-e-desclassificadas-publicadas-ate-23-01-2029-na-sg/despesas-com-cartao-de-pagamento-do-governo-federal-mandatos-anteriores/cartao2003-202208032023.csv/view) informa que operações em moeda estrangeira passaram a representar valores convertidos em reais a partir de março de 2020. Esse trecho foi localizado na indexação pública; a abertura direta falhou durante a verificação. É evidência contrária à hipótese de que INT$ implica valores em USD, mas não foi tratado como confirmação específica de todos os CSVs de 2023–2025.

**Confirmado:** INT$ identifica exterior. **Não confirmado de forma suficiente para toda a base:** moeda do campo de valor de cada lançamento. Para encerrar essa pendência, obter confirmação da CGU/Banco do Brasil especificamente sobre `VALOR TRANSAÇÃO` nos downloads anuais utilizados. Não aplicar conversão cambial adicional: ela poderia converter novamente um valor já convertido.

## Decisão aplicada

As consultas das análises 2 e 3 usam `descricao_original` para formar grupos de operação:

- `R$/ATM`: descrições com R$ ou `SAQUE CASH/ATM BB`.
- `Exterior (INT$)`: descrições com INT$.
- `Sem identificação`: demais descrições; o ranking de órgãos distingue ainda os sigilosos.

São grupos operacionais, não uma declaração de que existam moedas diferentes no campo monetário. Os valores permanecem como fornecidos e não são combinados entre esses grupos. As comparações entre compras e saques usam quantidades. Os rankings mantêm o recorte R$/ATM e não representam gasto total.

O campo `DIM_TIPO_TRANSACAO.moeda` conserva a classificação legada dos pipelines e **não é utilizado por estas duas análises**. O mapeamento legado `INT$ → USD` não deve ser interpretado como moeda comprovada. Alterar esse contrato global exige revisar em conjunto pipelines, esquema, demais análises e bancos já gerados.
