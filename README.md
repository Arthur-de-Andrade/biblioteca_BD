# Sistema de Biblioteca Escolar 📚
### CEFET-RJ — Campus Maria da Graça | Trabalho Prático de Banco de Dados 1
**Professor:** Rafael Costa  
**Estudante:** Arthur de Andrade  

---

## 📄 Sobre o Projeto
Este repositório contém o desenvolvimento completo do banco de dados relacional para o **Sistema de Biblioteca Escolar do CEFET-RJ (Campus Maria da Graça)**. O sistema foi projetado para gerenciar de forma rigorosa o acervo físico, o fluxo de empréstimos, as devoluções e a fila de reservas de livros, atendendo exclusivamente os alunos matriculados nos cursos técnicos integrados ao ensino médio.

O banco de dados foi construído seguindo as regras de negócio descritas no escopo do projeto, garantindo integridade de dados por meio de restrições de integridade, triggers automáticos e transações ACID robustas, estando totalmente normalizado na **Terceira Forma Normal (3FN)**.

---

## 🛠️ Tecnologias Utilizadas
* **SGBD:** MySQL 8.x
* **Linguagem:** SQL (DDL, DML, DQL e DTL)
* **Modelagem:** Modelo Entidade-Relacionamento (Gabarito Peter Chen & Modelo Físico)

---

## 📁 Estrutura do Repositório

O projeto está modularizado nos seguintes arquivos:

* **`MINIMUNDO.md`**: Descrição detalhada do cenário de negócios, entidades, restrições e regras de validação da biblioteca.
* **`schema.sql`**: Script de automação DDL contendo a criação do banco de dados `biblioteca_escolar`, definição detalhada de tabelas, chaves primárias/estrangeiras, índices de performance e os **Triggers** de validação de regras de negócio.
* **`data.sql`**: Script DML com a carga inicial de dados simulados (População de cursos, alunos, autores, livros, exemplares, empréstimos históricos e filas de reserva) garantindo consistência com os estados dinâmicos.
* **`queries.sql`**: Conjunto de 12 consultas complexas (DQL) cobrindo junções múltiplas (`JOIN`), agregações com agrupamentos (`GROUP BY / HAVING`), subconsultas e tratamento analítico de datas.
* **`transactions.sql`**: Conjunto de 8 transações controladas (DTL) que demonstram o uso de controle de concorrência, `COMMIT`, `ROLLBACK` total e controle parcial com `SAVEPOINT`.
* **`Peter_chen.png`**: Diagrama do modelo conceitual utilizando a notação clássica de Peter Chen.
* **`Modelo_fisico.png`**: Diagrama do modelo físico gerado a partir do mapeamento relacional das tabelas.

---

## ⚙️ Ordem de Execução dos Scripts

Para rodar e testar o projeto localmente em sua instância do MySQL, execute os arquivos estritamente na seguinte ordem:

1. **`schema.sql`** — Cria a estrutura do banco, tabelas e injeta a inteligência de negócios (Triggers).
2. **`data.sql`** — Alimenta o banco com dados iniciais respeitando os gatilhos criados.
3. **`queries.sql`** — Executa os relatórios gerenciais e consultas de auditoria.
4. **`transactions.sql`** — Executa os fluxos operacionais controlados (Devoluções, renovações, suspensão e limpeza de histórico).

---

## 🛡️ Principais Regras de Negócio Automatizadas por Trigger

O banco possui integridade automatizada diretamente no motor do banco de dados:
* **Limite de Empréstimos:** Bloqueio automático caso um aluno tente retirar mais de 3 livros simultaneamente ou se possuir pendências em atraso.
* **Gerenciamento Automático de Status:** Sempre que um empréstimo ou reserva é efetuada/devolvida, o status do `exemplar` físico muda automaticamente para *Emprestado*, *Disponível* ou *Reservado*.
* **Histórico de Conservação Interditado:** O gatilho `trg_antes_conservacao` impede que o estado físico de um livro seja "melhorado" manualmente (ex: de 'Danificado' para 'Ótimo') sem que haja uma transação formal de restauração.

---
*Este repositório foi construído com propósitos acadêmicos para a disciplina de Banco de Dados 1 do CEFET-RJ.*