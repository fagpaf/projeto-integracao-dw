# Coleta dos dados

Os dados do CPGF são baixados direto do [Portal da Transparência](https://portaldatransparencia.gov.br/download-de-dados/cpgf). O portal disponibiliza um arquivo `.zip` por mês, com um CSV dentro.

## Como rodar

Com Python 3.9 ou mais recente instalado, rode na raiz do repositório:

```bash
python scripts/extract_cpgf.py
```

Por padrão o script baixa de 2023 a 2025. Para outro intervalo, é só passar os anos:

```bash
python scripts/extract_cpgf.py 2022 2024
```

* No Colab, depois de clonar o repositório, o comando é o mesmo com `!` na frente.

## O que é gerado

Tudo fica em `data/raw/`:

- `AAAAMM_CPGF.zip`: os arquivos mensais originais. Não sobem para o GitHub, já que o script consegue baixá-los de novo.
- `amostras/AAAA_amostra.csv`: o cabeçalho e as 100 primeiras linhas de janeiro de cada ano, para dar uma olhada nos dados sem precisar baixar tudo.
- `metadados.json`: para cada mês, o link de onde o arquivo veio, o tamanho, o hash sha256, a quantidade de registros, as colunas e a data do download.

## O que encontramos

| Ano  | Registros |
|------|-----------|
| 2023 | 134.122   |
| 2024 | 143.849   |
| 2025 | 160.800   |

- As 15 colunas são as mesmas nos três anos.
- Os arquivos originais vêm em Latin-1, separados por `;`, e os valores usam vírgula como separador decimal (ex.: `162,48`).
- O extrato de um mês pode ter compras de meses anteriores. O de janeiro de 2023, por exemplo, tem compras de novembro e dezembro de 2022.
- Cerca de 25% das linhas são sigilosas: o nome do portador, o favorecido e a data aparecem como "Sigiloso" ou vazios.
- O CPF do portador já vem mascarado pelo próprio portal (ex.: `***.562.861-**`).
