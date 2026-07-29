-- Produto (a ficha) e item da despensa (a coisa). Dois conceitos separados: é
-- isso que permite dois pacotes do mesmo arroz com validades diferentes, e que
-- faz renomear um produto não reescrever o passado.
--
-- Valores de enumeração ficam em inglês, como todo identificador; a tradução é
-- da interface.

-- ------------------------------------------------------------- produto

create table public.products (
  id uuid primary key default gen_random_uuid(),
  -- Nulo = produto canônico, global, vindo de EAN (ADR 0006). Nenhuma tela
  -- cria canônico nesta fatia; a coluna existe para não pagar migration depois.
  --
  -- O default é o que mantém a casa FORA do domínio: o cliente nunca envia
  -- household_id, e a policy de insert continua validando. Mesma categoria da
  -- ADR 0009 — plumbing de tenant, não regra de negócio.
  household_id uuid default private.current_household()
    references public.households (id) on delete cascade,
  name text not null,
  brand text,
  ean text,
  food_category text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,

  constraint products_name_not_blank check (btrim(name) <> ''),

  -- ADR 0006: canônico tem EAN e não pertence a ninguém; produto da casa
  -- pertence a uma casa e não tem EAN. Não existe meio caminho.
  constraint products_provenance check (
    (household_id is not null and ean is null)
    or (household_id is null and ean is not null)
  ),

  -- Lista fixa, definida por nós (ADR 0006). Serve só para sugerir prazo ao
  -- congelar, numa fatia futura.
  constraint products_food_category check (
    food_category is null
    or food_category in (
      'dairy', 'meat', 'produce', 'grocery', 'frozen', 'beverage', 'other'
    )
  )
);

create unique index products_ean_unique
  on public.products (ean) where ean is not null;

-- Um nome, um produto por casa: é o que faz "digitar um nome novo cria o
-- produto e reaproveita nas próximas vezes" (ADR 0006) virar um upsert só, sem
-- o cliente decidir nada.
--
-- Restrição, não índice parcial: índice com WHERE **não** serve como alvo de
-- `on conflict`, e o upsert falha com "no unique or exclusion constraint
-- matching". Como o Postgres trata NULL como distinto, o catálogo canônico
-- (household_id nulo) continua livre — quem o restringe é products_ean_unique.
alter table public.products
  add constraint products_household_name_unique unique (household_id, name);

create index products_household_id_idx
  on public.products (household_id) where household_id is not null;

comment on table public.products is
  'Ficha do produto. Não tem validade nem quantidade — isso é do item.';

-- ---------------------------------------------------------------- item

create table public.pantry_items (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null default private.current_household()
    references public.households (id) on delete cascade,
  product_id uuid not null references public.products (id),
  -- Quantidade INICIAL, imutável. A atual será inicial menos a soma dos
  -- movimentos (ADR 0005) — a tabela de movimentos nasce na fatia `baixa`,
  -- junto com quem escreve nela.
  initial_quantity integer not null default 1,
  expires_on date not null,
  purchased_on date,
  location text,
  -- Inteiro em centavos, BRL (ADR 0003). Nenhuma tela lê nesta fatia.
  price_cents integer,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,

  constraint pantry_items_quantity_positive check (initial_quantity >= 1),
  constraint pantry_items_price_non_negative check (
    price_cents is null or price_cents >= 0
  ),
  constraint pantry_items_location check (
    location is null or location in ('pantry', 'fridge', 'freezer')
  )
);

create index pantry_items_household_id_idx
  on public.pantry_items (household_id);

create index pantry_items_expires_on_idx
  on public.pantry_items (household_id, expires_on);

comment on table public.pantry_items is
  'Um pacote concreto na casa. Validade é obrigatória.';

-- ------------------------------------------------------------ updated_at

create trigger products_touch_updated_at
  before update on public.products
  for each row execute function public.touch_updated_at();

create trigger pantry_items_touch_updated_at
  before update on public.pantry_items
  for each row execute function public.touch_updated_at();

-- ------------------------------------------------------------------ RLS

alter table public.products enable row level security;
alter table public.pantry_items enable row level security;

-- Produto canônico é legível por todas as casas e não é escrito por ninguém
-- pela API. Produto da casa é escrito pela casa dona.
create policy "own or canonical product is readable"
  on public.products
  for select
  to authenticated
  using (household_id is null or household_id = private.current_household());

create policy "own product is writable"
  on public.products
  for insert
  to authenticated
  with check (household_id = private.current_household());

create policy "own product is updatable"
  on public.products
  for update
  to authenticated
  using (household_id = private.current_household())
  with check (household_id = private.current_household());

create policy "own items are readable"
  on public.pantry_items
  for select
  to authenticated
  using (household_id = private.current_household());

create policy "own items are writable"
  on public.pantry_items
  for insert
  to authenticated
  with check (household_id = private.current_household());

create policy "own items are updatable"
  on public.pantry_items
  for update
  to authenticated
  using (household_id = private.current_household())
  with check (household_id = private.current_household());
