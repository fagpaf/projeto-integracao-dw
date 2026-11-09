"""Inspeção simples do CPGF. Uso: python scripts/profile_cpgf.py [arquivos.csv ...]"""
from pathlib import Path
from contextlib import redirect_stdout
from datetime import datetime, timezone
from io import StringIO
import sys

import pandas as pd


def inspecionar_cpgf(caminho_csv: str):
    path = Path(caminho_csv)
    # Testa a leitura inteira. Latin-1 é fallback compatível, não prova do encoding.
    for encoding in ['utf-8-sig', 'latin-1']:
        try:
            df = pd.read_csv(path, sep=';', encoding=encoding, dtype=str,
                             keep_default_na=False)
            break
        except UnicodeDecodeError:
            continue
    if len(df.columns) == 1:
        raise ValueError(f'{path.name}: confira o separador; esperado ponto e vírgula.')

    # Preserva o original para contar duplicatas; normaliza só para a inspeção.
    total = len(df)
    duplicatas = int(df.duplicated().sum())
    dados = df.apply(lambda coluna: coluna.str.strip())
    vazios = dados.eq('').sum()
    nulos = dados.apply(lambda c: c.str.lower().isin(['null', 'nan', 'none', 'n/a'])).sum()
    campo = lambda nome: dados.get(nome, pd.Series('', index=df.index))
    sigilo = (campo('NOME PORTADOR').str.contains('sigilo', case=False)
              | campo('NOME FAVORECIDO').str.contains('sigilo', case=False)
              | campo('TRANSAÇÃO').str.contains('sigilo', case=False)
              | campo('CNPJ OU CPF FAVORECIDO').eq('-11'))

    def classificar(valor):
        if not valor:
            return 'VAZIO'
        if valor in ['-1', '-2', '-11']:
            return valor
        if valor.isdigit() and len(valor) in [11, 14]:
            return f'DOC_{len(valor)}_DIGITOS'
        return 'OUTRO'

    datas = pd.to_datetime(campo('DATA TRANSAÇÃO'), format='%d/%m/%Y', errors='coerce')
    valores = campo('VALOR TRANSAÇÃO')
    valor_valido = valores.str.fullmatch(r'-?(?:[0-9]+|[0-9]{1,3}(?:\.[0-9]{3})+),[0-9]{2}')
    anos = pd.to_numeric(campo('ANO EXTRATO'), errors='coerce')
    meses = pd.to_numeric(campo('MÊS EXTRATO'), errors='coerce')
    extrato_valido = anos.between(1, 9999) & anos.mod(1).eq(0) & meses.between(1, 12) & meses.mod(1).eq(0)
    comparaveis = datas.notna() & extrato_valido
    defasagem = (anos - datas.dt.year) * 12 + meses - datas.dt.month
    percentual = lambda qtd: f'{qtd / total:.2%}' if total else 'n/a'

    print(f'\n=== {path.name} ===')
    print(f'Encoding de leitura: {encoding} | Separador: ; | Shape: {df.shape}')
    print('Tipos na leitura: texto em todas as colunas (preserva zeros e máscaras).')
    print(f'Duplicatas excedentes: {duplicatas} ({percentual(duplicatas)})')
    print(f'Linhas sigilosas: {sigilo.sum()} ({percentual(sigilo.sum())})')
    print('Vazios por coluna:', vazios[vazios > 0].to_dict())
    print('Marcadores nulos por coluna:', nulos[nulos > 0].to_dict())
    print('Favorecido:', campo('CNPJ OU CPF FAVORECIDO').map(classificar).value_counts().to_dict())
    print('Datas preenchidas não convertíveis:', int((campo('DATA TRANSAÇÃO').ne('') & datas.isna()).sum()))
    print('Valores fora do formato decimal brasileiro:', int((~valor_valido).sum()))
    print('Intervalo das datas:', datas.min(), 'a', datas.max())
    print('Períodos de extrato inválidos:', int((~extrato_valido).sum()))
    print('Transações em mês anterior/posterior ao extrato:',
          int((comparaveis & defasagem.gt(0)).sum()), '/', int((comparaveis & defasagem.lt(0)).sum()))
    for ano in sorted(anos[extrato_valido].unique()):
        presentes = set(meses[extrato_valido & anos.eq(ano)].astype(int))
        print(f'{int(ano)}: meses sem registros:', sorted(set(range(1, 13)) - presentes))
    return df


def gerar_relatorio():
    raw = Path(__file__).resolve().parent.parent / 'data/raw'
    arquivos = sys.argv[1:] or [raw / f'{ano}_CPGF.csv' for ano in [2023, 2024, 2025]]
    print('DATA PROFILING E AUDITORIA TEMPORAL — CPGF')
    print('Gerado em (UTC):', datetime.now(timezone.utc).isoformat(timespec='seconds'))
    print('Arquivos analisados:')
    for arquivo in arquivos:
        print('-', Path(arquivo).resolve())
    anterior = None
    for arquivo in arquivos:
        df = inspecionar_cpgf(arquivo)
        colunas = list(df.columns)
        categorias = set(df['TRANSAÇÃO'].dropna()) if 'TRANSAÇÃO' in df else set()
        if anterior is not None:
            nome, esquema, dominio = anterior
            print(f'Comparação com {nome}:')
            print('Colunas adicionadas:', sorted(set(colunas) - set(esquema)))
            print('Colunas removidas:', sorted(set(esquema) - set(colunas)))
            print('Mesmo cabeçalho e ordem:', colunas == esquema)
            print('Categorias novas:', sorted(categorias - dominio))
            print('Categorias ausentes:', sorted(dominio - categorias))
        anterior = (Path(arquivo).name, colunas, categorias)
    print('\nObservações:')
    print('- Os dados originais foram preservados; este relatório não realiza tratamento.')
    print('- Repetições exatas não comprovam duplicidade de operações, especialmente sob sigilo.')
    print('- Latin-1 é fallback de leitura e não distingue Latin-1 de Windows-1252.')
    print('- Meses ausentes em amostras não comprovam lacunas na base completa.')


if __name__ == '__main__':
    # Captura o diagnóstico e só salva depois de concluir toda a inspeção.
    saida = StringIO()
    with redirect_stdout(saida):
        gerar_relatorio()
    texto = saida.getvalue()
    destino = Path(__file__).resolve().parent.parent / 'docs/relatorio-profiling.txt'
    destino.parent.mkdir(parents=True, exist_ok=True)
    destino.write_text(texto, encoding='utf-8')
    print(texto, end='')
    print(f'\nRelatório salvo em: {destino}')
