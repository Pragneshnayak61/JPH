-- =====================================================================
-- Server Administration / IT Operations — dhaancha (tables + RLS)
--
-- Supabase -> SQL Editor me chalaiye. Dobara chalana safe hai.
-- =====================================================================
--
-- KYA BAN RAHA HAI
--
-- Helpdesk ke saath-saath ek doosra kaam: 3-5 clients ke server, network,
-- backup, CCTV waghera ki rozana/haftawari/mahine ki jaanch. Har jaanch
-- ka nateeja hamesha ke liye sambhal kar rakhna hai, aur fail hone par
-- usi se ticket ban sake.
--
-- MAUJOODA HELPDESK PAR ASAR
--
-- Sirf EK purani table badli hai: roles me do naye column jude hain.
-- Dono ka default false hai, isliye aaj kisi ko bhi apne aap access nahi
-- milta. tickets, ticket_messages, profiles, organizations — kisi ko
-- haath nahi lagaya. Agar aap Operations ka page kabhi na kholein, to
-- helpdesk bilkul waise hi chalta rahega jaise abhi chal raha hai.
--
-- CLIENT KE LIYE NAYI TABLE NAHI BANAYI
--
-- organizations pehle se maujood hai (name + email_domain), tickets usse
-- jude hue hain, aur guest ticket apne aap us se link ho jaati hai. Uske
-- barabar ek "clients" table banana matlab ek hi cheez ke do naam — aur
-- phir ek din dono alag ho jaate. Isliye client = organization.
--
-- Ab tak organizations ka koi UI nahi tha; wo Operations ke setup page se
-- aayega.
--
-- NAAM ke aage `ops_` isliye lagaya hai taaki helpdesk ki tables aur is
-- module ki tables ek nazar me alag dikhein.


-- ---------------------------------------------------------------- 1/7
-- Enums
--
-- priority ke liye naya enum JAAN-BOOJH KAR nahi banaya. ticket_priority
-- pehle se hai, aur checklist se ticket banti hai — do alag paimane
-- rakhne par har baar ek se doosre me badalna padta, aur ek din wo
-- mapping galat ho jaati.

do $$ begin
  create type ops_frequency as enum ('daily', 'weekly', 'monthly', 'quarterly');
exception when duplicate_object then null; end $$;

-- 'attention' = jaanch hui, fail nahi hui, par koi dekhne layak baat hai
-- (jaise disk 85% par). 'skipped' = aaj ki jaanch jaan-boojh kar chhodi
-- (server band tha, maintenance chal raha tha). Dono ko 'failed' me
-- milaana galat hota — report me farq nahi rehta.
do $$ begin
  create type ops_status as enum
    ('pending', 'in_progress', 'completed', 'failed', 'skipped', 'attention');
exception when duplicate_object then null; end $$;

do $$ begin
  create type ops_device_kind as enum
    ('server', 'network', 'firewall', 'backup', 'cctv',
     'storage', 'application', 'other');
exception when duplicate_object then null; end $$;


-- ---------------------------------------------------------------- 2/7
-- Permissions
--
-- Wahi tareeqa jo pehle se chal raha hai: roles me alag-alag boolean
-- column, jsonb nahi. Wajah 01_schema.sql me likhi hai — RLS policy me
-- inhe seedha padhna padta hai.
--
-- Do alag permission isliye ki "jaanch karne wala" aur "checklist banane
-- wala" alag log hote hain. Server Administrator ko rozana ki jaanch
-- karni hai, par usse ye tay karne ka haq nahi ki kaunsi jaanch honi
-- chahiye.

alter table public.roles
  add column if not exists can_manage_operations boolean not null default false,
  add column if not exists can_run_operations    boolean not null default false;

-- Built-in Administrator role ko dono. (kind='admin' wale user ko waise
-- bhi has_perm() sab kuch deta hai; ye sirf role ki list saaf rakhne ke
-- liye hai.)
update public.roles
   set can_manage_operations = true,
       can_run_operations    = true
 where name = 'Administrator';

-- Ek naya role, taaki server admin ko poora Administrator banane ki
-- zaroorat na pade. Ye jaanch kar sakta hai, ticket bana sakta hai, par
-- na checklist badal sakta hai na logon ko chhoo sakta hai.
insert into public.roles
  (name, description,
   can_view_all_tickets, can_assign_tickets, can_delete_tickets,
   can_manage_agents, can_manage_customers, can_change_settings,
   can_manage_operations, can_run_operations, is_system)
values
  ('Server Administrator',
   'Runs the daily operations checklist and raises tickets from it',
   true, false, false, false, false, false, false, true, true)
on conflict (name) do nothing;


