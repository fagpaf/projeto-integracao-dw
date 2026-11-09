# Decisões de Modelagem do Data Warehouse CPGF

Este documento apresenta as principais decisões tomadas durante a construção do modelo multidimensional do Data Warehouse (DW) dos dados do Cartão de Pagamento do Governo Federal (CPGF).

## 1. Grão da tabela fato

Foi definido que cada registro da `FATO_TRANSACAO_CPGF` representa uma transação individual realizada com o CPGF.

Dessa forma, cada linha da tabela fato corresponde a uma compra ou saque, permitindo analisar os valores e as quantidades de transações por diferentes dimensões.

## 2. Dimensão temporal

Optou-se por utilizar uma única dimensão temporal (`DIM_TEMPO`), referenciada duas vezes na tabela fato:

- `id_data_transacao`: representa a data em que a compra ou o saque foi realizado.
- `id_mes_extrato`: representa o ano e o mês aos quais o registro pertence no extrato.

Essas informações possuem finalidades diferentes e não devem ser confundidas. Uma mesma data de transação pode estar associada a diferentes meses de extrato. Além disso, existem registros sem data de transação informada, mas que possuem o mês do extrato.

Para representar o mês do extrato, será utilizado o primeiro dia do mês como referência. Por exemplo, janeiro de 2023 será representado por 01/01/2023.

Assim, a mesma dimensão exerce dois papéis temporais distintos, evitando a duplicação de estruturas.

## 3. Dimensão de favorecido

A `DIM_FAVORECIDO` possui os atributos `documento`, `nome_favorecido` e `tipo_pessoa`.

O atributo `tipo_pessoa` será utilizado para diferenciar pessoas físicas e jurídicas a partir do tamanho do documento, após a remoção de caracteres não numéricos:

- 11 dígitos: Pessoa Física (CPF).
- 14 dígitos: Pessoa Jurídica (CNPJ).

O documento será armazenado como texto, preservando possíveis zeros à esquerda.

Registros com documentos ausentes, sigilosos ou que não correspondam aos formatos de CPF e CNPJ serão tratados separadamente, sem classificação incorreta como pessoa física ou jurídica.

## 4. Dimensão de órgão

A `DIM_ORGAO` reúne informações da hierarquia administrativa presente na base, incluindo:

- Unidade Gestora (UG);
- Órgão;
- Órgão superior.

Optou-se por manter essas informações em uma única dimensão, evitando a criação de dimensões separadas para cada nível hierárquico.

## 5. Dimensão de portador

A `DIM_PORTADOR` armazena as informações de identificação do portador, utilizando um identificador próprio (`id_portador`).

A identificação considera o CPF mascarado e o nome do portador em conjunto, pois o CPF mascarado, isoladamente, pode aparecer associado a nomes diferentes na base.

## 6. Dimensão de tipo de transação

A `DIM_TIPO_TRANSACAO` armazena a descrição original do tipo de transação e atributos derivados para facilitar as análises, como categoria, moeda e canal.

A descrição original será preservada para manter a informação disponibilizada pela fonte de dados.

## 7. Chaves das dimensões

As dimensões utilizarão chaves substitutas (surrogate keys), representadas pelos atributos `id_...`.

Essas chaves serão utilizadas como chaves primárias das dimensões e como chaves estrangeiras na tabela fato, permitindo estabelecer os relacionamentos do modelo estrela.

## 8. Tratamento de transações sigilosas e informações ausentes

Aproximadamente 25% dos registros da base (110.172) são protegidos por sigilo e não informam a data da transação nem o CPF do portador. Esses registros não serão descartados, pois ainda contêm o valor, o órgão e o mês do extrato, relevantes para as análises.

Para representar essas ausências, serão criados membros especiais com identificador -1 em DIM_TEMPO (data da transação não informada) e em DIM_PORTADOR (portador não identificado). Nos registros sigilosos, id_data_transacao aponta para o membro -1, enquanto id_mes_extrato continua referenciando o período correspondente.

As demais dimensões não possuem valores ausentes. A própria fonte já identifica os casos especiais do favorecido (?Sigiloso?, ?NAO SE APLICA? e ?SEM INFORMACAO?) e o tipo de transação sigiloso, que são mantidos como membros regulares das respectivas dimensões, sem agrupamento.