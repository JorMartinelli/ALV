-- =====================================================================
-- 0. CRIAÇÃO DO BANCO DE DADOS DO DATA WAREHOUSE (DW)
-- =====================================================================
DROP DATABASE IF EXISTS ALV_DW;
CREATE DATABASE ALV_DW DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE ALV_DW;

-- =====================================================================
-- 1. CRIAÇÃO DAS TABELAS DIMENSÃO (Star Schema)
-- =====================================================================

CREATE TABLE Dim_Tempo (
    SK_Tempo INT AUTO_INCREMENT,
    Data_Completa DATE NOT NULL,
    Dia_Semana INT,
    Dia INT,
    Mes INT,
    Trimestre INT,
    Ano INT,
    CONSTRAINT pk_dim_tempo PRIMARY KEY (SK_Tempo)
);

CREATE TABLE Dim_Cliente (
    SK_Cliente INT AUTO_INCREMENT,
    ID_Cliente_Origem INT NOT NULL,
    Nome VARCHAR(80),
    Logradouro VARCHAR(120),
    Bairro VARCHAR(60),
    Municipio VARCHAR(60),
    Estado CHAR(2),
    CONSTRAINT pk_dim_cliente PRIMARY KEY (SK_Cliente)
);

CREATE TABLE Dim_Filme (
    SK_Filme INT AUTO_INCREMENT,
    ID_Filme_Origem INT NOT NULL,
    Titulo VARCHAR(120),
    Duracao_Minutos INT,
    Diretor_Principal VARCHAR(80),
    CONSTRAINT pk_dim_filme PRIMARY KEY (SK_Filme)
);

CREATE TABLE Dim_Produtora (
    SK_Produtora INT AUTO_INCREMENT,
    ID_Produtora_Origem INT NOT NULL,
    Nome_Produtora VARCHAR(80),
    CONSTRAINT pk_dim_produtora PRIMARY KEY (SK_Produtora)
);

CREATE TABLE Dim_Genero (
    SK_Genero INT AUTO_INCREMENT,
    ID_Genero_Origem INT NOT NULL,
    Nome_Genero VARCHAR(40),
    CONSTRAINT pk_dim_genero PRIMARY KEY (SK_Genero)
);

-- =====================================================================
-- 2. CRIAÇÃO DAS TABELAS FATO
-- =====================================================================

CREATE TABLE Fato_Receita (
    SK_Cliente INT,
    SK_Tempo INT,
    ID_Assinatura INT,
    Hora TIME,
    Valor_Pago DECIMAL(10,2),
    CONSTRAINT fk_fato_receita_cliente FOREIGN KEY (SK_Cliente) REFERENCES Dim_Cliente (SK_Cliente),
    CONSTRAINT fk_fato_receita_tempo FOREIGN KEY (SK_Tempo) REFERENCES Dim_Tempo (SK_Tempo)
);

CREATE TABLE Fato_Avaliacao (
    SK_Cliente INT,
    SK_Filme INT,
    SK_Produtora INT,
    SK_Genero INT,
    SK_Tempo INT,
    Hora_Avaliacao TIME,
    Nota INT,
    CONSTRAINT fk_fato_aval_cliente FOREIGN KEY (SK_Cliente) REFERENCES Dim_Cliente (SK_Cliente),
    CONSTRAINT fk_fato_aval_filme FOREIGN KEY (SK_Filme) REFERENCES Dim_Filme (SK_Filme),
    CONSTRAINT fk_fato_aval_produtora FOREIGN KEY (SK_Produtora) REFERENCES Dim_Produtora (SK_Produtora),
    CONSTRAINT fk_fato_aval_genero FOREIGN KEY (SK_Genero) REFERENCES Dim_Genero (SK_Genero),
    CONSTRAINT fk_fato_aval_tempo FOREIGN KEY (SK_Tempo) REFERENCES Dim_Tempo (SK_Tempo)
);

-- =====================================================================
-- 3. PROCESSO DE ETL (EXTRACT, TRANSFORM E LOAD)
-- =====================================================================

-- ---------------------------------------------------------------------
-- 3.1 Carga Dim_Tempo (Gerando datas de 2020 a 2025 usando CTE Recursiva)
-- ---------------------------------------------------------------------
INSERT INTO Dim_Tempo (Data_Completa, Dia_Semana, Dia, Mes, Trimestre, Ano)
WITH RECURSIVE Datas AS (
    SELECT CAST('2020-01-01' AS DATE) AS DataBase
    UNION ALL
    SELECT DATE_ADD(DataBase, INTERVAL 1 DAY)
    FROM Datas
    WHERE DataBase < '2025-12-31'
)
SELECT 
    DataBase, 
    DAYOFWEEK(DataBase), 
    DAY(DataBase), 
    MONTH(DataBase), 
    QUARTER(DataBase), 
    YEAR(DataBase)
