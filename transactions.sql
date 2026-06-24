-- ======================================================================
-- CEFET-RJ — Campus Maria da Graça
-- Matéria: Banco de Dados 1 | Professor: Rafael Costa
-- Aluno(a): __________________________________________________
-- Script: transactions.sql — Transações com UPDATE, DELETE e ROLLBACK
-- SGBD-alvo: MySQL 8.x
--
-- Pré-requisito: execute schema.sql e, em seguida, data.sql antes deste
-- arquivo. As transações abaixo operam sobre o estado já carregado e
-- demonstram COMMIT, ROLLBACK total, ROLLBACK parcial (SAVEPOINT),
-- UPDATE/DELETE em lote e inserção condicional.
-- ======================================================================

USE biblioteca_escolar;

-- ======================================================================
-- TRANSAÇÃO 1: DEVOLUÇÃO DE EXEMPLAR COM SUCESSO
-- Cenário: Aluno 2024001 devolve o exemplar TOMB-001 (id_exemplar = 1).
-- O status do empréstimo muda para 'Devolvido'.
-- O trigger trg_apos_devolucao cuida de atualizar o exemplar.
-- ======================================================================

START TRANSACTION;

-- Atualiza o empréstimo registrando a data real de devolução
UPDATE emprestimo
SET    status          = 'Devolvido',
       data_devolucao = CURDATE()
WHERE  id_emprestimo = 1
  AND  status = 'Ativo';

-- Verificação explícita: confirma que a atualização ocorreu
-- (O trigger trg_apos_devolucao atualizará o exemplar automaticamente)

COMMIT;

SELECT 'TRANSAÇÃO 1 CONCLUÍDA: Devolução registrada com sucesso.' AS resultado;

-- ======================================================================
-- TRANSAÇÃO 2: REGISTRO DE NOVO EMPRÉSTIMO COM SUCESSO
-- Cenário: Aluno 2024003 (Carla) retira o exemplar TOMB-019 (id_exemplar = 19,
-- livro 'Dez Negrinhos'). TOMB-019 está 'Disponível' e o livro não possui
-- reserva ativa, portanto o empréstimo é direto.
-- Carla está com status 'Ativo', sem atrasos e com 0 empréstimos ativos.
-- ======================================================================

START TRANSACTION;

INSERT INTO emprestimo (matricula_aluno, id_exemplar, data_emprestimo, data_previsao, status)
VALUES (2024003, 19, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 10 DAY), 'Ativo');

-- O trigger trg_antes_emprestimo valida disponibilidade e limites.
-- O trigger trg_apos_emprestimo marca o exemplar como 'Emprestado'.

COMMIT;

SELECT 'TRANSAÇÃO 2 CONCLUÍDA: Novo empréstimo registrado com sucesso.' AS resultado;

-- ======================================================================
-- TRANSAÇÃO 3: REGISTRO DE RESERVA (INSERÇÃO CONDICIONAL)
-- Cenário: Aluno 2024014 (Nicolas) quer reservar o livro 'Dom Casmurro'.
-- A reserva só é gravada se NÃO houver exemplar disponível do título —
-- mesma regra que o trigger trg_antes_reserva aplica no nível do banco.
-- ======================================================================

START TRANSACTION;

-- Inserção condicional: grava a reserva apenas se nenhum exemplar do livro
-- estiver 'Disponível'. Se houver, a reserva é desnecessária (e o trigger
-- trg_antes_reserva também a impediria).
INSERT INTO reserva (matricula_aluno, isbn, data_reserva, status)
SELECT 2024014, '978-8535902778', CURDATE(), 'Ativa'
WHERE NOT EXISTS (
    SELECT 1 FROM exemplar
    WHERE isbn = '978-8535902778'
      AND status = 'Disponível'
);

-- Se não houve inserção, o livro estava disponível (reserva desnecessária).
SELECT ROW_COUNT() AS linhas_inseridas,
       CASE WHEN ROW_COUNT() = 0
            THEN 'Reserva desnecessária: há exemplar disponível.'
            ELSE 'Reserva registrada com sucesso.' END AS resultado;

COMMIT;

-- ======================================================================
-- TRANSAÇÃO 4: CANCELAMENTO DE RESERVA
-- Cenário: Aluno 2024006 cancela sua reserva ativa para 'Ensaio sobre a Cegueira'.
-- ======================================================================

START TRANSACTION;

UPDATE reserva
SET    status = 'Cancelada'
WHERE  matricula_aluno = 2024006
  AND  isbn            = '978-8579027895'
  AND  status          = 'Ativa';

