-- ======================================================================
-- CEFET-RJ — Campus Maria da Graça
-- Matéria: Banco de Dados 1 | Professor: Rafael Costa
-- Trabalho Individual — Sistema de Biblioteca Escolar
-- Aluno(a): __________________________________________
--
-- Script: schema.sql — Criação do Banco de Dados, Tabelas, Índices e Triggers
-- SGBD-alvo: MySQL 8.x  |  Charset: utf8mb4 / utf8mb4_unicode_ci
--
-- Ordem de execução: DROP DATABASE -> CREATE DATABASE -> USE
--                    -> CREATE TABLEs -> CREATE INDEX -> CREATE TRIGGERs
-- ======================================================================

DROP DATABASE IF EXISTS biblioteca_escolar;
CREATE DATABASE biblioteca_escolar
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE biblioteca_escolar;

-- ======================================================================
-- TABELA: curso
-- Representa os cursos técnicos integrados ao ensino médio.
-- ======================================================================
CREATE TABLE curso (
    id_curso     INT          AUTO_INCREMENT PRIMARY KEY,
    nome         VARCHAR(100) NOT NULL UNIQUE,
    turno        ENUM('Manhã','Tarde','Noite') NOT NULL,
    duracao_anos TINYINT      NOT NULL CHECK (duracao_anos BETWEEN 1 AND 5)
);

-- ======================================================================
-- TABELA: aluno
-- Representa os alunos matriculados na instituição.
-- ======================================================================
CREATE TABLE aluno (
    matricula        INT          PRIMARY KEY,
    nome             VARCHAR(100) NOT NULL,
    email            VARCHAR(100) NOT NULL UNIQUE,
    telefone         VARCHAR(20),
    data_nascimento  DATE         NOT NULL,
    status           ENUM('Ativo','Inativo','Suspenso') NOT NULL DEFAULT 'Ativo',
    id_curso         INT          NOT NULL,
    CONSTRAINT fk_aluno_curso
        FOREIGN KEY (id_curso) REFERENCES curso(id_curso) ON DELETE RESTRICT
);

-- ======================================================================
-- TABELA: categoria
-- Classificação temática dos livros do acervo.
-- ======================================================================
CREATE TABLE categoria (
    id_categoria   INT         AUTO_INCREMENT PRIMARY KEY,
    nome_categoria VARCHAR(80) NOT NULL UNIQUE
);

-- ======================================================================
-- TABELA: autor
-- Autores dos livros cadastrados no acervo.
-- UNIQUE (nome, nacionalidade): impede o cadastro de autores duplicados.
-- ======================================================================
CREATE TABLE autor (
    id_autor      INT          AUTO_INCREMENT PRIMARY KEY,
    nome          VARCHAR(100) NOT NULL,
    nacionalidade VARCHAR(60)  NOT NULL,
    CONSTRAINT uq_autor_nome_nac UNIQUE (nome, nacionalidade)
);

-- ======================================================================
-- TABELA: livro
-- Títulos que compõem o acervo, identificados por ISBN único.
-- ======================================================================
CREATE TABLE livro (
    isbn             VARCHAR(20)  PRIMARY KEY,
    titulo           VARCHAR(200) NOT NULL,
    ano_publicacao   YEAR         NOT NULL,
    id_categoria     INT          NOT NULL,
    CONSTRAINT fk_livro_categoria
        FOREIGN KEY (id_categoria) REFERENCES categoria(id_categoria) ON DELETE RESTRICT
);

-- ======================================================================
-- TABELA: livro_autor
-- Tabela associativa para o relacionamento N:M entre Livro e Autor.
-- ======================================================================
CREATE TABLE livro_autor (
    isbn      VARCHAR(20) NOT NULL,
    id_autor  INT         NOT NULL,
    PRIMARY KEY (isbn, id_autor),
    CONSTRAINT fk_la_livro FOREIGN KEY (isbn)     REFERENCES livro(isbn)       ON DELETE CASCADE,
    CONSTRAINT fk_la_autor FOREIGN KEY (id_autor) REFERENCES autor(id_autor)   ON DELETE RESTRICT
);

-- ======================================================================
-- TABELA: exemplar
-- Objetos físicos individuais de cada livro.
-- O empréstimo ocorre sempre sobre um exemplar específico.
-- ======================================================================
CREATE TABLE exemplar (
    id_exemplar    INT          AUTO_INCREMENT PRIMARY KEY,
    tombamento     VARCHAR(20)  NOT NULL UNIQUE,
    isbn           VARCHAR(20)  NOT NULL,
    data_aquisicao DATE         NOT NULL,
    conservacao    ENUM('Ótimo','Bom','Regular','Danificado') NOT NULL DEFAULT 'Ótimo',
    status         ENUM('Disponível','Emprestado','Reservado','Indisponível') NOT NULL DEFAULT 'Disponível',
    CONSTRAINT fk_exemplar_livro
        FOREIGN KEY (isbn) REFERENCES livro(isbn) ON DELETE RESTRICT
);

