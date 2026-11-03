import hashlib
import json
import re
import sys
import time
import urllib.request
import zipfile
from datetime import datetime, timezone
from pathlib import Path

ano_inicio = int(sys.argv[1]) if len(sys.argv) > 1 else 2023
ano_fim = int(sys.argv[2]) if len(sys.argv) > 2 else 2025

PASTA_RAW = Path(__file__).resolve().parent.parent / "data" / "raw"
PASTA_AMOSTRAS = PASTA_RAW / "amostras"
ARQ_METADADOS = PASTA_RAW / "metadados.json"
URL_BASE = "https://portaldatransparencia.gov.br/download-de-dados/cpgf/"


def agora():
    return datetime.now(timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z")


def baixar(url, destino, tentativas=3):
    # o portal redireciona para o servidor de arquivos da CGU, por isso
    # guardamos a url final (geturl) junto com o conteúdo
    for i in range(1, tentativas + 1):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "projeto-integracao-dw"})
            with urllib.request.urlopen(req, timeout=60) as resp:
                conteudo = resp.read()
                destino.write_bytes(conteudo)
                return conteudo, resp.geturl()
        except Exception as erro:
            print(f"   falhou (tentativa {i}): {erro}")
            if i == tentativas:
                raise
            time.sleep(2 * i)


def ler_linhas_do_zip(caminho_zip):
    # os csv do portal vêm em latin-1 e separados por ";"
    with zipfile.ZipFile(caminho_zip) as z:
        texto = b"".join(z.read(nome) for nome in z.namelist()).decode("latin-1")
    return [linha for linha in re.split(r"\r?\n", texto) if linha]


def main():
    PASTA_AMOSTRAS.mkdir(parents=True, exist_ok=True)
    metadados = []

    for ano in range(ano_inicio, ano_fim + 1):
        amostra = []
        saida = open(PASTA_RAW / f"{ano}_CPGF.csv", "w", encoding="utf-8")

        for mes in range(1, 13):
            ref = f"{ano}{mes:02d}"
            caminho_zip = PASTA_RAW / f"{ref}_CPGF.zip"
            print(f"{ref}...")

            baixado_em = agora()
            if caminho_zip.exists():
                conteudo = caminho_zip.read_bytes()
                url_final = URL_BASE + ref
            else:
                conteudo, url_final = baixar(URL_BASE + ref, caminho_zip)

            linhas = ler_linhas_do_zip(caminho_zip)

            # amostra = cabeçalho + 100 primeiras linhas de janeiro
            if mes == 1:
                amostra = linhas[:101]

            # cada mês vem com o próprio cabeçalho
            inicio = 0 if mes == 1 else 1
            saida.write("\n".join(linhas[inicio:]) + "\n")

            metadados.append({
                "referencia": ref,
                "url_origem": url_final,
                "arquivo": caminho_zip.name,
                "tamanho_bytes": len(conteudo),
                "sha256": hashlib.sha256(conteudo).hexdigest(),
                "qtd_registros": len(linhas) - 1,
                "colunas": [col.replace('"', "") for col in linhas[0].split(";")],
                "baixado_em": baixado_em,
            })

            time.sleep(0.5)  # pausa pra não sobrecarregar o portal

        saida.close()
        (PASTA_AMOSTRAS / f"{ano}_amostra.csv").write_text("\n".join(amostra), encoding="utf-8")

    ARQ_METADADOS.write_text(json.dumps(metadados, ensure_ascii=False, indent=2), encoding="utf-8")

    # resumo final: total de registros por ano e se as colunas mudaram
    total_por_ano = {}
    colunas_por_ano = {}
    for m in metadados:
        ano = m["referencia"][:4]
        total_por_ano[ano] = total_por_ano.get(ano, 0) + m["qtd_registros"]
        colunas_por_ano.setdefault(ano, tuple(m["colunas"]))

    print("\nano   registros")
    for ano, total in total_por_ano.items():
        print(f"{ano}  {total:>10,}".replace(",", "."))

    if len(set(colunas_por_ano.values())) == 1:
        print("Mesmo esquema de colunas em todos os anos")
    else:
        print("As colunas mudaram entre os anos, conferir metadados.json")


if __name__ == "__main__":
    main()
