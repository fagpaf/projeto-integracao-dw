# Data Profiling e Auditoria Temporal

Etapa implementada: inspeção dos CSVs de 2023, 2024 e 2025, com comparação
entre anos e geração de um relatório de diagnóstico.

O [script de inspeção](../scripts/profile_cpgf.py) verifica encoding, separador,
campos vazios, marcadores nulos, sigilo, duplicatas, formatos de datas e valores,
cobertura mensal e mudanças de colunas e categorias de transação.

O resultado está no [relatório de profiling](relatorio-profiling.txt).
Esta etapa identifica problemas e características da base, o tratamento dos
dados para ETL e ELT fica para uma etapa posterior.

## Como executar a inspeção

Execute os comandos abaixo na raiz do repositório.

Instale o pandas (`pip install pandas`) e execute:

```bash
python scripts/profile_cpgf.py
```

O script imprime encoding de leitura, tipos, vazios, marcadores nulos, sigilo,
duplicatas, formatos de datas/valores, cobertura mensal e mudanças de colunas e
categorias entre os três CSVs anuais. Os arquivos originais não são alterados.
O diagnóstico também é salvo em [relatorio-profiling.txt](relatorio-profiling.txt),
em UTF-8, com data da execução e arquivos analisados. Cada execução substitui o
relatório anterior, a saída no terminal aparece ao concluir a análise.
Para analisar amostras ou outros arquivos, passe os caminhos como argumentos.

Latin-1 é usado como fallback quando UTF-8 falha; isso não distingue Latin-1 de
Windows-1252.
Meses ausentes em amostras não comprovam lacunas na base completa.
Repetições exatas não devem ser excluídas automaticamente, especialmente sob sigilo.
