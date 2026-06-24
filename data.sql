-- ======================================================================
-- CEFET-RJ — Campus Maria da Graça
-- Matéria: Banco de Dados 1 | Professor: Rafael Costa
-- Trabalho Individual — Sistema de Biblioteca Escolar
-- Aluno(a): __________________________________________
--
-- Script: data.sql — Carga inicial de dados
-- Pré-requisito: executar antes o schema.sql (tabelas, índices e triggers).
--
-- NOTA SOBRE O ESTADO DOS EXEMPLARES
-- ----------------------------------------------------------------------
-- O status físico de cada exemplar é, sempre que possível, DERIVADO pelos
-- triggers a partir dos empréstimos e reservas, e não declarado de forma
-- redundante. Por isso:
--   * Exemplares que serão emprestados (empréstimos Ativos/Atrasados) são
--     inseridos como 'Disponível' e o trigger trg_apos_emprestimo os marca
--     como 'Emprestado'. (Ex.: TOMB-007 termina 'Emprestado' por causa do
--     empréstimo em atraso do aluno 2024014.)
--   * O segundo exemplar de cada livro que possui reserva ATIVA é inserido
--     como 'Reservado' (separado para o aluno da fila), de modo a respeitar
--     a regra de que não se reserva livro com exemplar disponível.
--   * Dois exemplares cujo livro só tinha empréstimo já devolvido recebem um
--     UPDATE pós-carga para 'Reservado' (regra do minimundo, seção 7).
-- Resultado: a carga executa do zero sem violar nenhum trigger e o estado
-- final é íntegro e coerente com as regras de negócio.
-- ======================================================================

USE biblioteca_escolar;

-- ======================================================================
-- 1. CURSOS (5 registros)
-- ======================================================================
INSERT INTO curso (nome, turno, duracao_anos) VALUES
('Informática para Internet',  'Manhã',  3),
('Eletrônica',                 'Tarde',  3),
('Administração',              'Noite',  3),
('Mecânica',                   'Manhã',  4),
('Design Gráfico',             'Tarde',  3);

-- ======================================================================
-- 2. CATEGORIAS (10 registros)
-- ======================================================================
INSERT INTO categoria (nome_categoria) VALUES
('Literatura Brasileira'),
('Literatura Estrangeira'),
('Ficção Científica'),
('História'),
('Matemática'),
('Física'),
('Informática'),
('Filosofia'),
('Química'),
('Artes');

-- ======================================================================
-- 3. AUTORES (16 registros)
-- 1–10: autores literários originais.
-- 11–16: autores reais dos livros técnicos do acervo (substituem as
--        associações fictícias que antes apontavam para Asimov/Sagan).
-- ======================================================================
INSERT INTO autor (nome, nacionalidade) VALUES
('Machado de Assis',     'Brasileira'),   -- 1
('Graciliano Ramos',     'Brasileira'),   -- 2
('Jorge Amado',          'Brasileira'),   -- 3
('Douglas Adams',        'Britânica'),    -- 4
('Frank Herbert',        'Americana'),    -- 5
('Isaac Asimov',         'Americana'),    -- 6
('José Saramago',        'Portuguesa'),   -- 7
('Agatha Christie',      'Britânica'),    -- 8
('Clarice Lispector',    'Brasileira'),   -- 9
('Carl Sagan',           'Americana'),    -- 10
('James Stewart',        'Americana'),    -- 11  Cálculo Vol. 1
('Gilbert Strang',       'Americana'),    -- 12  Álgebra Linear
('David Halliday',       'Americana'),    -- 13  Fundamentos de Física Vol. 1
('Abraham Silberschatz', 'Americana'),    -- 14  Banco de Dados
('Andrew Tanenbaum',     'Holandesa'),    -- 15  Sistemas Operacionais Modernos
('John McMurry',         'Americana');    -- 16  Química Orgânica

