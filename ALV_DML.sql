-- =====================================================================
--  ALV - Serviço de Streaming
--  Script de criação das tabelas + carga de dados fictícios
--  Baseado no esquema relacional do arquivo ALV_Relacional.erdplus,
--  atualizado para a versão normalizada (3FN): Genero, Diretor e Ator
--  deixaram de ser atributos multivalorados em texto e viraram
--  entidades próprias, ligadas a Filme por tabelas associativas que
--  guardam apenas as chaves (FilmeID + GeneroID/DiretorID/AtorID).
--
--  Dialeto: MySQL / MariaDB (sintaxe próxima do ANSI SQL; para
--  PostgreSQL basta remover o bloco de FOREIGN_KEY_CHECKS e trocar
--  os comentários "ENGINE" caso existam).
--
--  ATENÇÃO: todos os dados abaixo são INVENTADOS, inclusive nomes,
--  e-mails, telefones, endereços e números de cartão. Nenhum deles
--  corresponde a pessoas ou empresas reais.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. Banco de dados
-- ---------------------------------------------------------------------
DROP DATABASE IF EXISTS ALV;
CREATE DATABASE ALV DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE ALV;

-- ---------------------------------------------------------------------
-- 1. CRIAÇÃO DAS TABELAS
--    (ordem respeita as dependências de chave estrangeira)
-- ---------------------------------------------------------------------

-- Tabelas independentes -----------------------------------------------

CREATE TABLE Plano (
    PlanoID      INT            NOT NULL,
    PlanoNome    VARCHAR(50)    NOT NULL,
    PrecoMensal  DECIMAL(10,2)  NOT NULL,
    CONSTRAINT pk_plano PRIMARY KEY (PlanoID),
    CONSTRAINT uq_plano_nome UNIQUE (PlanoNome),
    CONSTRAINT ck_plano_preco CHECK (PrecoMensal >= 0)
);

CREATE TABLE Cargo (
    CargoID    INT          NOT NULL,
    CargoNome  VARCHAR(60)  NOT NULL,
    CONSTRAINT pk_cargo PRIMARY KEY (CargoID),
    CONSTRAINT uq_cargo_nome UNIQUE (CargoNome)
);

CREATE TABLE Produtora (
    ProdutoraID    INT          NOT NULL,
    ProdutoraNome  VARCHAR(80)  NOT NULL,
    CONSTRAINT pk_produtora PRIMARY KEY (ProdutoraID),
    CONSTRAINT uq_produtora_nome UNIQUE (ProdutoraNome)
);

CREATE TABLE Genero (
    GeneroID    INT          NOT NULL,
    GeneroNome  VARCHAR(40)  NOT NULL,
    CONSTRAINT pk_genero PRIMARY KEY (GeneroID),
    CONSTRAINT uq_genero_nome UNIQUE (GeneroNome)
);

CREATE TABLE Diretor (
    DiretorID    INT          NOT NULL,
    DiretorNome  VARCHAR(80)  NOT NULL,
    CONSTRAINT pk_diretor PRIMARY KEY (DiretorID),
    CONSTRAINT uq_diretor_nome UNIQUE (DiretorNome)
);

CREATE TABLE Ator (
    AtorID    INT          NOT NULL,
    AtorNome  VARCHAR(80)  NOT NULL,
    CONSTRAINT pk_ator PRIMARY KEY (AtorID),
    CONSTRAINT uq_ator_nome UNIQUE (AtorNome)
);

CREATE TABLE Usuario (
    UsuarioID            INT           NOT NULL,
    UsuarioNome          VARCHAR(80)   NOT NULL,
    Email                VARCHAR(120)  NOT NULL,
    Telefone             VARCHAR(20)   NOT NULL,
    Senha                VARCHAR(100)  NOT NULL,
    -- Endereço
    Logradouro           VARCHAR(120)  NOT NULL,
    Bairro               VARCHAR(60)   NOT NULL,
    Municipio            VARCHAR(60)   NOT NULL,
    Estado               CHAR(2)       NOT NULL,
    -- Dados de pagamento (fictícios)
    NomeDoProprietario   VARCHAR(80)   NOT NULL,
    NumeroDoCartao       VARCHAR(19)   NOT NULL,
    DataVencimento       DATE          NOT NULL,
    CodigoDeSeguranca    CHAR(3)       NOT NULL,
    CONSTRAINT pk_usuario PRIMARY KEY (UsuarioID),
    CONSTRAINT uq_usuario_email UNIQUE (Email)
);

CREATE TABLE Filme (
    FilmeID          INT          NOT NULL,
    FilmeNome        VARCHAR(120) NOT NULL,
    DuracaoMin       INT          NOT NULL,
    AnoDeLancamento  INT          NOT NULL,
    CONSTRAINT pk_filme PRIMARY KEY (FilmeID),
    CONSTRAINT ck_filme_duracao CHECK (DuracaoMin > 0),
    CONSTRAINT ck_filme_ano CHECK (AnoDeLancamento BETWEEN 1888 AND 2100)
);

