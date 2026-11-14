## Pipeline ELT — Extract & Load

Execute [ELT.ipynb](ELT.ipynb) para carregar os CSVs de 2023, 2024 e 2025 em `raw_cpgf_2023`, `raw_cpgf_2024` e `raw_cpgf_2025`, no SQLite `data/database/cpgf_elt.sqlite`. O notebook usa apenas a biblioteca padrão do Python e preserva as 15 colunas e seus valores como texto, sem transformação.

Antes, gere os CSVs com `python scripts/extract_cpgf.py`. Para usar as amostras versionadas, configure `MODO_AMOSTRA = True` no notebook; a saída será `cpgf_elt_amostra.sqlite`. Execute todas as células na ordem. A carga pode ser repetida sem acumular registros e só é confirmada após conferir contagens e conteúdo com os arquivos de origem.
