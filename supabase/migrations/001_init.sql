-- DJ Aiodip — core schema (run in Supabase SQL editor)
-- Pricing: $16/mo (7-day free trial via store), quota $3.20 after code rules

create extension if not exists "pgcrypto";

-- Profiles (1:1 with auth.users)
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text,
  display_name text,
  -- subscription / entitlement (store is source of truth; synced by webhooks later)
  plan text not null default 'none' check (plan in ('none', 'trial', 'full', 'quota')),
  price_cents int not null default 1600,
  trial_ends_at timestamptz,
  subscription_status text not null default 'inactive'
    check (subscription_status in ('inactive', 'trialing', 'active', 'expired', 'canceled')),
  store_product_id text,
  applied_quota_code text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Inviter quota codes
create table if not exists public.quota_codes (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete cascade,
  code text not null unique,
  use_count int not null default 0,
  unlock_at int not null default 4,
  unlocked bool not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists quota_codes_owner_uidx on public.quota_codes (owner_id);
create index if not exists quota_codes_code_idx on public.quota_codes (code);

-- Each paid/trial subscribe that used a code (invitee)
create table if not exists public.quota_redemptions (
  id uuid primary key default gen_random_uuid(),
  code_id uuid not null references public.quota_codes (id) on delete cascade,
  code text not null,
  redeemer_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (code_id, redeemer_id)
);

-- Projects + tracks
create table if not exists public.projects (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete cascade,
  title text not null default 'Untitled mix',
  status text not null default 'draft',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.project_tracks (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects (id) on delete cascade,
  name text not null,
  storage_path text,
  duration_ms int,
  bpm numeric,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

-- Auto profile on signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, display_name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1))
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Redeem quota code: invitee gets $3.20; bump inviter count; unlock at 4
create or replace function public.redeem_quota_code(p_code text)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_row public.quota_codes%rowtype;
  v_norm text;
begin
  if v_uid is null then
    raise exception 'Not authenticated';
  end if;

  v_norm := upper(trim(p_code));
  select * into v_row from public.quota_codes where code = v_norm;
  if not found then
    raise exception 'Invalid quota code';
  end if;
  if v_row.owner_id = v_uid then
    raise exception 'You cannot use your own code';
  end if;

  insert into public.quota_redemptions (code_id, code, redeemer_id)
  values (v_row.id, v_norm, v_uid)
  on conflict (code_id, redeemer_id) do nothing;

  update public.quota_codes q
  set
    use_count = (select count(*)::int from public.quota_redemptions r where r.code_id = q.id),
    unlocked = (select count(*) from public.quota_redemptions r where r.code_id = q.id) >= q.unlock_at,
    updated_at = now()
  where q.id = v_row.id
  returning * into v_row;

  -- Invitee entitlement path (store offer applied in app; we record intent)
  update public.profiles
  set
    applied_quota_code = v_norm,
    plan = 'quota',
    price_cents = 320,
    updated_at = now()
  where id = v_uid;

  -- If inviter unlocked, mark their price for $3.20 checkout
  if v_row.unlocked then
    update public.profiles
    set price_cents = 320, updated_at = now()
    where id = v_row.owner_id and subscription_status in ('inactive', 'trialing', 'expired');
  end if;

  return json_build_object(
    'code', v_row.code,
    'use_count', v_row.use_count,
    'unlocked', v_row.unlocked,
    'price_cents', 320
  );
end;
$$;

-- Create / upsert own quota code
create or replace function public.create_quota_code(p_code text)
returns public.quota_codes
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_norm text;
  v_out public.quota_codes%rowtype;
begin
  if v_uid is null then
    raise exception 'Not authenticated';
  end if;
  v_norm := upper(regexp_replace(trim(p_code), '[^A-Z0-9-]', '', 'g'));
  if length(v_norm) < 8 then
    raise exception 'Code too short';
  end if;
  if v_norm not like 'AIODIP-%' then
    v_norm := 'AIODIP-' || v_norm;
  end if;

  insert into public.quota_codes (owner_id, code)
  values (v_uid, v_norm)
  on conflict (owner_id) do update
    set code = excluded.code, updated_at = now()
  returning * into v_out;

  return v_out;
end;
$$;

alter table public.profiles enable row level security;
alter table public.quota_codes enable row level security;
alter table public.quota_redemptions enable row level security;
alter table public.projects enable row level security;
alter table public.project_tracks enable row level security;

create policy "profiles_select_own" on public.profiles for select using (auth.uid() = id);
create policy "profiles_update_own" on public.profiles for update using (auth.uid() = id);

create policy "quota_select_own" on public.quota_codes for select using (auth.uid() = owner_id);
create policy "quota_select_by_code" on public.quota_codes for select using (true);
create policy "quota_insert_own" on public.quota_codes for insert with check (auth.uid() = owner_id);
create policy "quota_update_own" on public.quota_codes for update using (auth.uid() = owner_id);

create policy "redemptions_select_related" on public.quota_redemptions
  for select using (
    auth.uid() = redeemer_id
    or auth.uid() in (select owner_id from public.quota_codes c where c.id = code_id)
  );

create policy "projects_own" on public.projects
  for all using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

create policy "tracks_via_project" on public.project_tracks
  for all using (
    exists (select 1 from public.projects p where p.id = project_id and p.owner_id = auth.uid())
  ) with check (
    exists (select 1 from public.projects p where p.id = project_id and p.owner_id = auth.uid())
  );

grant usage on schema public to anon, authenticated;
grant select, insert, update on public.profiles to authenticated;
grant select, insert, update on public.quota_codes to authenticated;
grant select on public.quota_redemptions to authenticated;
grant all on public.projects to authenticated;
grant all on public.project_tracks to authenticated;
grant execute on function public.redeem_quota_code(text) to authenticated;
grant execute on function public.create_quota_code(text) to authenticated;