-- Tabelas com chave estrangeira ---------------------------------------

CREATE TABLE Assinatura (
    AssinaturaID  INT          NOT NULL,
    DataInicio    DATE         NOT NULL,
    DataFim       DATE         NOT NULL,
    Status        VARCHAR(20)  NOT NULL,
    PlanoID       INT          NOT NULL,
    CONSTRAINT pk_assinatura PRIMARY KEY (AssinaturaID),
    CONSTRAINT fk_assinatura_plano FOREIGN KEY (PlanoID)
        REFERENCES Plano (PlanoID),
    CONSTRAINT ck_assinatura_datas CHECK (DataFim >= DataInicio),
    CONSTRAINT ck_assinatura_status
        CHECK (Status IN ('Ativa','Cancelada','Suspensa','Expirada'))
);

CREATE TABLE Funcionario (
    FuncionarioID    INT            NOT NULL,
    FuncionarioNome  VARCHAR(80)    NOT NULL,
    Salario          DECIMAL(10,2)  NOT NULL,
    CargoID          INT            NOT NULL,
    CONSTRAINT pk_funcionario PRIMARY KEY (FuncionarioID),
    CONSTRAINT fk_funcionario_cargo FOREIGN KEY (CargoID)
        REFERENCES Cargo (CargoID),
    CONSTRAINT ck_funcionario_salario CHECK (Salario > 0)
);

CREATE TABLE Avaliacao (
    AvaliacaoID    INT   NOT NULL,
    Nota           INT   NOT NULL,          -- atributo "Nota0-5" do esquema
    Comentario     VARCHAR(500)  NULL,      -- atributo opcional
    AvaliacaoData  DATE  NOT NULL,
    UsuarioID      INT   NOT NULL,
    FilmeID        INT   NOT NULL,
    CONSTRAINT pk_avaliacao PRIMARY KEY (AvaliacaoID),
    CONSTRAINT fk_avaliacao_usuario FOREIGN KEY (UsuarioID)
        REFERENCES Usuario (UsuarioID),
    CONSTRAINT fk_avaliacao_filme FOREIGN KEY (FilmeID)
        REFERENCES Filme (FilmeID),
    CONSTRAINT ck_avaliacao_nota CHECK (Nota BETWEEN 0 AND 5)
);

-- Tabelas associativas (relacionamentos N:N) ---------------------------

CREATE TABLE UsrPagto (
    UsuarioID     INT            NOT NULL,
    AssinaturaID  INT            NOT NULL,
    ValorPago     DECIMAL(10,2)  NOT NULL,
    DataPagto     DATE           NOT NULL,
    CONSTRAINT pk_usrpagto PRIMARY KEY (UsuarioID, AssinaturaID),
    CONSTRAINT fk_usrpagto_usuario FOREIGN KEY (UsuarioID)
        REFERENCES Usuario (UsuarioID),
    CONSTRAINT fk_usrpagto_assinatura FOREIGN KEY (AssinaturaID)
        REFERENCES Assinatura (AssinaturaID),
    CONSTRAINT ck_usrpagto_valor CHECK (ValorPago >= 0)
);

CREATE TABLE Assiste (
    UsuarioID  INT   NOT NULL,
    FilmeID    INT   NOT NULL,
    Data       DATE  NOT NULL,
    CONSTRAINT pk_assiste PRIMARY KEY (UsuarioID, FilmeID),
    CONSTRAINT fk_assiste_usuario FOREIGN KEY (UsuarioID)
        REFERENCES Usuario (UsuarioID),
    CONSTRAINT fk_assiste_filme FOREIGN KEY (FilmeID)
        REFERENCES Filme (FilmeID)
);

CREATE TABLE Modera (
    FuncionarioID  INT  NOT NULL,
    AvaliacaoID    INT  NOT NULL,
    CONSTRAINT pk_modera PRIMARY KEY (FuncionarioID, AvaliacaoID),
    CONSTRAINT fk_modera_funcionario FOREIGN KEY (FuncionarioID)
        REFERENCES Funcionario (FuncionarioID),
    CONSTRAINT fk_modera_avaliacao FOREIGN KEY (AvaliacaoID)
        REFERENCES Avaliacao (AvaliacaoID)
);

CREATE TABLE GerenciaConteudo (
    FilmeID        INT  NOT NULL,
    FuncionarioID  INT  NOT NULL,
    CONSTRAINT pk_gerenciaconteudo PRIMARY KEY (FilmeID, FuncionarioID),
    CONSTRAINT fk_gerconteudo_filme FOREIGN KEY (FilmeID)
        REFERENCES Filme (FilmeID),
    CONSTRAINT fk_gerconteudo_funcionario FOREIGN KEY (FuncionarioID)
        REFERENCES Funcionario (FuncionarioID)
);