-- ======================================================================
-- 4. ALUNOS (15 registros)
-- ======================================================================
INSERT INTO aluno (matricula, nome, email, telefone, data_nascimento, status, id_curso) VALUES
(2024001, 'Ana Carolina Ferreira',     'ana.ferreira@cefet.edu.br',     '21991110001', '2007-03-15', 'Ativo',    1),
(2024002, 'Bruno Henrique Souza',      'bruno.souza@cefet.edu.br',      '21991110002', '2006-07-22', 'Ativo',    1),
(2024003, 'Carla Mendes Lima',         'carla.lima@cefet.edu.br',       '21991110003', '2007-11-05', 'Ativo',    2),
(2024004, 'Diego Alves Rocha',         'diego.rocha@cefet.edu.br',      '21991110004', '2006-02-18', 'Ativo',    2),
(2024005, 'Eduarda Pinto Costa',       'eduarda.costa@cefet.edu.br',    '21991110005', '2007-09-30', 'Ativo',    3),
(2024006, 'Felipe Nascimento Silva',   'felipe.silva@cefet.edu.br',     '21991110006', '2006-12-01', 'Ativo',    3),
(2024007, 'Gabriela Torres Martins',   'gabriela.martins@cefet.edu.br', '21991110007', '2007-04-14', 'Ativo',    4),
(2024008, 'Henrique Castro Pereira',   'henrique.pereira@cefet.edu.br', '21991110008', '2006-08-25', 'Ativo',    4),
(2024009, 'Isabela Moura Ribeiro',     'isabela.ribeiro@cefet.edu.br',  '21991110009', '2007-06-07', 'Ativo',    5),
(2024010, 'João Victor Oliveira',      'joao.oliveira@cefet.edu.br',    '21991110010', '2006-01-19', 'Ativo',    5),
(2024011, 'Karen Santos Araujo',       'karen.araujo@cefet.edu.br',     '21991110011', '2007-10-23', 'Suspenso', 1),
(2024012, 'Lucas Barbosa Dias',        'lucas.dias@cefet.edu.br',       '21991110012', '2006-05-11', 'Ativo',    2),
(2024013, 'Mariana Gomes Freitas',     'mariana.freitas@cefet.edu.br',  '21991110013', '2007-08-03', 'Ativo',    3),
(2024014, 'Nicolas Almeida Cardoso',   'nicolas.cardoso@cefet.edu.br',  '21991110014', '2006-03-27', 'Ativo',    4),
(2024015, 'Paloma Rodrigues Nunes',    'paloma.nunes@cefet.edu.br',     '21991110015', '2007-12-09', 'Inativo',  5);

-- ======================================================================
-- 5. LIVROS (20 registros)
-- ======================================================================
INSERT INTO livro (isbn, titulo, ano_publicacao, id_categoria) VALUES
('978-8535902778', 'Dom Casmurro',                                  1899, 1),
('978-8535910483', 'Memórias Póstumas de Brás Cubas',               1881, 1),
('978-8535914849', 'Vidas Secas',                                   1938, 1),
('978-8535923421', 'Capitães da Areia',                             1937, 1),
('978-8535926491', 'A Hora da Estrela',                             1977, 1),
('978-8532530455', 'O Guia do Mochileiro das Galáxias',             1979, 3),
('978-8533613379', 'Duna',                                          1965, 3),
('978-8576571803', 'Fundação',                                      1951, 3),
('978-8579027895', 'Ensaio sobre a Cegueira',                       1995, 2),
('978-8535927665', 'Dez Negrinhos',                                 1939, 2),
('978-8576080602', 'Cosmos',                                        1980, 6),
('978-8535912694', 'Cálculo Vol. 1',                                2010, 5),
('978-8576051992', 'Álgebra Linear',                                2012, 5),
('978-8550800479', 'Fundamentos de Física Vol. 1',                  2008, 6),
('978-8535903492', 'Química Orgânica',                              2015, 9),
('978-8575227152', 'Banco de Dados — Projeto e Implementação',      2019, 7),
('978-8576082675', 'Sistemas Operacionais Modernos',                2016, 7),
('978-8571398047', 'Introdução à Filosofia',                        2005, 8),
('978-8535924435', 'História do Brasil',                            2018, 4),
('978-8550806532', 'Arte e Percepção Visual',                       2011, 10);