-- ======================================================================
-- TABELA: emprestimo
-- Registro de retirada de um exemplar específico por um aluno.
-- ======================================================================
CREATE TABLE emprestimo (
    id_emprestimo    INT  AUTO_INCREMENT PRIMARY KEY,
    matricula_aluno  INT  NOT NULL,
    id_exemplar      INT  NOT NULL,
    data_emprestimo  DATE NOT NULL,
    data_previsao    DATE NOT NULL,
    data_devolucao   DATE NULL,
    status           ENUM('Ativo','Devolvido','Atrasado') NOT NULL DEFAULT 'Ativo',
    CONSTRAINT fk_emp_aluno
        FOREIGN KEY (matricula_aluno) REFERENCES aluno(matricula) ON DELETE RESTRICT,
    CONSTRAINT fk_emp_exemplar
        FOREIGN KEY (id_exemplar) REFERENCES exemplar(id_exemplar) ON DELETE RESTRICT,
    CONSTRAINT chk_devolucao_valida
        CHECK (data_devolucao IS NULL OR data_devolucao >= data_emprestimo),
    CONSTRAINT chk_previsao_valida
        CHECK (data_previsao > data_emprestimo)
);

-- ======================================================================
-- TABELA: reserva
-- Fila de espera de alunos para livros sem exemplares disponíveis.
-- ======================================================================
CREATE TABLE reserva (
    id_reserva      INT  AUTO_INCREMENT PRIMARY KEY,
    matricula_aluno INT  NOT NULL,
    isbn            VARCHAR(20) NOT NULL,
    data_reserva    DATE NOT NULL,
    status          ENUM('Ativa','Cancelada','Atendida') NOT NULL DEFAULT 'Ativa',
    CONSTRAINT fk_res_aluno
        FOREIGN KEY (matricula_aluno) REFERENCES aluno(matricula) ON DELETE RESTRICT,
    CONSTRAINT fk_res_livro
        FOREIGN KEY (isbn) REFERENCES livro(isbn) ON DELETE RESTRICT
);

-- ======================================================================
-- ÍNDICES SECUNDÁRIOS
-- Aceleram filtros e JOINs frequentes nas consultas (queries.sql).
-- As chaves primárias e os UNIQUE já possuem índice automático; abaixo
-- criamos índices para as colunas mais usadas em WHERE/JOIN/GROUP BY.
-- ======================================================================
CREATE INDEX idx_emp_status        ON emprestimo(status);
CREATE INDEX idx_emp_matricula     ON emprestimo(matricula_aluno);
CREATE INDEX idx_ex_status         ON exemplar(status);
CREATE INDEX idx_ex_isbn           ON exemplar(isbn);
CREATE INDEX idx_res_isbn_status   ON reserva(isbn, status);
CREATE INDEX idx_res_matricula     ON reserva(matricula_aluno);

-- ======================================================================
-- TRIGGERS
-- Implementam, no nível do banco, as regras de negócio do minimundo.
-- ======================================================================

DELIMITER $$

-- ----------------------------------------------------------------------
-- TRIGGER 1: trg_antes_reserva  (BEFORE INSERT ON reserva)
-- Regra (minimundo, seção 8): não se pode reservar um livro que ainda
-- possui exemplar disponível para empréstimo imediato.
-- ----------------------------------------------------------------------
CREATE TRIGGER trg_antes_reserva
BEFORE INSERT ON reserva
FOR EACH ROW
BEGIN
    DECLARE v_disponiveis INT;

    SELECT COUNT(*) INTO v_disponiveis
    FROM exemplar
    WHERE isbn = NEW.isbn AND status = 'Disponível';

    IF NEW.status = 'Ativa' AND v_disponiveis > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Não é possível reservar: há exemplar disponível para empréstimo imediato.';
    END IF;
END$$

-- ----------------------------------------------------------------------
-- TRIGGER 2: trg_antes_emprestimo  (BEFORE INSERT ON emprestimo)
-- Valida, antes de gravar o empréstimo:
--   (a) o aluno deve estar com status 'Ativo';
--   (b) o aluno não pode ter empréstimos em atraso (minimundo, seções 2 e 9);
--   (c) o aluno não pode exceder 3 empréstimos ativos simultâneos;
--   (d) o exemplar deve estar com status 'Disponível'.
-- ----------------------------------------------------------------------
CREATE TRIGGER trg_antes_emprestimo
BEFORE INSERT ON emprestimo
FOR EACH ROW
BEGIN
    DECLARE v_status_exemplar ENUM('Disponível','Emprestado','Reservado','Indisponível');
    DECLARE v_status_aluno    ENUM('Ativo','Inativo','Suspenso');
    DECLARE v_qtd_ativos      INT;
    DECLARE v_qtd_atrasados   INT;

    -- (a) Verifica status do aluno
    SELECT status INTO v_status_aluno FROM aluno WHERE matricula = NEW.matricula_aluno;
    IF v_status_aluno != 'Ativo' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Aluno não está com status Ativo. Empréstimo bloqueado.';
    END IF;

    -- (b) Verifica empréstimos em atraso do aluno
    SELECT COUNT(*) INTO v_qtd_atrasados
    FROM emprestimo
    WHERE matricula_aluno = NEW.matricula_aluno AND status = 'Atrasado';
    IF v_qtd_atrasados > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Aluno possui empréstimos em atraso. Novos empréstimos bloqueados.';
    END IF;

    -- (c) Verifica limite de empréstimos ativos
    SELECT COUNT(*) INTO v_qtd_ativos
    FROM emprestimo
    WHERE matricula_aluno = NEW.matricula_aluno AND status = 'Ativo';
    IF v_qtd_ativos >= 3 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Limite de 3 empréstimos ativos atingido.';
    END IF;

    -- (d) Verifica disponibilidade do exemplar
    SELECT status INTO v_status_exemplar FROM exemplar WHERE id_exemplar = NEW.id_exemplar;
    IF v_status_exemplar != 'Disponível' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Exemplar não está disponível para empréstimo.';
    END IF;
