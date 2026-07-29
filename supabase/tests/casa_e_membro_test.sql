-- Invariantes de banco da fatia `entrar`. Roda com `bash tool/test_db.sh`.
-- Fica fora do CI: exige Docker no runner (ADR 0008, mesma regra do golden).
--
-- Toda asserção é **relativa aos usuários que este arquivo cria**. Contagem
-- absoluta (`count(*) from households = 1`) passa só em banco recém-resetado e
-- quebra na primeira vez que alguém usa o app local.

begin;
create extension if not exists pgtap;
select plan(6);

-- --------------------------------------------------- primeiro login

insert into auth.users (id, instance_id, aud, role, email)
values (
  '11111111-1111-1111-1111-111111111111',
  '00000000-0000-0000-0000-000000000000',
  'authenticated', 'authenticated', 'ana@exemplo.test'
);

select is(
  (select count(*) from public.household_members
   where user_id = '11111111-1111-1111-1111-111111111111')::int,
  1,
  'primeiro login cria exatamente um vínculo'
);

select is(
  (select count(*)
   from public.households h
   join public.household_members m on m.household_id = h.id
   where m.user_id = '11111111-1111-1111-1111-111111111111')::int,
  1,
  'e a casa desse vínculo existe'
);

-- ------------------------------------------------- segundo usuário

insert into auth.users (id, instance_id, aud, role, email)
values (
  '22222222-2222-2222-2222-222222222222',
  '00000000-0000-0000-0000-000000000000',
  'authenticated', 'authenticated', 'bruno@exemplo.test'
);

select isnt(
  (select household_id from public.household_members
   where user_id = '11111111-1111-1111-1111-111111111111'),
  (select household_id from public.household_members
   where user_id = '22222222-2222-2222-2222-222222222222'),
  'cada usuário ganha a própria casa'
);

select throws_ok(
  $$insert into public.household_members (household_id, user_id)
    values (
      (select household_id from public.household_members
       where user_id = '11111111-1111-1111-1111-111111111111'),
      '22222222-2222-2222-2222-222222222222'
    )$$,
  '23505',
  null,
  'uma pessoa não entra numa segunda casa'
);

-- ------------------------------------------------------------- RLS
-- Estas duas são relativas por natureza: a RLS filtra para a casa da própria
-- pessoa, não importa quantas existam no banco.

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}',
  true
);

select is(
  (select count(*) from public.households)::int,
  1,
  'a pessoa lê só a própria casa'
);

select is(
  (select id from public.households),
  (select household_id from public.household_members
   where user_id = '11111111-1111-1111-1111-111111111111'),
  'e a casa que ela lê é a dela'
);

select * from finish();
rollback;