CREATE TABLE FilmPagtoRoy (
    ProdutoraID  INT            NOT NULL,
    FilmeID      INT            NOT NULL,
    ValorPagto   DECIMAL(12,2)  NOT NULL,
    DataPagto    DATE           NOT NULL,
    CONSTRAINT pk_filmpagtoroy PRIMARY KEY (ProdutoraID, FilmeID),
    CONSTRAINT fk_royalty_produtora FOREIGN KEY (ProdutoraID)
        REFERENCES Produtora (ProdutoraID),
    CONSTRAINT fk_royalty_filme FOREIGN KEY (FilmeID)
        REFERENCES Filme (FilmeID),
    CONSTRAINT ck_royalty_valor CHECK (ValorPagto >= 0)
);

-- Relacionamentos N:N de Filme com Genero / Diretor / Ator -------------
-- (antes eram atributos multivalorados; normalizados para a 3FN)

CREATE TABLE Filme_GeneroFilme (
    FilmeID   INT  NOT NULL,
    GeneroID  INT  NOT NULL,
    CONSTRAINT pk_filme_genero PRIMARY KEY (FilmeID, GeneroID),
    CONSTRAINT fk_filmegenero_filme FOREIGN KEY (FilmeID)
        REFERENCES Filme (FilmeID),
    CONSTRAINT fk_filmegenero_genero FOREIGN KEY (GeneroID)
        REFERENCES Genero (GeneroID)
);

CREATE TABLE Filme_DiretorFilme (
    FilmeID    INT  NOT NULL,
    DiretorID  INT  NOT NULL,
    CONSTRAINT pk_filme_diretor PRIMARY KEY (FilmeID, DiretorID),
    CONSTRAINT fk_filmediretor_filme FOREIGN KEY (FilmeID)
        REFERENCES Filme (FilmeID),
    CONSTRAINT fk_filmediretor_diretor FOREIGN KEY (DiretorID)
        REFERENCES Diretor (DiretorID)
);

CREATE TABLE Filme_AtorFilme (
    FilmeID  INT  NOT NULL,
    AtorID   INT  NOT NULL,
    CONSTRAINT pk_filme_ator PRIMARY KEY (FilmeID, AtorID),
    CONSTRAINT fk_filmeator_filme FOREIGN KEY (FilmeID)
        REFERENCES Filme (FilmeID),
    CONSTRAINT fk_filmeator_ator FOREIGN KEY (AtorID)
        REFERENCES Ator (AtorID)
);


-- =====================================================================
-- 2. CARGA DE DADOS FICTÍCIOS
-- =====================================================================

-- ---------------------------------------------------------------------
-- Plano
-- ---------------------------------------------------------------------
INSERT INTO Plano (PlanoID, PlanoNome, PrecoMensal) VALUES
(1, 'Mobile',        12.90),
(2, 'Basico',        18.90),
(3, 'Padrao',        29.90),
(4, 'Premium',       44.90),
(5, 'Premium Anual', 39.90);

-- ---------------------------------------------------------------------
-- Cargo
-- ---------------------------------------------------------------------
INSERT INTO Cargo (CargoID, CargoNome) VALUES
(1, 'Analista de Conteudo'),
(2, 'Moderador de Comunidade'),
(3, 'Curador de Catalogo'),
(4, 'Engenheiro de Dados'),
(5, 'Gerente de Operacoes'),
(6, 'Suporte ao Cliente');

-- ---------------------------------------------------------------------
-- Produtora
-- ---------------------------------------------------------------------
INSERT INTO Produtora (ProdutoraID, ProdutoraNome) VALUES
(1, 'Aurora Filmes'),
(2, 'Estudio Meridiano'),
(3, 'Vento Sul Producoes'),
(4, 'Cine Atlantico'),
(5, 'Nebula Studios'),
(6, 'Pampa Entretenimento');

-- ---------------------------------------------------------------------
-- Genero
-- ---------------------------------------------------------------------
INSERT INTO Genero (GeneroID, GeneroNome) VALUES
( 1, 'Acao'),
( 2, 'Aventura'),
( 3, 'Comedia'),
( 4, 'Drama'),
( 5, 'Familia'),
( 6, 'Ficcao'),
( 7, 'Historico'),
( 8, 'Policial'),
( 9, 'Romance'),
(10, 'Suspense'),
(11, 'Terror');

-- ---------------------------------------------------------------------
-- Diretor
-- ---------------------------------------------------------------------
INSERT INTO Diretor (DiretorID, DiretorNome) VALUES
(1, 'Renato Villaca'),
(2, 'Sofia Marchetti'),
(3, 'Amaury Colares'),
(4, 'Priscila Duarte'),
(5, 'Ivan Kowalski'),
(6, 'Tereza Bomfim');

-- ---------------------------------------------------------------------
-- Ator
-- ---------------------------------------------------------------------
INSERT INTO Ator (AtorID, AtorNome) VALUES
(1, 'Marina Teixeira'),
(2, 'Gustavo Rangel'),
(3, 'Clara Bonfim'),
(4, 'Leandro Pacheco'),
(5, 'Tiago Ferrari'),
(6, 'Yasmin Cordeiro'),
(7, 'Rodrigo Assumpcao'),
(8, 'Bianca Sarmento');