-- ---------------------------------------------------------------- 3/7
-- Categories aur task library
--
-- ticket_categories jaisa hi dhaancha — naam, kram, active. Alphabetical
-- order aksar galat hota hai, isliye sort_order.

create table if not exists public.ops_categories (
  id         uuid primary key default gen_random_uuid(),
  name       text not null unique,
  sort_order int not null default 0,
  is_active  boolean not null default true,
  created_at timestamptz not null default now()
);

-- Dobara istemal hone wali jaanchon ki list.
--
-- Ye zaroori kyun hai: aapne ~35 aam jaanchein ginwayi hain. Inhe ek
-- baar likh lene ka matlab hai ki chautha client jodte waqt aap list me
-- se chunte hain, 35 rows dobara nahi likhte.
--
-- Ye khud kisi client ki nahi hai. Client ki asli checklist agli table
-- me hai.
create table if not exists public.ops_task_catalog (
  id          uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.ops_categories(id) on delete restrict,
  name        text not null,
  description text,
  -- "Ye jaanch kaise karni hai" — client ki checklist me copy ho jaata
  -- hai aur wahan badla ja sakta hai.
  default_instructions text,
  sort_order  int not null default 0,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now(),
  unique (category_id, name)
);


-- ---------------------------------------------------------------- 4/7
-- Client ka infrastructure
--
-- "Har client ka setup ek jaisa mat maano" — isliye device client ke
-- neeche latka hai, aur kisi client ke paas ek bhi device na ho to bhi
-- chalta hai.

create table if not exists public.ops_devices (
  id              uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  name            text not null,          -- "DC01", "FortiGate 100F"
  kind            ops_device_kind not null default 'server',
  hostname        text,
  -- inet ke bajaye text: kisi device ke do IP hote hain, kisi ka koi
  -- nahi, aur kabhi "10.0.0.5 (LAN) / 41.x (WAN)" jaisa likhna padta
  -- hai. inet ye sab reject kar deta.
  ip_address      text,
  location        text,
  notes           text,
  is_active       boolean not null default true,
  created_at      timestamptz not null default now(),
  created_by      uuid references public.profiles(id) on delete set null,
  unique (organization_id, name)
);

create index if not exists ops_devices_org_idx
  on public.ops_devices(organization_id) where is_active;


-- ---------------------------------------------------------------- 5/7
-- Client ki apni checklist — is module ka dil
--
-- Yahi wo table hai jiski wajah se Client A ki list Client B se alag ho
-- sakti hai. catalog se copy ho kar aati hai, phir yahan azadi se badli
-- ja sakti hai.
--
-- name yahan RAKHA hai, catalog se join karke nahi laate. Wajah: ek
-- client ke liye jaanch ka naam badalna doosre client par asar nahi
-- karna chahiye. catalog_id sirf ye batane ke liye hai ki ye kahan se
-- aayi thi.
--
-- catalog_id NULL bhi ho sakta hai — kisi client ki apni khaas jaanch
-- jiska library me hona zaroori nahi.

create table if not exists public.ops_client_tasks (
  id              uuid primary key default gen_random_uuid(),
  -- restrict: jis client ki checklist bani hui hai use delete nahi kar
  -- sakte. Purana record mit jaana sabse bura nateeja hai. Client band
  -- ho gaya ho to uski tasks ko is_active = false kar dijiye.
  organization_id uuid not null references public.organizations(id) on delete restrict,
  catalog_id      uuid references public.ops_task_catalog(id) on delete set null,
  device_id       uuid references public.ops_devices(id) on delete set null,
  category_id     uuid not null references public.ops_categories(id) on delete restrict,

  name            text not null,
  description     text,
  instructions    text,

  frequency       ops_frequency not null default 'daily',
  -- weekly ke liye: 0 = Sunday ... 6 = Saturday (Postgres ka extract(dow)).
  run_weekday     smallint not null default 1,
  -- monthly/quarterly ke liye mahine ka din. 28 se aage nahi ja sakta —
  -- warna February me wo din aata hi nahi aur us mahine ki jaanch chup-chaap
  -- gayab ho jaati.
  run_day         smallint not null default 1,

  priority        ticket_priority not null default 'medium',
  assigned_to     uuid references public.profiles(id) on delete set null,

  -- Fail hone par apne aap ticket? Default false, aur aise hi rehne
  -- dijiye jab tak haath se banane ka tajurba na ho jaye. Ek flapping
  -- check har roz ticket banaye to shor me asli masla dab jaata hai.
  auto_ticket_on_fail boolean not null default false,

  is_active       boolean not null default true,
  created_at      timestamptz not null default now(),
  created_by      uuid references public.profiles(id) on delete set null,

  constraint ops_client_tasks_weekday_ck check (run_weekday between 0 and 6),
  constraint ops_client_tasks_day_ck     check (run_day between 1 and 28)
);