END$$

-- ----------------------------------------------------------------------
-- TRIGGER 3: trg_apos_emprestimo  (AFTER INSERT ON emprestimo)
-- Quando o empréstimo registrado está em curso (Ativo ou Atrasado), o
-- exemplar passa a 'Emprestado'. Para empréstimos já 'Devolvido'
-- (carga histórica), o exemplar permanece como está (volta ao acervo).
-- ----------------------------------------------------------------------
CREATE TRIGGER trg_apos_emprestimo
AFTER INSERT ON emprestimo
FOR EACH ROW
BEGIN
    IF NEW.status IN ('Ativo','Atrasado') THEN
        UPDATE exemplar SET status = 'Emprestado' WHERE id_exemplar = NEW.id_exemplar;
    END IF;
END$$

-- ----------------------------------------------------------------------
-- TRIGGER 4: trg_apos_emprestimo_reserva  (AFTER INSERT ON emprestimo)
-- Fecha o ciclo da reserva: ao registrar um empréstimo do livro para o
-- aluno que estava na fila, a reserva ativa correspondente é marcada
-- como 'Atendida' (minimundo, seção 8).
-- ----------------------------------------------------------------------
CREATE TRIGGER trg_apos_emprestimo_reserva
AFTER INSERT ON emprestimo
FOR EACH ROW
BEGIN
    DECLARE v_isbn VARCHAR(20);

    SELECT isbn INTO v_isbn FROM exemplar WHERE id_exemplar = NEW.id_exemplar;

    UPDATE reserva
    SET status = 'Atendida'
    WHERE isbn = v_isbn
      AND matricula_aluno = NEW.matricula_aluno
      AND status = 'Ativa'
    LIMIT 1;
END$$

-- ----------------------------------------------------------------------
-- TRIGGER 5: trg_apos_devolucao  (AFTER UPDATE ON emprestimo)
-- Ao mudar o empréstimo para 'Devolvido', o exemplar retorna para
-- 'Disponível' — ou para 'Reservado', se existir fila de reserva ativa
-- para o livro (minimundo, seção 7).
-- ----------------------------------------------------------------------
CREATE TRIGGER trg_apos_devolucao
AFTER UPDATE ON emprestimo
FOR EACH ROW
BEGIN
    DECLARE v_isbn     VARCHAR(20);
    DECLARE v_reservas INT;

    IF NEW.status = 'Devolvido' AND OLD.status != 'Devolvido' THEN
        SELECT isbn INTO v_isbn FROM exemplar WHERE id_exemplar = NEW.id_exemplar;

        SELECT COUNT(*) INTO v_reservas
        FROM reserva WHERE isbn = v_isbn AND status = 'Ativa';

        IF v_reservas > 0 THEN
            UPDATE exemplar SET status = 'Reservado'  WHERE id_exemplar = NEW.id_exemplar;
        ELSE
            UPDATE exemplar SET status = 'Disponível' WHERE id_exemplar = NEW.id_exemplar;
        END IF;
    END IF;
END$$

-- ----------------------------------------------------------------------
-- TRIGGER 6: trg_antes_conservacao  (BEFORE UPDATE ON exemplar)
-- Regra (minimundo, seção 9): o estado de conservação não pode ser
-- "melhorado" manualmente sem registro de restauração. A ordem de
-- deterioração é: Ótimo > Bom > Regular > Danificado.
-- ----------------------------------------------------------------------
CREATE TRIGGER trg_antes_conservacao
BEFORE UPDATE ON exemplar
FOR EACH ROW
BEGIN
    IF (OLD.conservacao = 'Danificado' AND NEW.conservacao IN ('Ótimo','Bom','Regular')) OR
       (OLD.conservacao = 'Regular'    AND NEW.conservacao IN ('Ótimo','Bom'))           OR
       (OLD.conservacao = 'Bom'        AND NEW.conservacao = 'Ótimo')
    THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Melhoria de conservação não permitida sem registro de restauração.';
    END IF;
END$$

DELIMITER ;

-- ======================================================================
-- FIM DO SCHEMA
-- ======================================================================
