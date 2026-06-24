-- ======================================================================
-- CEFET-RJ — Campus Maria da Graça
-- Matéria: Banco de Dados 1 | Professor: Rafael Costa
-- Aluno(a): __________________________________________________
-- Script: queries.sql — 12 consultas ao modelo (com restrições e JOINs)
-- SGBD-alvo: MySQL 8.x
--
-- Pré-requisito: execute schema.sql e data.sql antes deste arquivo.
-- Cada consulta abaixo é independente e pode ser executada isoladamente.
-- ======================================================================

USE biblioteca_escolar;

-- ======================================================================
-- CONSULTA 1 — Relatório de empréstimos ativos
-- Tipo: SELECT com JOIN triplo (emprestimo + aluno + exemplar + livro)
-- Finalidade: listar quem está com quais livros no momento, com prazos.
-- ======================================================================
SELECT  e.id_emprestimo,
        a.matricula,
        a.nome            AS aluno,
        l.titulo          AS livro,
        ex.tombamento     AS exemplar,
        e.data_emprestimo,
        e.data_previsao
FROM        emprestimo e
JOIN        aluno      a  ON a.matricula    = e.matricula_aluno
JOIN        exemplar   ex ON ex.id_exemplar = e.id_exemplar
JOIN        livro      l  ON l.isbn         = ex.isbn
WHERE   e.status = 'Ativo'
ORDER BY e.data_previsao;

-- ======================================================================
-- CONSULTA 2 — Empréstimos em atraso com dias de atraso
-- Tipo: SELECT com JOIN + função de data (DATEDIFF)
-- Finalidade: apoiar a cobrança, mostrando há quantos dias cada
--             empréstimo 'Atrasado' deveria ter sido devolvido.
-- ======================================================================
SELECT  a.matricula,
        a.nome            AS aluno,
        l.titulo          AS livro,
        e.data_previsao,
        DATEDIFF(CURDATE(), e.data_previsao) AS dias_de_atraso
FROM        emprestimo e
JOIN        aluno      a  ON a.matricula    = e.matricula_aluno
JOIN        exemplar   ex ON ex.id_exemplar = e.id_exemplar
JOIN        livro      l  ON l.isbn         = ex.isbn
WHERE   e.status = 'Atrasado'
ORDER BY dias_de_atraso DESC;

-- ======================================================================
-- CONSULTA 3 — Empréstimos por categoria
-- Tipo: SELECT com JOIN + GROUP BY + COUNT
-- Finalidade: medir a demanda por área temática do acervo.
-- ======================================================================
SELECT  c.nome_categoria,
        COUNT(e.id_emprestimo) AS total_emprestimos
FROM        categoria  c
JOIN        livro      l  ON l.id_categoria = c.id_categoria
JOIN        exemplar   ex ON ex.isbn        = l.isbn
JOIN        emprestimo e  ON e.id_exemplar  = ex.id_exemplar
GROUP BY c.id_categoria, c.nome_categoria
ORDER BY total_emprestimos DESC, c.nome_categoria;

-- ======================================================================
-- CONSULTA 4 — Livros que nunca foram emprestados
-- Tipo: anti-join (LEFT JOIN + IS NULL) contra subconsulta
-- Finalidade: identificar títulos sem nenhuma circulação (qualquer exemplar).
-- ======================================================================
SELECT  l.isbn,
        l.titulo
FROM        livro l
LEFT JOIN ( SELECT DISTINCT ex.isbn
            FROM   exemplar   ex
            JOIN   emprestimo e ON e.id_exemplar = ex.id_exemplar
          ) AS emprestados ON emprestados.isbn = l.isbn
WHERE   emprestados.isbn IS NULL
ORDER BY l.titulo;

-- ======================================================================
-- CONSULTA 5 — Alunos próximos do limite de empréstimos
-- Tipo: SELECT com GROUP BY + HAVING
-- Finalidade: alertar sobre alunos com 2 ou mais empréstimos ativos
--             (o limite definido no minimundo é 3 simultâneos).
-- ======================================================================
SELECT  a.matricula,
        a.nome,
        COUNT(*) AS emprestimos_ativos
FROM        emprestimo e
JOIN        aluno      a ON a.matricula = e.matricula_aluno
WHERE   e.status = 'Ativo'
GROUP BY a.matricula, a.nome
HAVING  COUNT(*) >= 2
ORDER BY emprestimos_ativos DESC, a.nome;

-- ======================================================================
-- CONSULTA 6 — Fila de reservas por livro com posição
-- Tipo: SELECT com subconsulta correlacionada
-- Finalidade: para cada reserva ativa, calcular sua posição na fila do
--             título (ordenada por data e desempate pelo id_reserva).
-- ======================================================================
SELECT  l.titulo,
        a.nome          AS aluno,
        r.data_reserva,
        ( SELECT COUNT(*)
          FROM   reserva r2
          WHERE  r2.isbn   = r.isbn
            AND  r2.status = 'Ativa'
            AND  ( r2.data_reserva < r.data_reserva
                OR (r2.data_reserva = r.data_reserva AND r2.id_reserva <= r.id_reserva) )
        ) AS posicao_na_fila
