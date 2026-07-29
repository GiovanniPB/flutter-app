-- A casa é o tenant, desde a primeira tabela (ADR 0002).
-- Toda tabela do sistema pendura em household_id e nasce com RLS.

create schema if not exists private;

-- ---------------------------------------------------------------- tabelas

create table public.households (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

comment on table public.households is
  'Tenant. A despensa pertence à casa, nunca à pessoa.';

create table public.household_members (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  -- Uma pessoa pertence a no máximo uma casa (ADR 0002). Sem seletor de casa.
  constraint household_members_one_per_user unique (user_id)
);

create index household_members_household_id_idx
  on public.household_members (household_id);

-- ------------------------------------------------------------ updated_at

-- Trigger cuida só de updated_at. Regra de negócio vive no domain, em Dart
-- (ADR 0005).
create function public.touch_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

revoke execute on function public.touch_updated_at()
  from anon, authenticated, public;

create trigger households_touch_updated_at
  before update on public.households
  for each row execute function public.touch_updated_at();

create trigger household_members_touch_updated_at
  before update on public.household_members
  for each row execute function public.touch_updated_at();

-- ------------------------------------------- provisionamento do tenant

-- Provisionar tenant é infraestrutura, não regra de negócio (ADR 0009):
-- roda na mesma transação do insert em auth.users, o que torna impossível
-- existir usuário autenticado sem casa.
create function public.provision_household()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  new_household uuid;
begin
  insert into public.households default values
    returning id into new_household;

  insert into public.household_members (household_id, user_id)
    values (new_household, new.id);

  return new;
end;
$$;

revoke execute on function public.provision_household()
  from anon, authenticated, public;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.provision_household();

-- ---------------------------------------------------------------- RLS

-- Apoio de RLS nasce em private, nunca em public: o PostgREST expõe public,
-- e uma SECURITY DEFINER ali fica chamável por anon.
create function private.current_household()
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select m.household_id
  from public.household_members m
  where m.user_id = auth.uid()
    and m.deleted_at is null
  limit 1;
$$;

-- Diferente das funções de trigger: esta é avaliada dentro da policy, como o
-- usuário que consulta. Sem EXECUTE, a própria RLS quebra. O que a protege é o
-- schema private não estar exposto pelo PostgREST, não a falta de privilégio.
revoke execute on function private.current_household() from public, anon;
grant usage on schema private to authenticated;
grant execute on function private.current_household() to authenticated;

alter table public.households enable row level security;
alter table public.household_members enable row level security;

-- Só leitura: quem escreve nessas duas tabelas é o trigger de
-- provisionamento, que roda como SECURITY DEFINER e não passa por policy.
create policy "own household is readable"
  on public.households
  for select
  to authenticated
  using (id = private.current_household());

create policy "own household membership is readable"
  on public.household_members
  for select
  to authenticated
  using (household_id = private.current_household());