-- ---------------------------------------------------------------------
-- Usuario  (dados de cartão totalmente fictícios)
-- ---------------------------------------------------------------------
INSERT INTO Usuario (UsuarioID, UsuarioNome, Email, Telefone, Senha,
                     Logradouro, Bairro, Municipio, Estado,
                     NomeDoProprietario, NumeroDoCartao, DataVencimento, CodigoDeSeguranca) VALUES
( 1, 'Ana Clara Moreira',    'ana.moreira@exemplo.com',    '(11) 98123-4501', 'senha_hash_001',
      'Rua das Acacias, 128',       'Vila Mariana',   'Sao Paulo',      'SP', 'ANA C MOREIRA',     '4000000000000101', '2028-04-30', '101'),
( 2, 'Bruno Tavares',        'bruno.tavares@exemplo.com',  '(21) 99234-5602', 'senha_hash_002',
      'Av. Beira Mar, 900',         'Copacabana',     'Rio de Janeiro', 'RJ', 'BRUNO TAVARES',     '4000000000000202', '2027-09-30', '202'),
( 3, 'Carolina Prado',       'carol.prado@exemplo.com',    '(31) 98345-6703', 'senha_hash_003',
      'Rua Sabara, 45',             'Savassi',        'Belo Horizonte', 'MG', 'CAROLINA PRADO',    '4000000000000303', '2029-01-31', '303'),
( 4, 'Diego Fontenele',      'diego.fonte@exemplo.com',    '(85) 99456-7804', 'senha_hash_004',
      'Rua do Sol, 310',            'Aldeota',        'Fortaleza',      'CE', 'DIEGO FONTENELE',   '4000000000000404', '2026-11-30', '404'),
( 5, 'Elaine Bittencourt',   'elaine.b@exemplo.com',       '(41) 98567-8905', 'senha_hash_005',
      'Rua Pinheiro, 77',           'Batel',          'Curitiba',       'PR', 'ELAINE BITTENCOURT','4000000000000505', '2028-07-31', '505'),
( 6, 'Fabio Aguiar',         'fabio.aguiar@exemplo.com',   '(51) 99678-9006', 'senha_hash_006',
      'Av. Ipiranga, 2200',         'Azenha',         'Porto Alegre',   'RS', 'FABIO AGUIAR',      '4000000000000606', '2027-03-31', '606'),
( 7, 'Gabriela Sanches',     'gabi.sanches@exemplo.com',   '(62) 98789-0107', 'senha_hash_007',
      'Rua T-25, 501',              'Setor Bueno',    'Goiania',        'GO', 'GABRIELA SANCHES',  '4000000000000707', '2029-05-31', '707'),
( 8, 'Henrique Vilela',      'h.vilela@exemplo.com',       '(71) 99890-1208', 'senha_hash_008',
      'Rua da Paz, 18',             'Rio Vermelho',   'Salvador',       'BA', 'HENRIQUE VILELA',   '4000000000000808', '2026-12-31', '808'),
( 9, 'Isabela Rocha',        'isa.rocha@exemplo.com',      '(48) 98901-2309', 'senha_hash_009',
      'Rua das Gaivotas, 64',       'Ingleses',       'Florianopolis',  'SC', 'ISABELA ROCHA',     '4000000000000909', '2028-02-29', '909'),
(10, 'Joao Pedro Lacerda',   'jp.lacerda@exemplo.com',     '(81) 99012-3410', 'senha_hash_010',
      'Av. Boa Viagem, 1420',       'Boa Viagem',     'Recife',         'PE', 'JOAO P LACERDA',    '4000000000001010', '2027-08-31', '110'),
(11, 'Karina Delgado',       'karina.d@exemplo.com',       '(19) 98123-4511', 'senha_hash_011',
      'Rua Barao de Jaguara, 233',  'Centro',         'Campinas',       'SP', 'KARINA DELGADO',    '4000000000001111', '2029-10-31', '111'),
(12, 'Lucas Mendonca',       'lucas.mend@exemplo.com',     '(61) 99234-5612', 'senha_hash_012',
      'SQN 210, Bloco B',           'Asa Norte',      'Brasilia',       'DF', 'LUCAS MENDONCA',    '4000000000001212', '2026-06-30', '112'),
(13, 'Mariana Estrela',      'mari.estrela@exemplo.com',   '(92) 98345-6713', 'senha_hash_013',
      'Rua Rio Negro, 88',          'Adrianopolis',   'Manaus',         'AM', 'MARIANA ESTRELA',   '4000000000001313', '2028-09-30', '113'),
(14, 'Nelson Bacelar',       'nelson.b@exemplo.com',       '(27) 99456-7814', 'senha_hash_014',
      'Rua das Palmeiras, 12',      'Praia do Canto', 'Vitoria',        'ES', 'NELSON BACELAR',    '4000000000001414', '2027-01-31', '114'),
(15, 'Olivia Ferraz',        'olivia.ferraz@exemplo.com',  '(98) 98567-8915', 'senha_hash_015',
      'Av. Litoranea, 505',         'Calhau',         'Sao Luis',       'MA', 'OLIVIA FERRAZ',     '4000000000001515', '2029-03-31', '115');

