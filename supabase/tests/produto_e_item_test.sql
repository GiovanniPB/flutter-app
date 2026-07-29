-- Invariantes de produto e item. Roda com `bash tool/test_db.sh`.
--
-- Toda asserção é relativa aos dados que este arquivo cria: contagem absoluta
-- passa em banco recém-resetado e quebra no primeiro uso local.

begin;
create extension if not exists pgtap;
select plan(10);

-- Duas casas, criadas pelo trigger de provisionamento.
insert into auth.users (id, instance_id, aud, role, email) values
  ('aaaaaaaa-0000-0000-0000-000000000001',
   '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'casa-a@exemplo.test'),
  ('bbbbbbbb-0000-0000-0000-000000000002',
   '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'casa-b@exemplo.test');

create temporary view casas as
  select
    (select household_id from public.household_members
     where user_id = 'aaaaaaaa-0000-0000-0000-000000000001') as a,
    (select household_id from public.household_members
     where user_id = 'bbbbbbbb-0000-0000-0000-000000000002') as b;

-- A view é criada como postgres; sem isto ela fica ilegível depois do
-- `set local role authenticated`, e o teste falha por permissão, não por regra.
grant select on casas to authenticated;

insert into public.products (id, household_id, name)
select '11111111-aaaa-0000-0000-000000000001', a, 'Arroz Tio João 5 kg' from casas;

insert into public.products (id, household_id, name)
select '22222222-bbbb-0000-0000-000000000002', b, 'Feijão da casa B' from casas;

insert into public.pantry_items
  (id, household_id, product_id, expires_on, initial_quantity)
select
  '33333333-aaaa-0000-0000-000000000001', a,
  '11111111-aaaa-0000-0000-000000000001', '2027-03-12', 1
from casas;

-- ------------------------------------------------------- restrições

select throws_ok(
  $$insert into public.pantry_items (household_id, product_id, expires_on)
    select a, '11111111-aaaa-0000-0000-000000000001', null from casas$$,
  '23502',
  null,
  'item sem validade é recusado'
);

select throws_ok(
  $$insert into public.pantry_items
      (household_id, product_id, expires_on, initial_quantity)
    select a, '11111111-aaaa-0000-0000-000000000001', '2027-01-01', 0 from casas$$,
  '23514',
  null,
  'quantidade zero é recusada'
);

select throws_ok(
  $$insert into public.products (household_id, name) select a, '   ' from casas$$,
  '23514',
  null,
  'nome em branco não vira produto'
);

-- ADR 0006: não existe produto com casa e EAN ao mesmo tempo.
select throws_ok(
  $$insert into public.products (household_id, name, ean)
    select a, 'Híbrido', '7891234567895' from casas$$,
  '23514',
  null,
  'produto da casa não pode ter EAN'
);

select throws_ok(
  $$insert into public.pantry_items
      (household_id, product_id, expires_on, location)
    select a, '11111111-aaaa-0000-0000-000000000001', '2027-01-01', 'garagem'
    from casas$$,
  '23514',
  null,
  'local fora da lista é recusado'
);

-- ------------------------------------------------------------- RLS

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"aaaaaaaa-0000-0000-0000-000000000001","role":"authenticated"}',
  true
);

select is(
  (select count(*) from public.products
   where id = '22222222-bbbb-0000-0000-000000000002')::int,
  0,
  'produto da outra casa não é visível'
);

select is(
  (select count(*) from public.products
   where id = '11111111-aaaa-0000-0000-000000000001')::int,
  1,
  'o próprio produto é visível'
);

select is(
  (select count(*) from public.pantry_items)::int,
  1,
  'a casa lê só os próprios itens'
);

-- O default de household_id é o que mantém a casa fora do domínio: o cliente
-- insere sem informá-la.
insert into public.products (name) values ('Leite integral 1 L');

select is(
  (select household_id from public.products where name = 'Leite integral 1 L'),
  (select a from casas),
  'insert sem household_id herda a casa da sessão'
);

select throws_ok(
  $$insert into public.products (name) values ('Leite integral 1 L')$$,
  '23505',
  null,
  'um nome, um produto por casa'
);

select * from finish();
rollback;