-- ======================================================================
-- 6. LIVRO_AUTOR (relacionamentos N:M)
-- Livros técnicos agora associados aos seus autores reais (ids 11–16).
-- ======================================================================
INSERT INTO livro_autor (isbn, id_autor) VALUES
('978-8535902778', 1),   -- Dom Casmurro -> Machado de Assis
('978-8535910483', 1),   -- Memórias Póstumas -> Machado de Assis
('978-8535914849', 2),   -- Vidas Secas -> Graciliano Ramos
('978-8535923421', 3),   -- Capitães da Areia -> Jorge Amado
('978-8535926491', 9),   -- A Hora da Estrela -> Clarice Lispector
('978-8532530455', 4),   -- Guia do Mochileiro -> Douglas Adams
('978-8533613379', 5),   -- Duna -> Frank Herbert
('978-8576571803', 6),   -- Fundação -> Isaac Asimov
('978-8579027895', 7),   -- Ensaio sobre a Cegueira -> José Saramago
('978-8535927665', 8),   -- Dez Negrinhos -> Agatha Christie
('978-8576080602', 10),  -- Cosmos -> Carl Sagan
('978-8535912694', 11),  -- Cálculo Vol. 1 -> James Stewart
('978-8576051992', 12),  -- Álgebra Linear -> Gilbert Strang
('978-8550800479', 13),  -- Fundamentos de Física -> David Halliday
('978-8535903492', 16),  -- Química Orgânica -> John McMurry
('978-8575227152', 14),  -- Banco de Dados -> Abraham Silberschatz
('978-8576082675', 15),  -- Sistemas Operacionais Modernos -> Andrew Tanenbaum
('978-8571398047', 7),   -- Introdução à Filosofia -> José Saramago
('978-8535924435', 3),   -- História do Brasil -> Jorge Amado
('978-8550806532', 10);  -- Arte e Percepção Visual -> Carl Sagan