-- ---------------------------------------------------------------------
-- Filme
-- ---------------------------------------------------------------------
INSERT INTO Filme (FilmeID, FilmeNome, DuracaoMin, AnoDeLancamento) VALUES
( 1, 'O Ultimo Farol',            118, 2018),
( 2, 'Cidade de Vidro',           132, 2020),
( 3, 'Noite em Aurora',            97, 2016),
( 4, 'Ecos do Deserto',           145, 2021),
( 5, 'A Colheita Vermelha',       108, 2019),
( 6, 'Ninguem Volta de Marte',    156, 2022),
( 7, 'Pequenos Desastres',         92, 2017),
( 8, 'O Silencio das Mares',      121, 2015),
( 9, 'Corrida Contra a Chuva',    101, 2023),
(10, 'Cafe com Estrelas',          88, 2019),
(11, 'A Setima Estacao',          134, 2014),
(12, 'Fogo de Palha',             110, 2020),
(13, 'Sombras de Neon',           127, 2024),
(14, 'O Jardim Suspenso',          99, 2013),
(15, 'Maquina do Tempo Quebrada', 141, 2022),
(16, 'Verao de 1998',             105, 2018),
(17, 'Rota 12',                    95, 2021),
(18, 'A Casa Sem Janelas',        113, 2016),
(19, 'Cartas Para Ninguem',       124, 2023),
(20, 'O Peso do Ceu',             149, 2025);

-- ---------------------------------------------------------------------
-- Assinatura
-- ---------------------------------------------------------------------
INSERT INTO Assinatura (AssinaturaID, DataInicio, DataFim, Status, PlanoID) VALUES
( 1, '2024-01-15', '2025-01-15', 'Expirada',  3),
( 2, '2024-02-01', '2025-02-01', 'Expirada',  2),
( 3, '2023-11-10', '2024-11-10', 'Expirada',  4),
( 4, '2025-03-05', '2026-03-05', 'Ativa',     1),
( 5, '2024-06-20', '2025-06-20', 'Cancelada', 3),
( 6, '2025-01-01', '2026-01-01', 'Ativa',     5),
( 7, '2024-08-12', '2025-08-12', 'Ativa',     2),
( 8, '2025-02-18', '2026-02-18', 'Ativa',     4),
( 9, '2024-04-30', '2025-04-30', 'Suspensa',  1),
(10, '2025-05-09', '2026-05-09', 'Ativa',     3),
(11, '2023-09-22', '2024-09-22', 'Expirada',  4),
(12, '2025-06-14', '2026-06-14', 'Ativa',     2),
(13, '2024-10-03', '2025-10-03', 'Cancelada', 5),
(14, '2025-04-27', '2026-04-27', 'Ativa',     3),
(15, '2024-12-08', '2025-12-08', 'Ativa',     1),
(16, '2025-01-16', '2026-01-16', 'Ativa',     4),
(17, '2024-11-11', '2025-11-11', 'Ativa',     3),
(18, '2025-07-01', '2026-07-01', 'Ativa',     2),
(19, '2025-08-20', '2026-08-20', 'Ativa',     5),
(20, '2025-04-05', '2026-04-05', 'Suspensa',  4);

-- ---------------------------------------------------------------------
-- Funcionario
-- ---------------------------------------------------------------------
INSERT INTO Funcionario (FuncionarioID, FuncionarioNome, Salario, CargoID) VALUES
( 1, 'Beatriz Salgueiro',    4200.00, 2),
( 2, 'Rafael Antunes',       4350.00, 2),
( 3, 'Camila Nogueira',      5800.00, 1),
( 4, 'Diego Vasconcelos',    6100.00, 3),
( 5, 'Larissa Peixoto',      6250.00, 3),
( 6, 'Otavio Bandeira',      9800.00, 4),
( 7, 'Helena Furtado',      12500.00, 5),
( 8, 'Marcelo Quintela',     3100.00, 6),
( 9, 'Taina Reboucas',       3250.00, 6),
(10, 'Vinicius Aragao',      5600.00, 1);

