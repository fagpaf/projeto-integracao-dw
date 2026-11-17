"""Gráfico da análise de gastos por órgão e proporção de despesas sigilosas.

Executa as consultas de scripts/sql/queries/analise_gastos_por_orgao.sql (sem
alterá-las) e salva docs/analises/analise_gastos_por_orgao.png.

Uso (na raiz do repositório):
    pip install pandas matplotlib
    python scripts/analise_gastos_por_orgao.py [banco.sqlite] [pasta_de_saida]

Valores sem conversão cambial: o total por órgão soma BRL e USD (ver docs).
"""
import sqlite3
import sys
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import pandas as pd

RAIZ = Path(__file__).resolve().parent.parent
ARQ_SQL = RAIZ / "scripts/sql/queries/analise_gastos_por_orgao.sql"
BANCO = Path(sys.argv[1]) if len(sys.argv) > 1 else RAIZ / "data/database/cpgf_dw.sqlite"
SAIDA = Path(sys.argv[2]) if len(sys.argv) > 2 else RAIZ / "docs/analises"

AZUL, LARANJA, VERDE, ROSA = "#2a78d6", "#eb6834", "#1baf7a", "#e87ba4"
SUPERFICIE, TEXTO, TEXTO_2, MUDO, GRADE = "#fcfcfb", "#0b0b0b", "#52514e", "#898781", "#e6e5e1"


def estilizar(ax, titulo, xlabel=None, grade="x"):
    ax.set_facecolor(SUPERFICIE)
    ax.set_title(titulo, loc="left", fontsize=11, color=TEXTO, fontweight="bold", pad=10)
    if xlabel:
        ax.set_xlabel(xlabel, color=TEXTO_2, fontsize=9)
    ax.tick_params(colors=MUDO, labelsize=9, length=0)
    ax.grid(axis=grade, color=GRADE, linewidth=0.8)
    ax.set_axisbelow(True)
    for lado in ("top", "right", "left"):
        ax.spines[lado].set_visible(False)
    ax.spines["bottom"].set_color(GRADE)


def abreviar(nome, limite=34):
    return nome if len(nome) <= limite else nome[: limite - 1] + "…"


def main():
    # O arquivo tem 2 consultas: [0] evolução anual por órgão, [1] ranking acumulado.
    consultas = [p.strip() for p in ARQ_SQL.read_text(encoding="utf-8").split(";") if "SELECT" in p.upper()]
    with sqlite3.connect(BANCO) as con:
        anual, ranking = (pd.read_sql(q, con) for q in consultas)

    fig, (a1, a2) = plt.subplots(1, 2, figsize=(14, 5.5), facecolor=SUPERFICIE,
                                 gridspec_kw={"width_ratios": [1.25, 1]})

    # (a) Top 10 acumulado: aberto vs sigiloso (R$ milhões, empilhado)
    r = ranking.iloc[::-1]  # maior no topo
    y = range(len(r))
    aberto, sigiloso = r["valor_aberto"] / 1e6, r["valor_sigiloso"] / 1e6
    a1.barh(y, aberto, color=AZUL, height=0.65, label="Aberto (compra/saque)",
            edgecolor=SUPERFICIE, linewidth=1.5)
    a1.barh(y, sigiloso, left=aberto, color=LARANJA, height=0.65, label="Sigiloso",
            edgecolor=SUPERFICIE, linewidth=1.5)
    for i, (total, pct) in enumerate(zip(r["valor_total"] / 1e6, r["percentual_sigiloso"])):
        a1.text(total + 0.8, i, f"{total:,.1f} mi · {pct:.0f}% sigiloso".replace(",", "."),
                va="center", fontsize=8.5, color=TEXTO_2)
    a1.set_yticks(list(y), [abreviar(n) for n in r["nome_orgao_superior"]])
    a1.set_xlim(0, (r["valor_total"] / 1e6).max() * 1.45)
    estilizar(a1, "10 maiores órgãos superiores, acumulado 2023–2025",
              "valor registrado (milhões, sem conversão cambial)")
    a1.legend(frameon=False, loc="lower right", fontsize=9, labelcolor=TEXTO_2)

    # (b) % sigiloso por ano, só para os órgãos do top 10 com sigilo relevante
    codigos = ranking.loc[ranking["percentual_sigiloso"] > 0, "codigo_orgao_superior"].head(4)
    for cor, codigo in zip([AZUL, LARANJA, VERDE, ROSA], codigos):
        d = anual[anual["codigo_orgao_superior"] == codigo].sort_values("ano")
        a2.plot(d["ano"], d["percentual_sigiloso"], color=cor, linewidth=2, marker="o", markersize=6,
                markeredgecolor=SUPERFICIE, markeredgewidth=1.5,
                label=abreviar(d["nome_orgao_superior"].iloc[0], 26))
    a2.set_xticks([2023, 2024, 2025])
    a2.set_ylim(0, 105)
    a2.set_ylabel("% do valor do órgão que é sigiloso", color=TEXTO_2, fontsize=9)
    estilizar(a2, "Parcela sigilosa por ano", grade="y")
    a2.legend(frameon=False, loc="center right", fontsize=8.5, labelcolor=TEXTO_2)

    fig.suptitle("CPGF: maiores órgãos e proporção de gastos sigilosos", x=0.01, ha="left",
                 fontsize=13, color=TEXTO, fontweight="bold")
    fig.text(0.01, 0.01, "Fonte: DW CPGF. Valores somam BRL e USD sem conversão; "
             "'Outros' (R$ 546) omitido por ser desprezível.", fontsize=8, color=MUDO)
    fig.tight_layout(rect=(0, 0.04, 1, 0.94))
    SAIDA.mkdir(parents=True, exist_ok=True)
    destino = SAIDA / "analise_gastos_por_orgao.png"
    fig.savefig(destino, dpi=150, facecolor=SUPERFICIE)
    print("Gráfico salvo em", destino)


if __name__ == "__main__":
    main()
