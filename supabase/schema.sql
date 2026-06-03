create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  tx_date date not null,
  type text not null check (type in ('entrada', 'saida', 'investimento', 'diario')),
  category text not null,
  description text,
  amount numeric(14,2) not null check (amount >= 0),
  payment_method text not null default 'conta_corrente' check (payment_method in ('conta_corrente', 'cartao_credito')),
  card_bill_month date,
  status text not null default 'previsto' check (status in ('previsto', 'confirmado', 'pago')),
  source text not null default 'manual',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.recurring_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null,
  account_kind text not null default 'fixa' check (account_kind in ('fixa', 'variavel')),
  day_of_month integer not null check (day_of_month between 1 and 31),
  type text not null check (type in ('entrada', 'saida', 'investimento', 'diario')),
  category text not null,
  amount numeric(14,2) not null check (amount >= 0),
  payment_method text not null default 'conta_corrente' check (payment_method in ('conta_corrente', 'cartao_credito')),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.budgets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  month date not null,
  category text not null,
  limit_amount numeric(14,2) not null check (limit_amount >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, month, category)
);

create table if not exists public.app_settings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  key text not null,
  value jsonb not null default 'null'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, key)
);

create table if not exists public.investments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  asset text not null,
  shares numeric(14,4) not null default 0 check (shares >= 0),
  price numeric(14,4) not null default 0 check (price >= 0),
  segment text,
  dividend_per_share numeric(14,4) not null default 0 check (dividend_per_share >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.mei_invoices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  reference text not null,
  issued_at date not null,
  amount numeric(14,2) not null check (amount >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists transactions_user_date_idx on public.transactions (user_id, tx_date desc);
create index if not exists recurring_items_user_day_idx on public.recurring_items (user_id, day_of_month);

alter table public.transactions
  add column if not exists payment_method text not null default 'conta_corrente',
  add column if not exists card_bill_month date;

alter table public.recurring_items
  add column if not exists payment_method text not null default 'conta_corrente',
  add column if not exists account_kind text not null default 'fixa';

create index if not exists transactions_user_card_bill_idx on public.transactions (user_id, card_bill_month);

do $$
begin
  alter table public.transactions
    add constraint transactions_payment_method_check
    check (payment_method in ('conta_corrente', 'cartao_credito'));
exception when duplicate_object then null;
end;
$$;

do $$
begin
  alter table public.recurring_items
    add constraint recurring_items_payment_method_check
    check (payment_method in ('conta_corrente', 'cartao_credito'));
exception when duplicate_object then null;
end;
$$;

do $$
begin
  alter table public.recurring_items
    add constraint recurring_items_account_kind_check
    check (account_kind in ('fixa', 'variavel'));
exception when duplicate_object then null;
end;
$$;

do $$
declare
  tbl text;
begin
  foreach tbl in array array['transactions','recurring_items','budgets','app_settings','investments','mei_invoices']
  loop
    execute format('alter table public.%I enable row level security', tbl);
    execute format('drop policy if exists "Users manage own rows" on public.%I', tbl);
    execute format(
      'create policy "Users manage own rows" on public.%I for all to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id)',
      tbl
    );
    execute format('drop trigger if exists set_%I_updated_at on public.%I', tbl, tbl);
    execute format(
      'create trigger set_%I_updated_at before update on public.%I for each row execute function public.set_updated_at()',
      tbl,
      tbl
    );
  end loop;
end;
$$;

grant usage on schema public to authenticated;
grant select, insert, update, delete on
  public.transactions,
  public.recurring_items,
  public.budgets,
  public.app_settings,
  public.investments,
  public.mei_invoices
to authenticated;