create index if not exists ops_client_tasks_org_idx
  on public.ops_client_tasks(organization_id) where is_active;
create index if not exists ops_client_tasks_due_idx
  on public.ops_client_tasks(frequency) where is_active;


-- ---------------------------------------------------------------- 6/7
-- Har jaanch ka nateeja — history
--
-- Ek task, ek din = ek row. Wo row kabhi overwrite nahi hoti; agle din
-- ki jaanch nayi row banati hai. Isi se "Client -> Server -> Task ->
-- History" wala nazariya bina kisi extra kaam ke mil jaata hai.
--
-- UNIQUE (client_task_id, due_date) IS TABLE KI SABSE ZAROORI LINE HAI.
-- Recurring tasks banane wala code din me kai baar chal sakta hai (cron
-- se bhi, page kholne par bhi). Duplicate rokne ka kaam application ke
-- bharose chhodne par ek din race condition me do rows ban hi jaati
-- hain. Yahan database khud mana kar deta hai, isliye generator ko
-- `on conflict do nothing` likh kar jitni baar chahe chalaya ja sakta
-- hai.
--
-- organization_id, device_id, category_id yahan DOBARA rakhe hain jabki
-- wo client_task se mil sakte the. Wajah reporting hai: 6 mahine purani
-- report banate waqt har row par teen join lagana mehnga hai, aur agar
-- tab tak task kisi doosre device par shift ho gaya to purani report
-- jhooth bolne lagti.
--
-- task_name bhi isi wajah se snapshot hai. Yahi tareeqa deleted_accounts
-- me pehle se istemal hua hai (deleted_by_label) — jis cheez ka naam
-- baad me badal ya mit sakta hai, use us waqt likh lo.

create table if not exists public.ops_task_executions (
  id              bigint primary key generated always as identity,
  -- restrict: task delete karke uski history nahi udayi ja sakti.
  client_task_id  uuid not null references public.ops_client_tasks(id) on delete restrict,
  organization_id uuid not null references public.organizations(id) on delete restrict,
  device_id       uuid references public.ops_devices(id) on delete set null,
  category_id     uuid references public.ops_categories(id) on delete set null,
  task_name       text not null,

  -- Ye jaanch KIS DIN ki hai. Kab ki gayi wo performed_at me hai — do
  -- alag cheezein: raat 11 baje kal ki pending jaanch nipta sakte hain.
  due_date        date not null,

  status          ops_status not null default 'pending',
  remarks         text,
  performed_by    uuid references public.profiles(id) on delete set null,
  performed_at    timestamptz,

  -- Is jaanch se koi ticket bani ho to wahi. Ticket alag se mit sakti
  -- hai, is history ko usse nahi jaana chahiye — isliye set null.
  ticket_id       bigint references public.tickets(id) on delete set null,

  created_at      timestamptz not null default now(),

  unique (client_task_id, due_date)
);

create index if not exists ops_exec_date_idx
  on public.ops_task_executions(due_date desc, status);
create index if not exists ops_exec_org_date_idx
  on public.ops_task_executions(organization_id, due_date desc);
create index if not exists ops_exec_task_history_idx
  on public.ops_task_executions(client_task_id, due_date desc);
create index if not exists ops_exec_ticket_idx
  on public.ops_task_executions(ticket_id) where ticket_id is not null;

-- Saboot: screenshot, backup report, log file.
--
-- file_path alag se rakha hai (sirf URL nahi) kyunki bucket private hai.
-- Private bucket se dikhane ke liye har baar signed URL banana padta
-- hai, aur uske liye path chahiye — URL se path nikaalna bharosemand
-- nahi.
create table if not exists public.ops_execution_files (
  id           uuid primary key default gen_random_uuid(),
  execution_id bigint not null references public.ops_task_executions(id) on delete cascade,
  file_path    text not null,
  file_name    text not null,
  file_size    int,
  mime_type    text,
  uploaded_by  uuid references public.profiles(id) on delete set null,
  created_at   timestamptz not null default now()
);

create index if not exists ops_exec_files_idx
  on public.ops_execution_files(execution_id);


-- ---------------------------------------------------------------- 7/7
-- RLS
--
-- Do chhote helper pehle, taaki har policy me ek hi shart likhi jaye.
-- Alag-alag jagah alag shart likhne par ek din koi ek policy chhoot
-- jaati hai — 24_hide_identity.sql me yahi seekh likhi hai.

