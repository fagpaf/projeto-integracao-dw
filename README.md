# Projeto de Integração - Data Warehouse (ETL vs ELT)

Projeto da disciplina em que integramos três anos de dados do **Cartão de Pagamento do Governo Federal (CPGF)** em um Data Warehouse no modelo estrela, comparando as abordagens ETL e ELT.

O CPGF funciona de forma parecida com um cartão de crédito, mas é usado pelo governo para pagar despesas que se enquadram como suprimento de fundos. Os dados são públicos e estão no [Portal da Transparência](https://portaldatransparencia.gov.br/download-de-dados/cpgf).

Período analisado: 2023, 2024 e 2025.

## Documentação

- [Coleta dos dados](docs/coleta-de-dados.md): como baixar os arquivos do portal e o que fica salvo em `data/raw/`

## Estrutura do repositório

```
data/
  raw/            dados originais (amostras e metadados)
  processed/      dados tratados
  database/       banco de dados final
docs/             documentação, relatório, apresentação e diagramas
notebooks/        notebooks do Colab (ETL e ELT)
scripts/          script de coleta e scripts SQL
```