-- ======================================================================
-- 7. EXEMPLARES (40 registros — 2 por livro)
-- Status de carga conforme a NOTA do cabeçalho:
--   'Disponível'  -> exemplar livre, ou que será emprestado via trigger
--   'Reservado'   -> exemplar separado para a fila de reserva ativa
--   'Indisponível'-> exemplar fora de circulação (decisão administrativa)
-- ======================================================================
INSERT INTO exemplar (tombamento, isbn, data_aquisicao, conservacao, status) VALUES
-- Dom Casmurro
('TOMB-001', '978-8535902778', '2020-01-10', 'Bom', 'Disponível'),
('TOMB-002', '978-8535902778', '2020-01-10', 'Ótimo', 'Reservado'),
-- Memórias Póstumas de Brás Cubas
('TOMB-003', '978-8535910483', '2020-01-10', 'Bom', 'Disponível'),
('TOMB-004', '978-8535910483', '2021-03-15', 'Ótimo', 'Disponível'),
-- Vidas Secas
('TOMB-005', '978-8535914849', '2020-02-20', 'Regular', 'Disponível'),
('TOMB-006', '978-8535914849', '2021-04-10', 'Bom', 'Reservado'),
-- Capitães da Areia
('TOMB-007', '978-8535923421', '2020-02-20', 'Ótimo', 'Disponível'),
('TOMB-008', '978-8535923421', '2021-05-01', 'Bom', 'Disponível'),
-- A Hora da Estrela
('TOMB-009', '978-8535926491', '2020-03-01', 'Bom', 'Disponível'),
('TOMB-010', '978-8535926491', '2022-01-20', 'Ótimo', 'Disponível'),
-- O Guia do Mochileiro das Galáxias
('TOMB-011', '978-8532530455', '2020-03-01', 'Bom', 'Reservado'),
('TOMB-012', '978-8532530455', '2021-06-15', 'Regular', 'Disponível'),
-- Duna
('TOMB-013', '978-8533613379', '2020-04-05', 'Ótimo', 'Reservado'),
('TOMB-014', '978-8533613379', '2021-07-20', 'Bom', 'Disponível'),
-- Fundação
('TOMB-015', '978-8576571803', '2020-04-05', 'Bom', 'Disponível'),
('TOMB-016', '978-8576571803', '2022-02-10', 'Ótimo', 'Disponível'),
-- Ensaio sobre a Cegueira
('TOMB-017', '978-8579027895', '2020-05-10', 'Bom', 'Disponível'),
('TOMB-018', '978-8579027895', '2022-03-05', 'Ótimo', 'Reservado'),
-- Dez Negrinhos
('TOMB-019', '978-8535927665', '2020-05-10', 'Regular', 'Disponível'),
('TOMB-020', '978-8535927665', '2021-08-25', 'Bom', 'Disponível'),
-- Cosmos
('TOMB-021', '978-8576080602', '2020-06-15', 'Bom', 'Disponível'),
('TOMB-022', '978-8576080602', '2022-04-12', 'Ótimo', 'Reservado'),
-- Cálculo Vol. 1
('TOMB-023', '978-8535912694', '2020-06-15', 'Regular', 'Disponível'),
('TOMB-024', '978-8535912694', '2021-09-30', 'Bom', 'Disponível'),
-- Álgebra Linear
('TOMB-025', '978-8576051992', '2020-07-20', 'Bom', 'Disponível'),
('TOMB-026', '978-8576051992', '2022-05-18', 'Ótimo', 'Disponível'),
-- Fundamentos de Física Vol. 1
('TOMB-027', '978-8550800479', '2020-07-20', 'Bom', 'Disponível'),
('TOMB-028', '978-8550800479', '2021-10-14', 'Regular', 'Indisponível'),
-- Química Orgânica
('TOMB-029', '978-8535903492', '2020-08-25', 'Ótimo', 'Disponível'),
('TOMB-030', '978-8535903492', '2022-06-22', 'Bom', 'Disponível'),
-- Banco de Dados — Projeto e Implementação
('TOMB-031', '978-8575227152', '2020-08-25', 'Ótimo', 'Disponível'),
('TOMB-032', '978-8575227152', '2022-07-30', 'Bom', 'Reservado'),
-- Sistemas Operacionais Modernos
('TOMB-033', '978-8576082675', '2020-09-30', 'Bom', 'Disponível'),
('TOMB-034', '978-8576082675', '2021-11-19', 'Regular', 'Disponível'),
-- Introdução à Filosofia
('TOMB-035', '978-8571398047', '2020-09-30', 'Bom', 'Disponível'),
('TOMB-036', '978-8571398047', '2022-08-15', 'Ótimo', 'Disponível'),
-- História do Brasil
('TOMB-037', '978-8535924435', '2020-10-10', 'Bom', 'Disponível'),
('TOMB-038', '978-8535924435', '2021-12-05', 'Regular', 'Reservado'),
-- Arte e Percepção Visual
('TOMB-039', '978-8550806532', '2020-10-10', 'Ótimo', 'Disponível'),
('TOMB-040', '978-8550806532', '2022-09-01', 'Bom', 'Disponível');

