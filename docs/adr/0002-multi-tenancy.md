# 0002 — A casa é o tenant, desde a primeira tabela

## Contexto

O produto quer, em algum momento, que as pessoas de uma mesma casa vejam a
mesma despensa. Mas a v1 precisa ficar de pé rápido, e convite, aceite e tela
de membros são três fatias que não entregam o momento de valor.

Multi-tenancy retrofitado é migration dolorosa: significa mexer em toda tabela,
toda policy e todo dado já gravado.

## Decisão

**A v1 é single-user na superfície e multi-tenant no modelo.**

- A unidade de compartilhamento é a **casa**. A despensa pertence à casa, nunca
  à pessoa.
- **Toda tabela nasce com `household_id` e RLS ativa**, sem exceção — inclusive
  as da primeira fatia.
- A casa é criada automaticamente no primeiro login. O usuário nunca vê a
  palavra "casa" na v1.
- **Sem papéis.** Todo membro pode tudo: cadastrar, dar baixa, remover. As
  policies verificam pertencimento à casa, nada mais.
- **Uma pessoa pertence a no máximo uma casa.** Não existe seletor de casa em
  tela nenhuma.
- Fica de fora da v1, sem bloquear nada: convite, aceite, lista de membros,
  sair da casa.
- A função de apoio de RLS (`private.household_id_do_usuario()` ou equivalente)
  nasce no schema **`private`**, nunca em `public` — o PostgREST expõe `public`,
  e uma `SECURITY DEFINER` ali fica chamável por `anon`.

## Alternativas descartadas

- **`user_id` na v1, `household_id` depois** — exatamente a migration dolorosa
  que este ADR existe para evitar.
- **Multiusuário completo na v1** — ~3 fatias antes do primeiro fato
  demonstrável.
- **Pessoa em várias casas** — obriga seletor de casa em toda tela e um
  conceito de "casa ativa" que contamina todas as consultas. Se um dia doer,
  vira ADR próprio.

## Consequência

Fácil: ligar o multiusuário depois é uma fatia de convite + aceite. O schema já
está pronto; nenhum dado precisa se mover.

Difícil: nada, na prática. O custo é escrever `household_id` em queries que na
v1 sempre retornam a mesma casa.

Custo aceito: uma coluna e uma policy "inúteis" durante meses.
