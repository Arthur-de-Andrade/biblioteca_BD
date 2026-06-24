# MINIMUNDO — SISTEMA DE BIBLIOTECA ESCOLAR
## CEFET-RJ — Campus Maria da Graça | Banco de Dados 1 | Prof. Rafael Costa

---

## 1. CONTEXTO GERAL

A Biblioteca do CEFET-RJ Campus Maria da Graça atende exclusivamente alunos regularmente matriculados nos cursos técnicos integrados ao ensino médio da instituição. O sistema visa controlar de forma rigorosa o acervo físico, os empréstimos, as devoluções e as reservas de livros, garantindo rastreabilidade de cada exemplar e cumprimento das políticas internas da biblioteca.

---

## 2. ALUNOS E CURSOS

Cada aluno possui matrícula única gerada automaticamente pela instituição, nome completo, e-mail institucional, telefone de contato e data de nascimento. Todo aluno deve estar vinculado a exatamente um curso técnico. Os cursos oferecidos pela instituição possuem nome, turno (manhã, tarde ou noite) e duração em anos. Um aluno só pode realizar empréstimos enquanto estiver com o status "Ativo" no sistema. Alunos com empréstimos em atraso têm o privilégio de novos empréstimos suspenso automaticamente. Cada aluno pode ter no máximo 3 (três) empréstimos ativos simultaneamente.

---

## 3. ACERVO DE LIVROS

O acervo é composto por livros identificados por ISBN único. Cada livro possui título, ano de publicação e pertence a exatamente uma categoria temática (ex.: Ficção Científica, História, Matemática). Cada livro pode ter sido escrito por um ou mais autores cadastrados no sistema. Os autores possuem nome completo e nacionalidade. A relação entre livro e autor é de muitos-para-muitos: um autor pode ter escrito múltiplos livros, e um livro pode ter múltiplos autores.

---

## 4. CATEGORIAS

As categorias organizam o acervo temático da biblioteca. Cada categoria possui um nome único. Um livro pertence a uma única categoria. As categorias incluem, por exemplo: Literatura Brasileira, Literatura Estrangeira, Ficção Científica, História, Matemática, Física, Química, Informática, Filosofia e Artes.

---

## 5. EXEMPLARES

Cada livro pode possuir múltiplos exemplares físicos. Um exemplar representa um objeto físico concreto existente na biblioteca. Cada exemplar possui um número de tombamento único (identificador interno da biblioteca), a data de aquisição, o estado de conservação (Ótimo, Bom, Regular, Danificado) e um status de disponibilidade (Disponível, Emprestado, Reservado, Indisponível). Um exemplar com status "Danificado" ou "Indisponível" não pode ser emprestado. O empréstimo é sempre realizado sobre um exemplar específico, e não sobre o livro em geral. Isso permite rastrear exatamente qual objeto físico está em posse de qual aluno.

---

## 6. EMPRÉSTIMOS

O empréstimo é o registro da retirada de um exemplar por um aluno. Para registrar um empréstimo, o exemplar deve estar com status "Disponível" e o aluno deve estar ativo e sem restrições. A data de empréstimo é registrada automaticamente. O prazo padrão de devolução é de 10 (dez) dias corridos a partir da data de retirada. A data de previsão de devolução é calculada e armazenada no momento do empréstimo. Ao registrar o empréstimo, o status do exemplar é automaticamente alterado para "Emprestado". Um empréstimo pode ter os seguintes status: Ativo, Devolvido ou Atrasado.

---

## 7. DEVOLUÇÕES

A devolução ocorre quando o aluno retorna o exemplar à biblioteca. A data real de devolução é registrada, e o status do empréstimo é atualizado para "Devolvido". O sistema não permite registrar uma data de devolução anterior à data de empréstimo. Após a devolução, o status do exemplar retorna para "Disponível" (ou "Danificado", caso o bibliotecário registre avaria durante a conferência). Se houver uma reserva ativa para o livro correspondente ao exemplar devolvido, o sistema altera automaticamente o status do exemplar para "Reservado", impedindo que outro aluno o retire sem ter reservado.

---

## 8. RESERVAS

Um aluno pode reservar um livro quando todos os exemplares daquele livro estiverem emprestados ou indisponíveis. Não faz sentido reservar um livro que já possui exemplar disponível. A reserva registra o aluno, o livro desejado, a data da reserva e o status (Ativa ou Cancelada). As reservas são atendidas por ordem de data de criação (fila de espera). Quando um exemplar do livro reservado é devolvido, a reserva mais antiga ativa é notificada. O aluno tem 2 (dois) dias úteis para comparecer e realizar o empréstimo; caso contrário, a reserva é cancelada automaticamente.

---

## 9. LIMITES E RESTRIÇÕES

As seguintes regras de negócio são aplicadas pelo sistema:

- Um aluno não pode ter mais de 3 empréstimos ativos ao mesmo tempo.
- Um exemplar com status diferente de "Disponível" não pode ser emprestado.
- A data de devolução real não pode ser anterior à data do empréstimo.
- A matrícula do aluno é única no sistema.
- O ISBN de cada livro é único no sistema.
- O número de tombamento de cada exemplar é único no sistema.
- Um livro disponível no acervo não pode ser reservado; a reserva é válida apenas quando todos os exemplares estão indisponíveis.
- Alunos com empréstimos em atraso não podem realizar novos empréstimos até quitar a pendência.
- O estado de conservação de um exemplar não pode ser melhorado manualmente sem justificativa de restauração.
- A data de nascimento do aluno é obrigatória e deve ser informada no cadastro.

---

## 10. NORMALIZAÇÃO E INTEGRIDADE

O banco de dados é projetado para estar na Terceira Forma Normal (3FN). Isso significa que:

- Não há grupos repetitivos (1FN).
- Todo atributo não-chave depende da chave primária inteira (2FN).
- Não há dependências transitivas entre atributos não-chave (3FN).

A relação Livro–Autor é implementada por uma tabela associativa (livro_autor), pois é um relacionamento muitos-para-muitos. O curso do aluno é uma entidade separada, eliminando a dependência transitiva que existia quando o curso era um atributo textual da tabela aluno.

---

## 11. RESUMO DAS ENTIDADES

| Entidade    | Descrição                                                  |
|-------------|------------------------------------------------------------|
| Curso       | Cursos técnicos integrados ao ensino médio                 |
| Aluno       | Alunos matriculados, vinculados a um curso                 |
| Categoria   | Classificação temática dos livros                          |
| Autor       | Autores dos livros do acervo                               |
| Livro       | Títulos do acervo identificados por ISBN                   |
| Livro_Autor | Tabela associativa entre Livro e Autor (N:M)               |
| Exemplar    | Objetos físicos individuais de cada livro                  |
| Emprestimo  | Registro de retirada de um exemplar por um aluno           |
| Reserva     | Fila de espera de um aluno para um livro indisponível      |
