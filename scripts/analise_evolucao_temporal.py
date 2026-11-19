"""Análise 1 — Evolução temporal e sazonalidade de gastos.

Executa as consultas de scripts/sql/queries/evolucao_temporal.sql no DW,
imprime as tabelas e salva o gráfico em docs/analises/01_analise/evolucao-temporal.png.

Uso (na raiz do repositório):
    python -m pip install -r requirements.txt
    python scripts/analise_evolucao_temporal.py [caminho_do_banco.sqlite]
"""
import argparse
import hashlib
import json
import re
from datetime import datetime, timezone
import sqlite3
import sys
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import pandas as pd
from matplotlib.ticker import FuncFormatter

RAIZ = Path(__file__).resolve().parent.parent
ARQ_SQL = RAIZ / "scripts/sql/queries/evolucao_temporal.sql"
BANCO = RAIZ / "data/database/cpgf_dw.sqlite"
SAIDA = RAIZ / "docs/analises/01_analise/evolucao-temporal.png"

# Um ano por cor (ordem fixa) e um marcador por ano, para não depender só da cor.
ESTILO = {
    2023: ("#2a78d6", "o"),
    2024: ("#eb6834", "s"),
    2025: ("#1baf7a", "^"),
}
SUPERFICIE, TEXTO, TEXTO_2, MUDO, GRADE = "#fcfcfb", "#0b0b0b", "#52514e", "#898781", "#e6e5e1"
MESES = ["Jan", "Fev", "Mar", "Abr", "Mai", "Jun", "Jul", "Ago", "Set", "Out", "Nov", "Dez"]


def carregar_consultas(caminho):
    """Divide o arquivo .sql em {nome: consulta} usando os marcadores '-- name:'."""
    blocos = re.split(r"^-- name:\s*(\w+)\s*$", caminho.read_text(encoding="utf-8"), flags=re.M)
    return {nome: sql.strip() for nome, sql in zip(blocos[1::2], blocos[2::2])}


def estilizar(ax, titulo, ylabel):
    ax.set_facecolor(SUPERFICIE)
    ax.set_title(titulo, loc="left", fontsize=11, color=TEXTO, fontweight="bold", pad=10)
    ax.set_ylabel(ylabel, color=TEXTO_2, fontsize=9)
    ax.set_xticks(range(1, 13), MESES)
    ax.tick_params(colors=MUDO, labelsize=9, length=0)
    ax.grid(axis="y", color=GRADE, linewidth=0.8)
    ax.set_axisbelow(True)
    ax.yaxis.set_major_formatter(FuncFormatter(lambda x, _: f"{x:g}".replace(".", ",")))
    for lado in ("top", "right", "left"):
        ax.spines[lado].set_visible(False)
    ax.spines["bottom"].set_color(GRADE)


