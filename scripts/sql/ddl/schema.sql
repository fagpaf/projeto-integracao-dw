PRAGMA foreign_keys = ON;

-- DIM_TEMPO (role-playing: data da transação e mês do extrato)
-- id_tempo = YYYYMMDD. O mês do extrato é ancorado no dia 01 (ex.: 20230101).
CREATE TABLE DIM_TEMPO (
    id_tempo       INTEGER PRIMARY KEY,   -- YYYYMMDD ou -1 (Não Informado / Sigiloso)
    data           DATE,                  -- NULL apenas para id_tempo = -1
    dia            INTEGER,
    mes            INTEGER,
    nome_mes       VARCHAR(30) NOT NULL,
    trimestre      INTEGER,
    semestre       INTEGER,
    ano            INTEGER,
    dia_semana     VARCHAR(20) NOT NULL,
    fim_de_semana  BOOLEAN,               -- 1 = sábado/domingo, 0 = dia útil
    CONSTRAINT uq_dim_tempo_data UNIQUE (data),
    CONSTRAINT ck_dim_tempo_mes CHECK (mes BETWEEN 1 AND 12),
    CONSTRAINT ck_dim_tempo_trimestre CHECK (trimestre BETWEEN 1 AND 4),
    CONSTRAINT ck_dim_tempo_semestre CHECK (semestre BETWEEN 1 AND 2)
);

-- DIM_ORGAO (hierarquia administrativa desnormalizada)
-- Códigos como texto para preservar zeros à esquerda.
CREATE TABLE DIM_ORGAO (
    id_orgao                INTEGER PRIMARY KEY,
    codigo_unidade_gestora  VARCHAR(20)  NOT NULL,
    nome_unidade_gestora    VARCHAR(255) NOT NULL,
    codigo_orgao            VARCHAR(20)  NOT NULL,
    nome_orgao              VARCHAR(255) NOT NULL,
    codigo_orgao_superior   VARCHAR(20)  NOT NULL,
    nome_orgao_superior     VARCHAR(255) NOT NULL,
    CONSTRAINT uq_dim_orgao_natural
        UNIQUE (codigo_unidade_gestora, codigo_orgao, codigo_orgao_superior)
);

-- DIM_PORTADOR (servidor responsável pelo cartão)
CREATE TABLE DIM_PORTADOR (
    id_portador    INTEGER PRIMARY KEY,
    cpf_mascarado  VARCHAR(20)  NOT NULL,   -- ex.: ***.562.861-**
    nome_portador  VARCHAR(255) NOT NULL,
    CONSTRAINT uq_dim_portador_natural UNIQUE (cpf_mascarado, nome_portador)
);

-- Códigos administrativos da fonte (-1, -2, -11) são membros regulares,
-- classificados como tipo_pessoa = 'Especial'.
CREATE TABLE DIM_FAVORECIDO (
    id_favorecido    INTEGER PRIMARY KEY,
    documento        VARCHAR(30)  NOT NULL,   -- texto: preserva zeros e máscaras
    nome_favorecido  VARCHAR(255) NOT NULL,
    tipo_pessoa      VARCHAR(20)  NOT NULL,
    CONSTRAINT uq_dim_favorecido_natural UNIQUE (documento, nome_favorecido),
    CONSTRAINT ck_dim_favorecido_tipo CHECK (tipo_pessoa IN ('PF', 'PJ', 'Especial'))
);

-- 'Outros' acomoda descrições novas da fonte ainda não classificadas.
CREATE TABLE DIM_TIPO_TRANSACAO (
    id_tipo_transacao   INTEGER PRIMARY KEY,
    descricao_original  VARCHAR(255) NOT NULL,
    categoria           VARCHAR(50)  NOT NULL,
    moeda               VARCHAR(20)  NOT NULL,
    canal               VARCHAR(50)  NOT NULL,
    CONSTRAINT uq_dim_tipo_transacao_desc UNIQUE (descricao_original),
    CONSTRAINT ck_dim_tipo_categoria CHECK (categoria IN ('Compra', 'Saque', 'Sigiloso', 'Outros')),
    CONSTRAINT ck_dim_tipo_moeda CHECK (moeda IN ('BRL', 'USD', 'Não Aplicável')),
    CONSTRAINT ck_dim_tipo_canal CHECK (canal IN ('Cartão / Fatura', 'Espécie / Autoatendimento', 'Sigiloso', 'Outros'))
);

-- Grão: 1 linha = 1 transação individual (compra ou saque).
-- Sem unicidade nas colunas de negócio: repetições exatas são mantidas
CREATE TABLE FATO_TRANSACAO_CPGF (
    id_transacao           INTEGER PRIMARY KEY,
    id_data_transacao      INTEGER        NOT NULL,   -- -1 se sigilosa
    id_mes_extrato         INTEGER        NOT NULL,
    id_orgao               INTEGER        NOT NULL,
    id_portador            INTEGER        NOT NULL,   -- -1 se sigilosa
    id_favorecido          INTEGER        NOT NULL,
    id_tipo_transacao      INTEGER        NOT NULL,
    valor_transacao        DECIMAL(15, 2) NOT NULL,   -- sem CHECK de sinal: estornos não verificados
    quantidade_transacoes  INTEGER        NOT NULL DEFAULT 1,
    CONSTRAINT ck_fato_quantidade CHECK (quantidade_transacoes = 1),
    CONSTRAINT fk_fato_data_transacao FOREIGN KEY (id_data_transacao) REFERENCES DIM_TEMPO (id_tempo),
    CONSTRAINT fk_fato_mes_extrato    FOREIGN KEY (id_mes_extrato)    REFERENCES DIM_TEMPO (id_tempo),
    CONSTRAINT fk_fato_orgao          FOREIGN KEY (id_orgao)          REFERENCES DIM_ORGAO (id_orgao),
    CONSTRAINT fk_fato_portador       FOREIGN KEY (id_portador)       REFERENCES DIM_PORTADOR (id_portador),
    CONSTRAINT fk_fato_favorecido     FOREIGN KEY (id_favorecido)     REFERENCES DIM_FAVORECIDO (id_favorecido),
    CONSTRAINT fk_fato_tipo_transacao FOREIGN KEY (id_tipo_transacao) REFERENCES DIM_TIPO_TRANSACAO (id_tipo_transacao)
);

-- Índices analíticos nas FKs da fato
-- Executar DEPOIS da carga da fato (criar índice antes deixa a carga lenta).
CREATE INDEX IF NOT EXISTS idx_fato_data_transacao ON FATO_TRANSACAO_CPGF (id_data_transacao);
CREATE INDEX IF NOT EXISTS idx_fato_mes_extrato    ON FATO_TRANSACAO_CPGF (id_mes_extrato);
CREATE INDEX IF NOT EXISTS idx_fato_orgao          ON FATO_TRANSACAO_CPGF (id_orgao);
CREATE INDEX IF NOT EXISTS idx_fato_portador       ON FATO_TRANSACAO_CPGF (id_portador);
CREATE INDEX IF NOT EXISTS idx_fato_favorecido     ON FATO_TRANSACAO_CPGF (id_favorecido);
CREATE INDEX IF NOT EXISTS idx_fato_tipo_transacao ON FATO_TRANSACAO_CPGF (id_tipo_transacao);
