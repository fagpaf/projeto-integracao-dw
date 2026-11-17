"""Gráfico da análise de tipos de transação e concentração em favorecidos.

Executa as consultas de scripts/sql/queries/analise_tipos_transacao_favorecidos.sql
(sem alterá-las) e salva docs/analises/analise_tipos_transacao_favorecidos.png.

Uso (na raiz do repositório):
    pip install pandas matplotlib
    python scripts/analise_tipos_transacao_favorecidos.py [banco.sqlite] [pasta_de_saida]
"""
import sqlite3
import sys
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import pandas as pd

RAIZ = Path(__file__).resolve().parent.parent
ARQ_SQL = RAIZ / "scripts/sql/queries/analise_tipos_transacao_favorecidos.sql"
BANCO = Path(sys.argv[1]) if len(sys.argv) > 1 else RAIZ / "data/database/cpgf_dw.sqlite"
SAIDA = Path(sys.argv[2]) if len(sys.argv) > 2 else RAIZ / "docs/analises"

AZUL, LARANJA, VERDE = "#2a78d6", "#eb6834", "#1baf7a"
SUPERFICIE, TEXTO, TEXTO_2, MUDO, GRADE = "#fcfcfb", "#0b0b0b", "#52514e", "#898781", "#e6e5e1"


def estilizar(ax, titulo, xlabel):
    ax.set_facecolor(SUPERFICIE)
    ax.set_title(titulo, loc="left", fontsize=11, color=TEXTO, fontweight="bold", pad=10)
    ax.set_xlabel(xlabel, color=TEXTO_2, fontsize=9)
    ax.tick_params(colors=MUDO, labelsize=9, length=0)
    ax.grid(axis="x", color=GRADE, linewidth=0.8)
    ax.set_axisbelow(True)
    for lado in ("top", "right", "left"):
        ax.spines[lado].set_visible(False)
    ax.spines["bottom"].set_color(GRADE)


def abreviar(nome, limite=40):
    return nome if len(nome) <= limite else nome[: limite - 1] + "…"


def main():
    # O arquivo tem 3 consultas: [0] compras x saques, [1] top 10 favorecidos, [2] moeda x tipo de favorecido.
    consultas = [p.strip() for p in ARQ_SQL.read_text(encoding="utf-8").split(";") if "SELECT" in p.upper()]
    with sqlite3.connect(BANCO) as con:
        _compras_saques, ranking, distrib = (pd.read_sql(q, con) for q in consultas)

    fig, (a1, a2) = plt.subplots(1, 2, figsize=(14, 5.5), facecolor=SUPERFICIE,
                                 gridspec_kw={"width_ratios": [1.3, 1]})

    # (a) Top 10 favorecidos identificados (PF/PJ) em BRL
    r = ranking.iloc[::-1]
    y = range(len(r))
    a1.barh(y, r["valor_total"] / 1e6, color=AZUL, height=0.65)
    for i, (v, pct, n) in enumerate(zip(r["valor_total"] / 1e6, r["percentual_do_total"],
                                        r["quantidade_transacoes"])):
        a1.text(v + 0.05, i, f"{v:.2f} mi · {pct:.2f}% · {n:,} transações".replace(",", "."),
                va="center", fontsize=8.5, color=TEXTO_2)
    a1.set_yticks(list(y), [abreviar(n) for n in r["nome_favorecido"]])
    a1.set_xlim(0, (r["valor_total"] / 1e6).max() * 1.6)
    estilizar(a1, "10 maiores favorecidos identificados (PF/PJ), em BRL", "valor registrado (R$ milhões)")

    # (b) Valor em BRL por tipo de favorecido (mostra o peso dos registros 'Especial')
    brl = distrib[distrib["moeda"] == "BRL"].sort_values("valor_total")
    cores = {"PJ": AZUL, "PF": LARANJA, "Especial": VERDE}
    total = brl["valor_total"].sum()
    a2.barh(brl["tipo_pessoa"], brl["valor_total"] / 1e6,
            color=[cores[t] for t in brl["tipo_pessoa"]], height=0.55)
    for i, (v, n) in enumerate(zip(brl["valor_total"], brl["quantidade_transacoes"])):
        a2.text(v / 1e6 + 1.5, i, f"{v / 1e6:.1f} mi · {100 * v / total:.0f}% · {n:,} transações".replace(",", "."),
                va="center", fontsize=8.5, color=TEXTO_2)
    a2.set_xlim(0, brl["valor_total"].max() / 1e6 * 1.7)
    estilizar(a2, "BRL por tipo de favorecido (compras + saques)", "valor registrado (R$ milhões)")
    usd = distrib[distrib["moeda"] == "USD"]
    if not usd.empty:
        a2.text(0.0, -0.26, f"USD ({int(usd['quantidade_transacoes'].sum()):,} transações) não aparece:\n"
                f"100% dos favorecidos em dólar são 'Especial'.".replace(",", "."),
                transform=a2.transAxes, fontsize=8.5, color=MUDO)

    fig.suptitle("CPGF: concentração em favorecidos e tipo de favorecido", x=0.01, ha="left",
                 fontsize=13, color=TEXTO, fontweight="bold")
    fig.text(0.01, 0.01, "Fonte: DW CPGF (categorias Compra e Saque). Moedas nunca somadas neste gráfico.",
             fontsize=8, color=MUDO)
    fig.tight_layout(rect=(0, 0.04, 1, 0.94))
    SAIDA.mkdir(parents=True, exist_ok=True)
    destino = SAIDA / "analise_tipos_transacao_favorecidos.png"
    fig.savefig(destino, dpi=150, facecolor=SUPERFICIE)
    print("Gráfico salvo em", destino)


if __name__ == "__main__":
    main()