FROM        reserva r
JOIN        livro   l ON l.isbn      = r.isbn
JOIN        aluno   a ON a.matricula = r.matricula_aluno
WHERE   r.status = 'Ativa'
ORDER BY l.titulo, posicao_na_fila;

-- ======================================================================
-- CONSULTA 7 — Histórico completo de um aluno
-- Tipo: UNION ALL (empréstimos + reservas) — aqui, aluno 2024003 (Carla)
-- Finalidade: consolidar, numa única lista cronológica, todas as
--             interações do aluno com a biblioteca.
-- ======================================================================
SELECT  'Empréstimo'      AS tipo,
        l.titulo          AS item,
        e.data_emprestimo AS data_evento,
        e.status          AS situacao
FROM        emprestimo e
JOIN        exemplar   ex ON ex.id_exemplar = e.id_exemplar
JOIN        livro      l  ON l.isbn         = ex.isbn
WHERE   e.matricula_aluno = 2024003
UNION ALL
SELECT  'Reserva'         AS tipo,
        l.titulo          AS item,
        r.data_reserva    AS data_evento,
        r.status          AS situacao
FROM        reserva r
JOIN        livro   l ON l.isbn = r.isbn
WHERE   r.matricula_aluno = 2024003
ORDER BY data_evento;

-- ======================================================================
-- CONSULTA 8 — Livros sem nenhum exemplar disponível
-- Tipo: SELECT com NOT EXISTS (e EXISTS para excluir livros sem exemplar)
-- Finalidade: mostrar títulos cujos exemplares estão todos fora de
--             circulação (emprestados, reservados ou indisponíveis).
-- ======================================================================
SELECT  l.isbn,
        l.titulo
FROM        livro l
WHERE   EXISTS (
            SELECT 1 FROM exemplar ex WHERE ex.isbn = l.isbn
        )
  AND   NOT EXISTS (
            SELECT 1 FROM exemplar ex
            WHERE ex.isbn = l.isbn AND ex.status = 'Disponível'
        )
ORDER BY l.titulo;

-- ======================================================================
-- CONSULTA 9 — Autores com mais de um livro no acervo
-- Tipo: SELECT com JOIN + GROUP BY + HAVING + GROUP_CONCAT
-- Finalidade: listar autores com obra múltipla, concatenando seus títulos.
-- ======================================================================
SELECT  au.nome          AS autor,
        au.nacionalidade,
        COUNT(la.isbn)   AS qtd_livros,
        GROUP_CONCAT(l.titulo ORDER BY l.titulo SEPARATOR '; ') AS livros
FROM        autor       au
JOIN        livro_autor la ON la.id_autor = au.id_autor
JOIN        livro       l  ON l.isbn      = la.isbn
GROUP BY au.id_autor, au.nome, au.nacionalidade
HAVING  COUNT(la.isbn) > 1
ORDER BY qtd_livros DESC, autor;

-- ======================================================================
-- CONSULTA 10 — Média de dias de atraso por curso
-- Tipo: SELECT com JOIN + AVG + DATEDIFF + GROUP BY + HAVING
-- Finalidade: identificar os cursos cujos alunos mais atrasam devoluções.
-- ======================================================================
SELECT  c.nome           AS curso,
        COUNT(*)         AS qtd_atrasos,
        ROUND(AVG(DATEDIFF(CURDATE(), e.data_previsao)), 1) AS media_dias_atraso
FROM        emprestimo e
JOIN        aluno      a ON a.matricula = e.matricula_aluno
JOIN        curso      c ON c.id_curso  = a.id_curso
WHERE   e.status = 'Atrasado'
GROUP BY c.id_curso, c.nome
HAVING  AVG(DATEDIFF(CURDATE(), e.data_previsao)) > 0
ORDER BY media_dias_atraso DESC;

-- ======================================================================
-- CONSULTA 11 — Inventário de exemplares por status e conservação
-- Tipo: SELECT com GROUP BY composto + COUNT
-- Finalidade: visão gerencial do acervo físico cruzando situação de
--             circulação com estado de conservação.
-- ======================================================================
SELECT  status,
        conservacao,
        COUNT(*) AS total_exemplares
FROM        exemplar
GROUP BY status, conservacao
ORDER BY status, conservacao;

-- ======================================================================
-- CONSULTA 12 — Alunos que nunca realizaram empréstimo
-- Tipo: anti-join (LEFT JOIN + IS NULL)
-- Finalidade: encontrar alunos cadastrados sem histórico de retirada,
--             úteis para ações de incentivo à leitura.
-- ======================================================================
SELECT  a.matricula,
        a.nome,
        a.status
FROM        aluno      a
LEFT JOIN   emprestimo e ON e.matricula_aluno = a.matricula
WHERE   e.id_emprestimo IS NULL
ORDER BY a.nome;

-- ======================================================================
-- FIM DO QUERIES.SQL
-- ======================================================================