-- ---------------------------------------------------------------------
-- Avaliacao
-- ---------------------------------------------------------------------
INSERT INTO Avaliacao (AvaliacaoID, Nota, Comentario, AvaliacaoData, UsuarioID, FilmeID) VALUES
( 1, 5, 'Fotografia impecavel do inicio ao fim.',        '2025-02-11',  1,  1),
( 2, 4, 'Boa historia, final um pouco apressado.',       '2025-02-18',  1,  3),
( 3, 3, NULL,                                            '2025-03-02',  1,  5),
( 4, 5, 'Melhor filme que assisti no ano.',              '2025-01-27',  2,  2),
( 5, 2, 'Ritmo lento demais para o meu gosto.',          '2025-03-14',  2,  4),
( 6, 4, 'Trilha sonora excelente.',                      '2025-04-09',  3,  9),
( 7, 5, 'Leve e divertido, recomendo.',                  '2025-04-21',  3, 10),
( 8, 3, NULL,                                            '2025-05-05',  4, 11),
( 9, 4, 'Atuacoes muito convincentes.',                  '2025-05-19',  4, 12),
(10, 5, 'Visual futurista de encher os olhos.',          '2025-06-01',  5, 13),
(11, 1, 'Nao consegui terminar.',                        '2025-06-15',  5, 14),
(12, 4, 'Roteiro criativo, efeitos medianos.',           '2025-06-28',  6, 15),
(13, 5, 'Ficcao cientifica do jeito certo.',             '2025-07-04',  6,  6),
(14, 3, 'Comeco fraco, mas melhora bastante.',           '2025-07-12',  7, 16),
(15, 4, NULL,                                            '2025-07-19',  7, 17),
(16, 2, 'Esperava mais do desfecho.',                    '2025-07-25',  8, 18),
(17, 5, 'Um classico moderno.',                          '2025-07-30',  8,  8),
(18, 4, 'Emocionante sem ser apelativo.',                '2025-08-02',  9, 19),
(19, 5, 'Elenco perfeito.',                              '2025-08-05',  9, 20),
(20, 3, NULL,                                            '2025-08-06', 10,  1),
(21, 4, 'Assisti duas vezes, vale a pena.',              '2025-08-07', 11,  3),
(22, 5, 'Direcao de arte espetacular.',                  '2025-08-08', 12, 13),
(23, 2, 'Personagens pouco desenvolvidos.',              '2025-08-09', 13,  5),
(24, 4, 'Bom para assistir em familia.',                 '2025-08-10', 14, 15),
(25, 5, 'Encerramento perfeito para a historia.',        '2025-08-11', 15, 20);

-- ---------------------------------------------------------------------
-- UsrPagto  (pagamento de cada usuário por assinatura)
-- ---------------------------------------------------------------------
INSERT INTO UsrPagto (UsuarioID, AssinaturaID, ValorPago, DataPagto) VALUES
( 1,  1, 29.90, '2024-01-15'),
( 2,  2, 18.90, '2024-02-01'),
( 3,  3, 44.90, '2023-11-10'),
( 4,  4, 12.90, '2025-03-05'),
( 5,  5, 29.90, '2024-06-20'),
( 6,  6, 39.90, '2025-01-01'),
( 7,  7, 18.90, '2024-08-12'),
( 8,  8, 44.90, '2025-02-18'),
( 9,  9, 12.90, '2024-04-30'),
(10, 10, 29.90, '2025-05-09'),
(11, 11, 44.90, '2023-09-22'),
(12, 12, 18.90, '2025-06-14'),
(13, 13, 39.90, '2024-10-03'),
(14, 14, 29.90, '2025-04-27'),
(15, 15, 12.90, '2024-12-08'),
( 1, 16, 44.90, '2025-01-16'),
( 3, 17, 29.90, '2024-11-11'),
( 5, 18, 18.90, '2025-07-01'),
( 7, 19, 39.90, '2025-08-20'),
( 9, 20, 44.90, '2025-04-05');

-- ---------------------------------------------------------------------
-- Assiste  (histórico de exibições)
-- ---------------------------------------------------------------------
INSERT INTO Assiste (UsuarioID, FilmeID, Data) VALUES
( 1,  1, '2025-02-10'), ( 1,  3, '2025-02-17'), ( 1,  5, '2025-03-01'), ( 1,  7, '2025-03-20'),
( 2,  2, '2025-01-26'), ( 2,  4, '2025-03-13'), ( 2,  6, '2025-04-02'),
( 3,  1, '2025-04-05'), ( 3,  9, '2025-04-08'), ( 3, 10, '2025-04-20'),
( 4, 11, '2025-05-04'), ( 4, 12, '2025-05-18'),
( 5,  5, '2025-05-30'), ( 5, 13, '2025-06-01'), ( 5, 14, '2025-06-14'),
( 6,  6, '2025-07-03'), ( 6, 15, '2025-06-27'),
( 7,  7, '2025-07-10'), ( 7, 16, '2025-07-11'), ( 7, 17, '2025-07-18'),
( 8,  8, '2025-07-29'), ( 8, 18, '2025-07-24'),
( 9,  9, '2025-08-01'), ( 9, 19, '2025-08-01'), ( 9, 20, '2025-08-04'),
(10,  1, '2025-08-05'), (10,  2, '2025-08-06'), (10, 10, '2025-07-15'),
(11,  3, '2025-08-06'), (11, 11, '2025-07-22'),
(12,  4, '2025-08-03'), (12, 12, '2025-07-28'), (12, 13, '2025-08-07'),
(13,  5, '2025-08-08'), (13, 13, '2025-08-02'),
(14,  6, '2025-08-09'), (14, 14, '2025-07-30'), (14, 15, '2025-08-09'),
(15,  7, '2025-08-10'), (15, 15, '2025-08-11'), (15, 20, '2025-08-10');

