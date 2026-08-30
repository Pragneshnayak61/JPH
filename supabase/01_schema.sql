-- =====================================================================
-- JPH Helpdesk — Database Schema (Milestone 1)
--
-- Supabase ke SQL Editor me poori file paste karke "Run" dabaiye.
-- Ye script dobara chalayi ja sakti hai (idempotent).
-- =====================================================================

-- ---------------------------------------------------------------- enums
do $$ begin
  create type ticket_status as enum ('open', 'replied', 'resolved', 'closed');
exception when duplicate_object then null; end $$;

do $$ begin
  create type ticket_priority as enum ('low', 'medium', 'high', 'urgent');
exception when duplicate_object then null; end $$;

do $$ begin
  create type user_kind as enum ('admin', 'agent', 'customer');
exception when duplicate_object then null; end $$;


-- ---------------------------------------------------------------- roles
-- Admin yahan tay karta hai ki kis role ke paas kya permission hai.
-- Ye alag table isliye hai (permissions ko user par seedha likhne ke bajaye)
-- taaki admin naye role bana sake bina code badle.
create table if not exists public.roles (
  id                  uuid primary key default gen_random_uuid(),
  name                text not null unique,
  description         text,
  -- permissions: alag-alag columns, jsonb nahi.
  -- Wajah: RLS policy me inhe seedha padhna padta hai, aur explicit
  -- columns se policy padhne me saaf rehti hai aur index bhi lag sakta hai.
  can_view_all_tickets  boolean not null default false,
  can_assign_tickets    boolean not null default false,
  can_delete_tickets    boolean not null default false,
  can_manage_agents     boolean not null default false,
  can_manage_customers  boolean not null default false,
  can_change_settings   boolean not null default false,
  is_system           boolean not null default false,  -- built-in, delete na ho
  created_at          timestamptz not null default now()
);

insert into public.roles (name, description, can_view_all_tickets, can_assign_tickets,
                          can_delete_tickets, can_manage_agents, can_manage_customers,
                          can_change_settings, is_system)
values
  ('Administrator', 'Can do everything', true, true, true, true, true, true, true),
  ('Agent',         'Can see and reply to every ticket', true, true, false, false, false, false, true),
  ('Junior Agent',  'Can only see tickets assigned to them', false, false, false, false, false, false, true)
on conflict (name) do nothing;


-- ---------------------------------------------------------------- profiles
-- auth.users Supabase ka apna table hai, usme apne columns nahi jod sakte.
-- Isliye har user ka extra data yahan rakhte hain.
create table if not exists public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  email       text not null,
  full_name   text,
  avatar_url  text,
  kind        user_kind not null default 'customer',
  role_id     uuid references public.roles(id) on delete set null,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now()
);

create index if not exists profiles_kind_idx on public.profiles(kind);


-- ---------------------------------------------------------------- organizations
create table if not exists public.organizations (
  id          uuid primary key default gen_random_uuid(),
  name        text not null unique,
  -- NOTE: Frappe Helpdesk me `domain` field bekaar padi thi — kuch karti hi
  -- nahi thi. Yahan ye SACH ME kaam karti hai: guest ticket ka email domain
  -- isse match hota hai aur organization apne aap jud jaata hai
  -- (dekhiye create_guest_ticket function).
  email_domain text unique,
  created_at  timestamptz not null default now()
);


-- ---------------------------------------------------------------- tickets
create table if not exists public.tickets (
  id               bigint primary key generated always as identity,
  -- guest ko login ke bina apna ticket dekhne ke liye. Guess na kiya ja sake
  -- isliye random uuid, sequential id nahi.
  public_token     uuid not null unique default gen_random_uuid(),

  subject          text not null,
  description      text not null,
  status           ticket_status not null default 'open',
  priority         ticket_priority not null default 'medium',

  -- guest ne jo bhara (login ho ya na ho, ye hamesha bharta hai)
  raised_by_email  text not null,
  contact_name     text,
  company_name     text,          -- free text, jo guest ne likha

  -- system ne jo joda
  organization_id  uuid references public.organizations(id) on delete set null,
  created_by       uuid references public.profiles(id) on delete set null,  -- guest ke liye null
  assigned_to      uuid references public.profiles(id) on delete set null,

  first_replied_at timestamptz,
  resolved_at      timestamptz,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

create index if not exists tickets_status_idx      on public.tickets(status);
create index if not exists tickets_assigned_idx    on public.tickets(assigned_to);
create index if not exists tickets_created_at_idx  on public.tickets(created_at desc);
create index if not exists tickets_email_idx       on public.tickets(lower(raised_by_email));


-- ---------------------------------------------------------------- messages
create table if not exists public.ticket_messages (
  id            bigint primary key generated always as identity,
  ticket_id     bigint not null references public.tickets(id) on delete cascade,
  author_id     uuid references public.profiles(id) on delete set null,
  author_email  text,
  author_name   text,
  body          text not null,
  -- true = sirf staff ko dikhega, customer ko kabhi nahi
  is_internal   boolean not null default false,
  created_at    timestamptz not null default now()
);

create index if not exists ticket_messages_ticket_idx on public.ticket_messages(ticket_id, created_at);


-- ---------------------------------------------------------------- helpers
-- SECURITY DEFINER: ye function apne owner ke rights se chalta hai, isliye
-- RLS ise nahi rokti. Iske bina policies apne aap ko hi check karti rahengi
-- aur infinite recursion me chali jayengi.
create or replace function public.current_profile()
returns public.profiles
language sql
stable
security definer
set search_path = public
as $$
  select * from public.profiles where id = auth.uid();
$$;

create or replace function public.is_staff()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid()
      and is_active
      and kind in ('admin', 'agent')
  );