def linhas_por_ano(ax, df, coluna, rotular=True):
    for ano, (cor, marcador) in ESTILO.items():
        d = df[df["ano"] == ano]
        ax.plot(d["mes"], d[coluna], color=cor, linewidth=2, marker=marcador, markersize=6,
                markeredgecolor=SUPERFICIE, markeredgewidth=1.5, label=str(ano))
        if not rotular:
            continue
        ultimo = d.iloc[-1]
        ax.annotate(f"{ano}", (ultimo["mes"], ultimo[coluna]), xytext=(8, 0),
                    textcoords="offset points", va="center", fontsize=9, color=TEXTO_2)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("banco", nargs="?", type=Path, default=BANCO)
    parser.add_argument("--saida", type=Path, default=SAIDA)
    args = parser.parse_args()
    banco, saida = args.banco.resolve(), args.saida.resolve()
    if not banco.is_file() or not ARQ_SQL.is_file():
        raise ValueError("Banco ou arquivo SQL não encontrado. Confira os caminhos.")
    consultas = carregar_consultas(ARQ_SQL)
    if set(consultas) != {"mensal", "sazonalidade", "anual"}:
        raise ValueError("O SQL deve conter as consultas mensal, sazonalidade e anual.")
    with sqlite3.connect(banco.as_uri() + "?mode=ro", uri=True) as con:
        orfas = con.execute("""
            SELECT COUNT(*)
            FROM FATO_TRANSACAO_CPGF f
            LEFT JOIN DIM_MES_EXTRATO t
                ON t.id_mes_extrato = f.id_mes_extrato
            WHERE t.id_mes_extrato IS NULL
               OR t.ano IS NULL
               OR t.mes IS NULL
        """).fetchone()[0]
        if orfas:
            raise ValueError(f"Há {orfas} transações sem mês de extrato válido.")
        res = {nome: pd.read_sql(sql, con) for nome, sql in consultas.items()}
    mensal, saz, anual = res["mensal"], res["sazonalidade"], res["anual"]

    esperado = {(ano, mes) for ano in ESTILO for mes in range(1, 13)}
    for nome in ("mensal", "sazonalidade"):
        df = res[nome]
        if len(df) != 36 or set(zip(df.ano, df.mes)) != esperado:
            raise ValueError(f"{nome}: são necessários os 36 meses de 2023–2025; confira a cobertura da base.")
    if saz.indice_sazonal.isna().any():
        raise ValueError("Índice indefinido: confira os totais anuais da base.")
    saida.parent.mkdir(parents=True, exist_ok=True)
    for nome, df in res.items():
        df.to_csv(saida.with_name(f"{saida.stem}_{nome}.csv"), index=False)
    with banco.open("rb") as arquivo:
        digest = hashlib.file_digest(arquivo, "sha256").hexdigest()
    metadados = {"banco": banco.name, "sha256": digest,
                 "gerado_em_utc": datetime.now(timezone.utc).isoformat(),
                 "periodo": "2023–2025", "meses": len(mensal),
                 "transacoes": int(anual.qtd_transacoes.sum())}
    saida.with_suffix(".json").write_text(json.dumps(metadados, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    pd.set_option("display.width", 200, "display.max_columns", 20)
    for nome, df in res.items():
        print(f"\n== {nome}\n{df.to_string(index=False)}")

    fig, (a1, a2) = plt.subplots(1, 2, figsize=(13, 5), facecolor=SUPERFICIE)
    mensal = mensal.assign(valor_mi=mensal["valor_total"] / 1e6)
    linhas_por_ano(a1, mensal, "valor_mi")
    estilizar(a1, "Valor mensal por mês de extrato", "R$ milhões")
    a1.set_ylim(0, None)

    linhas_por_ano(a2, saz, "indice_sazonal", rotular=False)  # séries se cruzam em dez: só legenda
    a2.axhline(1, color=MUDO, linewidth=1, linestyle=(0, (4, 3)))
    a2.text(1, 1.02, "média do ano = 1,0", color=MUDO, fontsize=8, va="bottom")
    estilizar(a2, "Índice sazonal (valor do mês ÷ média mensal do ano)", "índice")
    a2.set_ylim(0, None)

    for ax in (a1, a2):
        ax.set_xlim(0.6, 12.9)
        ax.legend(frameon=False, loc="upper left", fontsize=9, labelcolor=TEXTO_2, ncols=3)
    fig.suptitle("CPGF 2023–2025: gastos por mês de extrato", x=0.01, ha="left",
                 fontsize=13, color=TEXTO, fontweight="bold")
    fig.text(0.01, 0.01, "Fonte: DW CPGF (FATO_TRANSACAO_CPGF x DIM_MES_EXTRATO). Valores nominais; inclui transações sigilosas.",
             fontsize=8, color=MUDO)
    fig.tight_layout(rect=(0, 0.03, 1, 0.95))
    fig.savefig(saida, dpi=150, facecolor=SUPERFICIE)
    plt.close(fig)
    print("\nGráfico salvo em", saida)


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, sqlite3.Error, pd.errors.DatabaseError) as erro:
        sys.exit(f"Erro na análise: {erro}")