-- ---------------------------------------------------------------------
-- Modera  (funcionários que moderaram avaliações)
-- ---------------------------------------------------------------------
INSERT INTO Modera (FuncionarioID, AvaliacaoID) VALUES
(1,  1), (1,  4), (1,  7), (1, 13),
(2,  2), (2,  5), (2, 11), (2, 16),
(8,  3), (8,  9), (8, 20),
(9,  6), (9, 14), (9, 23),
(7, 19);

-- ---------------------------------------------------------------------
-- GerenciaConteudo  (funcionários responsáveis por cada filme)
-- ---------------------------------------------------------------------
INSERT INTO GerenciaConteudo (FilmeID, FuncionarioID) VALUES
( 1,  3), ( 2,  3), ( 3,  3), ( 4,  4), ( 5,  4),
( 6,  4), ( 7,  5), ( 8,  5), ( 9,  5), (10, 10),
(11, 10), (12, 10), (13,  6), (14,  6), (15,  6),
(16,  3), (17,  4), (18,  5), (19, 10), (20,  6),
( 1, 10), (13,  3);

-- ---------------------------------------------------------------------
-- FilmPagtoRoy  (royalties pagos às produtoras)
-- ---------------------------------------------------------------------
INSERT INTO FilmPagtoRoy (ProdutoraID, FilmeID, ValorPagto, DataPagto) VALUES
(1,  1, 125000.00, '2025-01-10'),
(1,  3,  98000.00, '2025-01-10'),
(1, 11, 143500.00, '2025-02-10'),
(1, 19, 210000.00, '2025-03-10'),
(2,  2, 187300.00, '2025-01-15'),
(2,  9, 156800.00, '2025-02-15'),
(2, 18,  99450.00, '2025-03-15'),
(3,  4, 232000.00, '2025-01-20'),
(3,  8, 118700.00, '2025-02-20'),
(3, 14,  87600.00, '2025-03-20'),
(4,  5, 134200.00, '2025-01-25'),
(4, 12, 121900.00, '2025-02-25'),
(4, 17, 105300.00, '2025-03-25'),
(5,  6, 305000.00, '2025-01-30'),
(5, 13, 289400.00, '2025-02-28'),
(5, 15, 264800.00, '2025-03-30'),
(5, 20, 412000.00, '2025-04-30'),
(6,  7,  76500.00, '2025-02-05'),
(6, 10,  81200.00, '2025-03-05'),
(6, 16,  93700.00, '2025-04-05');

-- ---------------------------------------------------------------------
-- Filme_GeneroFilme
-- ---------------------------------------------------------------------
INSERT INTO Filme_GeneroFilme (FilmeID, GeneroID) VALUES
( 1,  4), ( 1, 10),   -- Drama, Suspense
( 2,  6), ( 2,  8),   -- Ficcao, Policial
( 3,  9), ( 3,  4),   -- Romance, Drama
( 4,  2), ( 4,  1),   -- Aventura, Acao
( 5, 11), ( 5, 10),   -- Terror, Suspense
( 6,  6), ( 6,  2),   -- Ficcao, Aventura
( 7,  3),             -- Comedia
( 8,  4), ( 8,  9),   -- Drama, Romance
( 9,  3), ( 9,  9),   -- Comedia, Romance
(10,  3), (10,  5),   -- Comedia, Familia
(11,  4), (11,  7),   -- Drama, Historico
(12,  8), (12,  1),   -- Policial, Acao
(13,  6), (13, 10),   -- Ficcao, Suspense
(14,  4),             -- Drama
(15,  6), (15,  3),   -- Ficcao, Comedia
(16,  9), (16,  4),   -- Romance, Drama
(17,  1), (17,  2),   -- Acao, Aventura
(18, 11),             -- Terror
(19,  4), (19,  9),   -- Drama, Romance
(20,  4), (20,  7);   -- Drama, Historico

-- ---------------------------------------------------------------------
-- Filme_DiretorFilme
-- ---------------------------------------------------------------------
INSERT INTO Filme_DiretorFilme (FilmeID, DiretorID) VALUES
( 1, 1),
( 2, 2),
( 3, 1),
( 4, 3),
( 5, 4),
( 6, 5),
( 7, 6),
( 8, 3),
( 9, 2),
(10, 6),
(11, 1),
(12, 4),
(13, 5),
(14, 3),
(15, 5), (15, 2),
(16, 6),
(17, 4),
(18, 2),
(19, 1), (19, 6),
(20, 5);

-- ---------------------------------------------------------------------
-- Filme_AtorFilme
-- ---------------------------------------------------------------------
INSERT INTO Filme_AtorFilme (FilmeID, AtorID) VALUES
( 1, 1), ( 1, 2), ( 1, 3),
( 2, 4), ( 2, 1),
( 3, 3), ( 3, 5),
( 4, 2), ( 4, 6), ( 4, 4),
( 5, 6), ( 5, 5),
( 6, 1), ( 6, 7), ( 6, 3),
( 7, 8), ( 7, 5),
( 8, 7), ( 8, 3),
( 9, 8), ( 9, 4),
(10, 8), (10, 2),
(11, 1), (11, 7),
(12, 5), (12, 6),
(13, 4), (13, 6), (13, 1),
(14, 3), (14, 7),
(15, 2), (15, 8),
(16, 8), (16, 5),
(17, 6), (17, 2),
(18, 7), (18, 1),
(19, 3), (19, 4),
(20, 1), (20, 6), (20, 7);