$$;

create or replace function public.has_perm(perm text)
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  result boolean;
begin
  -- admin ko hamesha sab kuch
  if exists (select 1 from public.profiles
             where id = auth.uid() and is_active and kind = 'admin') then
    return true;
  end if;

  execute format(
    'select coalesce(bool_or(r.%I), false)
       from public.profiles p
       join public.roles r on r.id = p.role_id
      where p.id = $1 and p.is_active',
    perm
  ) into result using auth.uid();

  return coalesce(result, false);
end;
$$;


-- ---------------------------------------------------------------- guest ticket
-- Guest ko `tickets` table par SEEDHA access NAHI diya gaya.
-- Sirf ye ek function chala sakta hai. Fayde:
--   1. anon kabhi SELECT nahi kar sakta -> doosron ke ticket nahi padh sakta
--   2. token wapas mil jaata hai (INSERT...RETURNING ke liye SELECT ki
--      permission chahiye hoti, jo hum dena nahi chahte)
--   3. organization apne aap jud jaata hai
create or replace function public.create_guest_ticket(
  p_email        text,
  p_contact_name text,
  p_company_name text,
  p_subject      text,
  p_description  text,
  p_priority     ticket_priority default 'medium'
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_org   uuid;
  v_token uuid;
  v_email text := lower(trim(p_email));
begin
  if v_email = '' or v_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then
    raise exception 'Email sahi nahi hai';
  end if;
  if coalesce(trim(p_subject), '') = '' then
    raise exception 'Subject zaroori hai';
  end if;
  if coalesce(trim(p_description), '') = '' then
    raise exception 'Description zaroori hai';
  end if;

  -- email ke domain se organization dhundho
  select id into v_org
    from public.organizations
   where email_domain = split_part(v_email, '@', 2);

  insert into public.tickets (
    subject, description, priority,
    raised_by_email, contact_name, company_name, organization_id
  ) values (
    trim(p_subject), trim(p_description), coalesce(p_priority, 'medium'),
    v_email, nullif(trim(p_contact_name), ''), nullif(trim(p_company_name), ''), v_org
  )
  returning public_token into v_token;

  return v_token;
end;
$$;

revoke all on function public.create_guest_ticket(text, text, text, text, text, ticket_priority) from public;
grant execute on function public.create_guest_ticket(text, text, text, text, text, ticket_priority) to anon, authenticated;


-- ---------------------------------------------------------------- RLS
alter table public.profiles        enable row level security;
alter table public.roles           enable row level security;
alter table public.organizations   enable row level security;
alter table public.tickets         enable row level security;
alter table public.ticket_messages enable row level security;

-- profiles ------------------------------------------------------------
drop policy if exists profiles_self_read on public.profiles;
create policy profiles_self_read on public.profiles
  for select using (id = auth.uid() or public.is_staff());

drop policy if exists profiles_self_update on public.profiles;
create policy profiles_self_update on public.profiles
  for update using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists profiles_admin_all on public.profiles;
create policy profiles_admin_all on public.profiles
  for all using (public.has_perm('can_manage_agents'))
  with check (public.has_perm('can_manage_agents'));

-- roles ---------------------------------------------------------------
drop policy if exists roles_staff_read on public.roles;
create policy roles_staff_read on public.roles
  for select using (public.is_staff());

drop policy if exists roles_admin_write on public.roles;
create policy roles_admin_write on public.roles
  for all using (public.has_perm('can_manage_agents'))
  with check (public.has_perm('can_manage_agents'));

-- organizations -------------------------------------------------------
drop policy if exists orgs_staff_read on public.organizations;
create policy orgs_staff_read on public.organizations
  for select using (public.is_staff());

drop policy if exists orgs_manage on public.organizations;
create policy orgs_manage on public.organizations
  for all using (public.has_perm('can_manage_customers'))
  with check (public.has_perm('can_manage_customers'));

-- tickets -------------------------------------------------------------
-- YAHAN anon ke liye KOI policy nahi hai. Matlab guest na padh sakta hai,
-- na likh sakta hai. Wo sirf create_guest_ticket() function chala sakta hai.
drop policy if exists tickets_staff_read on public.tickets;
create policy tickets_staff_read on public.tickets
  for select using (
    public.has_perm('can_view_all_tickets')
    or assigned_to = auth.uid()
    or created_by  = auth.uid()
  );

drop policy if exists tickets_staff_update on public.tickets;
create policy tickets_staff_update on public.tickets
  for update using (
    public.has_perm('can_view_all_tickets') or assigned_to = auth.uid()
  );

drop policy if exists tickets_staff_insert on public.tickets;
create policy tickets_staff_insert on public.tickets
  for insert with check (public.is_staff());

drop policy if exists tickets_delete on public.tickets;
create policy tickets_delete on public.tickets
  for delete using (public.has_perm('can_delete_tickets'));

-- ticket_messages -----------------------------------------------------
drop policy if exists messages_staff_read on public.ticket_messages;
create policy messages_staff_read on public.ticket_messages
  for select using (
    exists (select 1 from public.tickets t where t.id = ticket_id)
    and public.is_staff()
  );

drop policy if exists messages_staff_insert on public.ticket_messages;
create policy messages_staff_insert on public.ticket_messages
  for insert with check (public.is_staff());


-- ---------------------------------------------------------------- triggers
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists tickets_touch on public.tickets;
create trigger tickets_touch before update on public.tickets
  for each row execute function public.touch_updated_at();

-- Naya user sign up kare to uska profile apne aap ban jaye.
-- Default 'customer' hai — koi khud se agent nahi ban sakta.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name)
  values (new.id, new.email, new.raw_user_meta_data->>'full_name')
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