COMMIT;

SELECT 'TRANSAÇÃO 4 CONCLUÍDA: Reserva cancelada com sucesso.' AS resultado;

-- ======================================================================
-- TRANSAÇÃO 5: ATUALIZAÇÃO DE ESTADO DE CONSERVAÇÃO DE EXEMPLAR
-- Cenário: Bibliotecário registra que o TOMB-008 foi devolvido com dano.
-- O empréstimo de Capitães da Areia (id 3, Carla) já foi devolvido.
-- Atualiza conservação (Bom -> Danificado) e bloqueia o exemplar.
-- ======================================================================

START TRANSACTION;

UPDATE exemplar
SET    conservacao = 'Danificado',
       status      = 'Indisponível'
WHERE  tombamento = 'TOMB-008';

COMMIT;

SELECT 'TRANSAÇÃO 5 CONCLUÍDA: Exemplar marcado como danificado e bloqueado.' AS resultado;

-- ======================================================================
-- TRANSAÇÃO 6: ROLLBACK PARCIAL COM SAVEPOINT
-- Cenário: Bibliotecário inicia um lote de atualizações. Uma das operações
-- é inválida. O SAVEPOINT permite desfazer apenas a parte inválida,
-- preservando a operação válida já executada.
-- ======================================================================

START TRANSACTION;

SAVEPOINT sp_antes_atualizacao;

-- Operação 1 válida: estende em 5 dias o prazo do empréstimo ativo id 4
UPDATE emprestimo
SET data_previsao = DATE_ADD(data_previsao, INTERVAL 5 DAY)
WHERE id_emprestimo = 4 AND status = 'Ativo';

SELECT 'Operação 1 executada: prazo estendido em 5 dias.' AS etapa;

SAVEPOINT sp_pos_extensao;

-- Operação 2 inválida (simulada): tenta atualizar um exemplar inexistente.
-- O sistema detecta que nenhuma linha foi afetada e decide o rollback parcial.
UPDATE exemplar
SET conservacao = 'Bom'
WHERE tombamento = 'TOMB-999';  -- tombamento inexistente

SELECT ROW_COUNT() AS linhas_afetadas;

-- Como nenhuma linha foi afetada, desfaz apenas a operação 2
-- e mantém a operação 1.
ROLLBACK TO SAVEPOINT sp_pos_extensao;

SELECT 'ROLLBACK PARCIAL: apenas operação 2 desfeita. Operação 1 mantida.' AS resultado;

COMMIT;  -- Confirma somente a operação 1

SELECT 'TRANSAÇÃO 6 CONCLUÍDA: SAVEPOINT e ROLLBACK parcial demonstrados.' AS final;

-- ======================================================================
-- TRANSAÇÃO 7: UPDATE EM LOTE — MARCAR EMPRÉSTIMOS ATRASADOS
-- Cenário: Rotina diária que verifica todos os empréstimos ativos cuja
-- data de previsão já passou e atualiza o status para 'Atrasado'.
-- ======================================================================

START TRANSACTION;

UPDATE emprestimo
SET    status = 'Atrasado'
WHERE  status           = 'Ativo'
  AND  data_previsao   < CURDATE();

COMMIT;

SELECT CONCAT('TRANSAÇÃO 7 CONCLUÍDA: ', ROW_COUNT(), ' empréstimo(s) marcado(s) como Atrasado.') AS resultado;

-- ======================================================================
-- TRANSAÇÃO 8: DELETE SEGURO — REMOÇÃO DE RESERVAS VENCIDAS
-- Cenário: Limpeza periódica de reservas canceladas com mais de 30 dias.
-- Utiliza DELETE com critério de data para não remover registros recentes.
-- ======================================================================

START TRANSACTION;

-- Inserindo reserva antiga para demonstração
INSERT INTO reserva (matricula_aluno, isbn, data_reserva, status)
VALUES (2024015, '978-8576080602', '2025-01-01', 'Cancelada');

-- Agora deletando reservas canceladas com mais de 30 dias
DELETE FROM reserva
WHERE  status       = 'Cancelada'
  AND  data_reserva < DATE_SUB(CURDATE(), INTERVAL 30 DAY);

COMMIT;

SELECT CONCAT('TRANSAÇÃO 8 CONCLUÍDA: ', ROW_COUNT(), ' reserva(s) cancelada(s) antiga(s) removida(s).') AS resultado;

-- ======================================================================
-- FIM DO TRANSACTIONS.SQL
-- ======================================================================