-- =====================================================================
-- 3. CONSULTAS DE VERIFICAÇÃO (opcionais)
-- =====================================================================

-- Quantidade de linhas por tabela
SELECT 'Plano' AS Tabela, COUNT(*) AS Registros FROM Plano
UNION ALL SELECT 'Cargo',              COUNT(*) FROM Cargo
UNION ALL SELECT 'Produtora',          COUNT(*) FROM Produtora
UNION ALL SELECT 'Genero',             COUNT(*) FROM Genero
UNION ALL SELECT 'Diretor',            COUNT(*) FROM Diretor
UNION ALL SELECT 'Ator',               COUNT(*) FROM Ator
UNION ALL SELECT 'Usuario',            COUNT(*) FROM Usuario
UNION ALL SELECT 'Filme',              COUNT(*) FROM Filme
UNION ALL SELECT 'Assinatura',         COUNT(*) FROM Assinatura
UNION ALL SELECT 'Funcionario',        COUNT(*) FROM Funcionario
UNION ALL SELECT 'Avaliacao',          COUNT(*) FROM Avaliacao
UNION ALL SELECT 'UsrPagto',           COUNT(*) FROM UsrPagto
UNION ALL SELECT 'Assiste',            COUNT(*) FROM Assiste
UNION ALL SELECT 'Modera',             COUNT(*) FROM Modera
UNION ALL SELECT 'GerenciaConteudo',   COUNT(*) FROM GerenciaConteudo
UNION ALL SELECT 'FilmPagtoRoy',       COUNT(*) FROM FilmPagtoRoy
UNION ALL SELECT 'Filme_GeneroFilme',  COUNT(*) FROM Filme_GeneroFilme
UNION ALL SELECT 'Filme_DiretorFilme', COUNT(*) FROM Filme_DiretorFilme
UNION ALL SELECT 'Filme_AtorFilme',    COUNT(*) FROM Filme_AtorFilme;

-- Nota média por filme
-- SELECT f.FilmeNome, ROUND(AVG(a.Nota), 2) AS NotaMedia, COUNT(*) AS QtdAvaliacoes
-- FROM Filme f JOIN Avaliacao a ON a.FilmeID = f.FilmeID
-- GROUP BY f.FilmeID, f.FilmeNome
-- ORDER BY NotaMedia DESC;

-- Total pago por usuário
-- SELECT u.UsuarioNome, SUM(p.ValorPago) AS TotalPago
-- FROM Usuario u JOIN UsrPagto p ON p.UsuarioID = u.UsuarioID
-- GROUP BY u.UsuarioID, u.UsuarioNome
-- ORDER BY TotalPago DESC;

-- Filmes mais assistidos
-- SELECT f.FilmeNome, COUNT(*) AS Exibicoes
-- FROM Filme f JOIN Assiste s ON s.FilmeID = f.FilmeID
-- GROUP BY f.FilmeID, f.FilmeNome
-- ORDER BY Exibicoes DESC;

-- Ficha de um filme com generos, diretores e atores (novo modelo 3FN)
-- SELECT f.FilmeNome,
--        GROUP_CONCAT(DISTINCT g.GeneroNome  ORDER BY g.GeneroNome  SEPARATOR ', ') AS Generos,
--        GROUP_CONCAT(DISTINCT d.DiretorNome ORDER BY d.DiretorNome SEPARATOR ', ') AS Diretores,
--        GROUP_CONCAT(DISTINCT a.AtorNome    ORDER BY a.AtorNome    SEPARATOR ', ') AS Elenco
-- FROM Filme f
-- LEFT JOIN Filme_GeneroFilme  fg ON fg.FilmeID = f.FilmeID
-- LEFT JOIN Genero             g  ON g.GeneroID = fg.GeneroID
-- LEFT JOIN Filme_DiretorFilme fd ON fd.FilmeID = f.FilmeID
-- LEFT JOIN Diretor            d  ON d.DiretorID = fd.DiretorID
-- LEFT JOIN Filme_AtorFilme    fa ON fa.FilmeID = f.FilmeID
-- LEFT JOIN Ator               a  ON a.AtorID = fa.AtorID
-- GROUP BY f.FilmeID, f.FilmeNome
-- ORDER BY f.FilmeNome;

-- Quantidade de filmes por genero
-- SELECT g.GeneroNome, COUNT(*) AS QtdFilmes
-- FROM Genero g JOIN Filme_GeneroFilme fg ON fg.GeneroID = g.GeneroID
-- GROUP BY g.GeneroID, g.GeneroNome
-- ORDER BY QtdFilmes DESC;
