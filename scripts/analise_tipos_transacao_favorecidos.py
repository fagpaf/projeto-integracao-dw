"""Dois gráficos: compras × saques e concentração/perfil de favorecidos.

Executa as consultas de scripts/sql/queries/analise_tipos_transacao_favorecidos.sql
(sem alterá-las) e salva compras_saques.png e concentracao_favorecidos.png
em docs/analises/03_analise/.

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

plt.rcParams["text.parse_math"] = False  # R$ e INT$ são rótulos literais.
import pandas as pd

RAIZ = Path(__file__).resolve().parent.parent
ARQ_SQL = RAIZ / "scripts/sql/queries/analise_tipos_transacao_favorecidos.sql"
BANCO = Path(sys.argv[1]) if len(sys.argv) > 1 else RAIZ / "data/database/cpgf_dw.sqlite"
SAIDA = Path(sys.argv[2]) if len(sys.argv) > 2 else RAIZ / "docs/analises/03_analise"

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
    # O arquivo tem 3 consultas: [0] compras x saques, [1] top 10 favorecidos, [2] grupo operacional x tipo de favorecido.
    consultas, trecho = [], ""
    for linha in ARQ_SQL.read_text(encoding="utf-8").splitlines(keepends=True):
        trecho += linha
        if sqlite3.complete_statement(trecho):
            consultas.append(trecho)
            trecho = ""
    if trecho.strip():
        raise ValueError("SQL incompleto ao final do arquivo.")
    with sqlite3.connect(BANCO.resolve().as_uri() + "?mode=ro", uri=True) as con:
        compras_saques, ranking, distrib = (pd.read_sql(q, con) for q in consultas)

    fig_modalidades, (a0, a3) = plt.subplots(1, 2, figsize=(14, 5.5), facecolor=SUPERFICIE)

    # Quantidades são comparáveis sem inferir a moeda do valor registrado.
    for ax, grupo in zip((a0, a3), ("R$/ATM", "Exterior (INT$)")):
        dados = compras_saques[compras_saques["grupo_operacao"] == grupo]
        quantidades = dados.groupby("categoria")["quantidade_transacoes"].sum().reindex(["Compra", "Saque"], fill_value=0)
        ax.barh(quantidades.index, quantidades.values, color=[AZUL, LARANJA])
        for i, quantidade in enumerate(quantidades):
            ax.text(quantidade, i, f" {quantidade:,}".replace(",", "."), va="center")
        ax.set_xlim(0, max(quantidades.max() * 1.3, 1))
        estilizar(ax, f"Compras × saques — {grupo}", "Quantidade de transações (2023–2025)")

    fig_modalidades.suptitle("CPGF 2023–2025: compras × saques", x=0.01, ha="left",
                             fontsize=14, color=TEXTO, fontweight="bold")
    fig_modalidades.text(0.01, 0.01,
        "Fonte: DW CPGF. Comparação por quantidade, não valor. INT$ identifica exterior, não USD. Sigilo e Outros excluídos.",
        fontsize=9, color=MUDO)
    fig_modalidades.tight_layout(rect=(0, 0.06, 1, 0.92))

    fig_favorecidos, (a1, a2) = plt.subplots(1, 2, figsize=(18, 7), facecolor=SUPERFICIE,
                                          gridspec_kw={"width_ratios": [1.3, 1]})

    # (a) Top 10 favorecidos identificados (PF/PJ) no recorte R$/ATM
    r = ranking.iloc[::-1]
    y = range(len(r))
    a1.barh(y, r["valor_total"] / 1e6, color=AZUL, height=0.65)
    for i, (v, pct, n) in enumerate(zip(r["valor_total"] / 1e6, r["percentual_do_total"],
                                        r["quantidade_transacoes"])):
        a1.text(v + 0.05, i, f"{v:.2f} mi · {pct:.2f}% · {n:,} transações".replace(",", "."),
                va="center", fontsize=8.5, color=TEXTO_2)
    a1.set_yticks(list(y), [abreviar(n) for n in r["nome_favorecido"]])
    a1.set_xlim(0, (r["valor_total"] / 1e6).max() * 1.6)
    estilizar(a1, "Top 10 PF/PJ — compras/saques R$/ATM", "valor registrado (milhões, recorte R$/ATM)")

    # (b) Valor no recorte R$/ATM por tipo de favorecido (mostra o peso dos registros 'Especial')
    brl = distrib[distrib["grupo_operacao"] == "R$/ATM"].sort_values("valor_total")
    cores = {"PJ": AZUL, "PF": LARANJA, "Especial": VERDE}
    total = brl["valor_total"].sum()
    a2.barh(brl["tipo_pessoa"], brl["valor_total"] / 1e6,
            color=[cores[t] for t in brl["tipo_pessoa"]], height=0.55)
    for i, (v, n) in enumerate(zip(brl["valor_total"], brl["quantidade_transacoes"])):
        a2.text(v / 1e6 + 1.5, i, f"{v / 1e6:.1f} mi · {100 * v / total:.0f}% · {n:,} transações".replace(",", "."),
                va="center", fontsize=8.5, color=TEXTO_2)
    a2.set_xlim(0, brl["valor_total"].max() / 1e6 * 1.7)
    estilizar(a2, "R$/ATM por tipo de favorecido (compras + saques)", "valor registrado (milhões, recorte R$/ATM)")
    fig_favorecidos.suptitle("CPGF 2023–2025: concentração e perfil dos favorecidos", x=0.01, ha="left",
                 fontsize=13, color=TEXTO, fontweight="bold")
    fig_favorecidos.text(0.01, 0.01, "Fonte: DW CPGF. Percentual do ranking: total de PF/PJ no recorte R$/ATM. Sigilo, INT$ e Outros excluídos do ranking.",
             fontsize=8, color=MUDO)
    fig_favorecidos.tight_layout(rect=(0, 0.06, 1, 0.92))
    SAIDA.mkdir(parents=True, exist_ok=True)
    for figura, nome in [(fig_modalidades, "compras_saques.png"),
                         (fig_favorecidos, "concentracao_favorecidos.png")]:
        destino = SAIDA / nome
        figura.savefig(destino, dpi=150, facecolor=SUPERFICIE, bbox_inches="tight")
        plt.close(figura)
        print("Gráfico salvo em", destino)
    for nome, tabela in [("compras_saques", compras_saques), ("ranking_favorecidos", ranking), ("distribuicao_favorecidos", distrib)]:
        tabela.to_csv(SAIDA / f"{nome}.csv", index=False)


if __name__ == "__main__":
    main()