-- ======================================================================
-- 8. EMPRÉSTIMOS (15 registros)
-- Os triggers cuidam do efeito colateral nos exemplares:
--   - empréstimos Ativos/Atrasados  -> exemplar passa a 'Emprestado'
--   - empréstimos Devolvidos        -> exemplar permanece 'Disponível'
-- ======================================================================
INSERT INTO emprestimo (matricula_aluno, id_exemplar, data_emprestimo, data_previsao, data_devolucao, status) VALUES
(2024001, 1,  '2025-06-01', '2025-06-11', NULL,         'Ativo'),      -- TOMB-001 Ana -> Dom Casmurro
(2024002, 5,  '2025-06-03', '2025-06-13', NULL,         'Ativo'),      -- TOMB-005 Bruno -> Vidas Secas
(2024003, 8,  '2025-05-20', '2025-05-30', '2025-05-29', 'Devolvido'),  -- TOMB-008 Carla -> Capitães (devolvido)
(2024004, 10, '2025-06-05', '2025-06-15', NULL,         'Ativo'),      -- TOMB-010 Diego -> A Hora da Estrela
(2024005, 12, '2025-05-25', '2025-06-04', NULL,         'Atrasado'),   -- TOMB-012 Eduarda -> Guia Mochileiro (atrasado)
(2024006, 14, '2025-06-08', '2025-06-18', NULL,         'Ativo'),      -- TOMB-014 Felipe -> Duna
(2024007, 17, '2025-06-10', '2025-06-20', NULL,         'Ativo'),      -- TOMB-017 Gabriela -> Ensaio Cegueira
(2024008, 21, '2025-05-15', '2025-05-25', '2025-05-24', 'Devolvido'),  -- TOMB-021 Henrique -> Cosmos (devolvido)
(2024009, 23, '2025-06-12', '2025-06-22', NULL,         'Ativo'),      -- TOMB-023 Isabela -> Cálculo
(2024010, 31, '2025-06-14', '2025-06-24', NULL,         'Ativo'),      -- TOMB-031 João -> Banco de Dados
(2024012, 37, '2025-05-10', '2025-05-20', '2025-05-19', 'Devolvido'),  -- TOMB-037 Lucas -> Hist. Brasil (devolvido)
(2024013, 3,  '2025-06-02', '2025-06-12', '2025-06-11', 'Devolvido'),  -- TOMB-003 Mariana -> Memórias (devolvido)
(2024014, 7,  '2025-05-28', '2025-06-07', NULL,         'Atrasado'),   -- TOMB-007 Nicolas -> Capitães (atrasado)
(2024001, 15, '2025-05-05', '2025-05-15', '2025-05-14', 'Devolvido'),  -- TOMB-015 Ana -> Fundação (devolvido)
(2024002, 9,  '2025-06-16', '2025-06-26', NULL,         'Ativo');      -- TOMB-009 Bruno -> Hora da Estrela

-- ======================================================================
-- 9. AJUSTE DE ESTADO PRÉ-RESERVA (regra do minimundo, seção 7)
-- Cosmos e História do Brasil possuem reserva ATIVA, mas seu único
-- empréstimo recente já havia sido devolvido. O exemplar devolvido fica,
-- portanto, separado para a fila de reserva ('Reservado') e não livre.
-- Este ajuste vem ANTES dos INSERTs de reserva para que, no momento da
-- reserva, o livro já não tenha exemplar 'Disponível'.
-- (Atualizar somente o status não dispara trg_antes_conservacao.)
-- ======================================================================
UPDATE exemplar SET status = 'Reservado' WHERE tombamento = 'TOMB-021';  -- Cosmos
UPDATE exemplar SET status = 'Reservado' WHERE tombamento = 'TOMB-037';  -- História do Brasil

-- ======================================================================
-- 10. RESERVAS (10 registros)
-- Inseridas após os empréstimos: a esta altura, todos os livros abaixo
-- com status 'Ativa' já estão sem exemplar 'Disponível', de modo que o
-- trigger trg_antes_reserva aceita o registro.
-- ======================================================================
INSERT INTO reserva (matricula_aluno, isbn, data_reserva, status) VALUES
(2024003, '978-8533613379', '2025-06-10', 'Ativa'),      -- Carla reservou Duna
(2024004, '978-8532530455', '2025-06-12', 'Ativa'),      -- Diego reservou Guia do Mochileiro
(2024005, '978-8535902778', '2025-06-13', 'Ativa'),      -- Eduarda reservou Dom Casmurro
(2024006, '978-8579027895', '2025-06-11', 'Ativa'),      -- Felipe reservou Ensaio sobre a Cegueira
(2024007, '978-8576080602', '2025-06-14', 'Ativa'),      -- Gabriela reservou Cosmos
(2024008, '978-8535914849', '2025-06-15', 'Ativa'),      -- Henrique reservou Vidas Secas
(2024009, '978-8575227152', '2025-06-16', 'Ativa'),      -- Isabela reservou Banco de Dados
(2024010, '978-8535926491', '2025-06-10', 'Cancelada'),  -- João cancelou reserva A Hora da Estrela
(2024012, '978-8535924435', '2025-05-08', 'Atendida'),   -- Lucas reservou Hist. do Brasil (atendida pelo empréstimo TOMB-037, id 11)
(2024013, '978-8535924435', '2025-06-17', 'Ativa');      -- Mariana reservou Hist. do Brasil

-- ======================================================================
-- FIM DO DATA.SQL
-- ======================================================================