create or replace function public.ops_can_read()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.has_perm('can_run_operations')
      or public.has_perm('can_manage_operations');
$$;

create or replace function public.ops_can_manage()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.has_perm('can_manage_operations');
$$;

grant execute on function public.ops_can_read()   to authenticated;
grant execute on function public.ops_can_manage() to authenticated;

alter table public.ops_categories       enable row level security;
alter table public.ops_task_catalog     enable row level security;
alter table public.ops_devices          enable row level security;
alter table public.ops_client_tasks     enable row level security;
alter table public.ops_task_executions  enable row level security;
alter table public.ops_execution_files  enable row level security;

-- Yahan anon ke liye ek bhi policy NAHI hai. Bina login ke is module ka
-- kuch bhi nahi dikhta — na client ke naam, na hostname, na IP.
--
-- Aur jo agent sirf helpdesk ka kaam karta hai (dono operations
-- permission ke bina), use bhi kuch nahi dikhta. Infrastructure ki
-- jaankari har staff ke liye nahi hai.

-- categories / catalog -------------------------------------------------
drop policy if exists ops_categories_read on public.ops_categories;
create policy ops_categories_read on public.ops_categories
  for select using (public.ops_can_read());

drop policy if exists ops_categories_write on public.ops_categories;
create policy ops_categories_write on public.ops_categories
  for all using (public.ops_can_manage()) with check (public.ops_can_manage());

drop policy if exists ops_catalog_read on public.ops_task_catalog;
create policy ops_catalog_read on public.ops_task_catalog
  for select using (public.ops_can_read());

drop policy if exists ops_catalog_write on public.ops_task_catalog;
create policy ops_catalog_write on public.ops_task_catalog
  for all using (public.ops_can_manage()) with check (public.ops_can_manage());

-- devices --------------------------------------------------------------
drop policy if exists ops_devices_read on public.ops_devices;
create policy ops_devices_read on public.ops_devices
  for select using (public.ops_can_read());

drop policy if exists ops_devices_write on public.ops_devices;
create policy ops_devices_write on public.ops_devices
  for all using (public.ops_can_manage()) with check (public.ops_can_manage());

-- client tasks ---------------------------------------------------------
drop policy if exists ops_client_tasks_read on public.ops_client_tasks;
create policy ops_client_tasks_read on public.ops_client_tasks
  for select using (public.ops_can_read());

drop policy if exists ops_client_tasks_write on public.ops_client_tasks;
create policy ops_client_tasks_write on public.ops_client_tasks
  for all using (public.ops_can_manage()) with check (public.ops_can_manage());

-- executions -----------------------------------------------------------
-- INSERT ki koi policy nahi: rows sirf generator banata hai (wo definer
-- function hai, RLS usse nahi rokti). Haath se row daalne ka koi jayaz
-- kaaran nahi — usse duplicate aur galat date wali rows aati hain.
--
-- UPDATE khula hai par asli kaam ops_complete() se hota hai, jo
-- performed_by khud auth.uid() se bharta hai. Client se aaya hua
-- performed_by kabhi bharosa nahi kiya ja sakta.
drop policy if exists ops_exec_read on public.ops_task_executions;
create policy ops_exec_read on public.ops_task_executions
  for select using (public.ops_can_read());

drop policy if exists ops_exec_update on public.ops_task_executions;
create policy ops_exec_update on public.ops_task_executions
  for update using (public.ops_can_read()) with check (public.ops_can_read());

drop policy if exists ops_exec_delete on public.ops_task_executions;
create policy ops_exec_delete on public.ops_task_executions
  for delete using (public.ops_can_manage());

-- files ----------------------------------------------------------------
drop policy if exists ops_files_read on public.ops_execution_files;
create policy ops_files_read on public.ops_execution_files
  for select using (public.ops_can_read());

drop policy if exists ops_files_insert on public.ops_execution_files;
create policy ops_files_insert on public.ops_execution_files
  for insert with check (public.ops_can_read());

drop policy if exists ops_files_delete on public.ops_execution_files;
create policy ops_files_delete on public.ops_execution_files
  for delete using (public.ops_can_read());


-- ---------------------------------------------------------------- check

-- Saari tables ban gayin (6 rows aani chahiye):
select table_name
  from information_schema.tables
 where table_schema = 'public' and table_name like 'ops\_%'
 order by table_name;

-- Nayi permissions lag gayin:
select name, can_manage_operations, can_run_operations
  from public.roles order by name;

-- RLS har table par chalu hai (sab true):
select relname, relrowsecurity
  from pg_class
 where relnamespace = 'public'::regnamespace
   and relname like 'ops\_%'
 order by relname;