FROM Datas;

-- ---------------------------------------------------------------------
-- 3.2 Carga Dim_Cliente
-- ---------------------------------------------------------------------
INSERT INTO Dim_Cliente (ID_Cliente_Origem, Nome, Logradouro, Bairro, Municipio, Estado)
SELECT 
    UsuarioID, 
    UsuarioNome, 
    Logradouro, 
    Bairro, 
    Municipio, 
    COALESCE(Estado, 'NA') -- Transformação: Tratamento de nulos no Estado
FROM ALV.Usuario;

-- ---------------------------------------------------------------------
-- 3.3 Carga Dim_Filme
-- Nota: Como um filme pode ter vários diretores, estamos selecionando o 
-- primeiro diretor encontrado para simplificar a dimensão, conforme o guia.
-- ---------------------------------------------------------------------
INSERT INTO Dim_Filme (ID_Filme_Origem, Titulo, Duracao_Minutos, Diretor_Principal)
SELECT 
    f.FilmeID, 
    f.FilmeNome, 
    f.DuracaoMin,
    (SELECT d.DiretorNome 
     FROM ALV.Filme_DiretorFilme fd
     JOIN ALV.Diretor d ON fd.DiretorID = d.DiretorID
     WHERE fd.FilmeID = f.FilmeID 
     LIMIT 1) AS Diretor_Principal
FROM ALV.Filme f;

-- ---------------------------------------------------------------------
-- 3.4 Carga Dim_Produtora
-- ---------------------------------------------------------------------
INSERT INTO Dim_Produtora (ID_Produtora_Origem, Nome_Produtora)
SELECT ProdutoraID, ProdutoraNome
FROM ALV.Produtora;

-- ---------------------------------------------------------------------
-- 3.5 Carga Dim_Genero
-- ---------------------------------------------------------------------
INSERT INTO Dim_Genero (ID_Genero_Origem, Nome_Genero)
SELECT GeneroID, GeneroNome
FROM ALV.Genero;

-- ---------------------------------------------------------------------
-- 3.6 Carga Fato_Receita
-- Cruzando as chaves de origem para encontrar as SKs no DW
-- ---------------------------------------------------------------------
INSERT INTO Fato_Receita (SK_Cliente, SK_Tempo, ID_Assinatura, Hora, Valor_Pago)
SELECT 
    c.SK_Cliente,
    t.SK_Tempo,
    p.AssinaturaID,
    '00:00:00' AS Hora, -- Fonte não possui hora de transação, padronizado
    p.ValorPago
FROM ALV.UsrPagto p
JOIN Dim_Cliente c ON p.UsuarioID = c.ID_Cliente_Origem
JOIN Dim_Tempo t ON p.DataPagto = t.Data_Completa;

-- ---------------------------------------------------------------------
-- 3.7 Carga Fato_Avaliacao
-- Explosão de linhas para filmes com múltiplos gêneros e produtoras 
-- (Conforme a regra do seu guia: ligá-los diretamente na fato facilita filtros)
-- ---------------------------------------------------------------------
INSERT INTO Fato_Avaliacao (SK_Cliente, SK_Filme, SK_Produtora, SK_Genero, SK_Tempo, Hora_Avaliacao, Nota)
SELECT 
    c.SK_Cliente,
    f.SK_Filme,
    p.SK_Produtora,
    g.SK_Genero,
    t.SK_Tempo,
    '00:00:00' AS Hora_Avaliacao, -- Fonte não possui hora exata
    a.Nota
FROM ALV.Avaliacao a
JOIN Dim_Cliente c ON a.UsuarioID = c.ID_Cliente_Origem
JOIN Dim_Filme f ON a.FilmeID = f.ID_Filme_Origem
JOIN Dim_Tempo t ON a.AvaliacaoData = t.Data_Completa
-- Relacionamento com as tabelas associativas do MIR para pegar Gênero e Produtora
LEFT JOIN ALV.Filme_GeneroFilme f_gen ON a.FilmeID = f_gen.FilmeID
LEFT JOIN Dim_Genero g ON f_gen.GeneroID = g.ID_Genero_Origem
LEFT JOIN ALV.FilmPagtoRoy f_prod ON a.FilmeID = f_prod.FilmeID
LEFT JOIN Dim_Produtora p ON f_prod.ProdutoraID = p.ID_Produtora_Origem;