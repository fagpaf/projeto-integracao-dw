## Pipeline ETL — Extract, Transform & Load

Execute [ETL.ipynb](ETL.ipynb) para integrar os CSVs de 2023, 2024 e 2025 em um esquema estrela no SQLite `data/database/cpgf_dw.sqlite`. O notebook usa pandas para tratar valores monetários, padronizar datas, identificar transações sigilosas e gerar as chaves substitutas das dimensões. Todas as transações da origem são preservadas, inclusive repetições; datas e portadores sigilosos recebem a chave `-1`.

Antes, instale o pandas com `pip install pandas` e gere os CSVs com `python scripts/extract_cpgf.py`, executando os comandos na raiz do projeto. Para usar as amostras versionadas, configure `MODO_AMOSTRA = True`; a saída será `cpgf_dw_amostra.sqlite`. Execute todas as células na ordem. A carga pode ser repetida sem acumular registros e só substitui o banco após validar contagens, valores e integridade dos relacionamentos. Divergências de contagem entre os CSVs e os metadados geram um aviso, sem interromper a carga.
