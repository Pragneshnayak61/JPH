-- =====================================================================
-- Public site ki branding — company ka naam, logo, color, aur guest
-- form par likha text. Sab admin settings se badal sakega.
--
-- Supabase -> SQL Editor me chalaiye. Dobara chalana safe hai.
-- =====================================================================

create table if not exists public.site_settings (
  -- Ek hi row honi chahiye. `id` ko 1 par lock kar diya hai — check
  -- constraint galti se doosri row banne hi nahi dega.
  id                 int primary key default 1 check (id = 1),

  company_name       text not null default 'JPH Helpdesk',
  logo_url           text,
  accent_color       text not null default '#1b2422',

  -- guest form ka text
  guest_heading      text not null default 'JPH Support',
  guest_intro        text not null default 'Tell us what went wrong — no account needed',
  guest_submit_label text not null default 'Submit ticket',

  -- thank-you page
  thanks_title       text not null default 'Ticket submitted',
  thanks_message     text not null default 'Our team will reply to your email.',

  updated_at         timestamptz not null default now(),
  updated_by         uuid references public.profiles(id) on delete set null
);

insert into public.site_settings (id) values (1)
on conflict (id) do nothing;

alter table public.site_settings enable row level security;

-- Padhna SABKE liye khula hai — guest form bina login ke branding
-- dikhata hai, isliye anon ko bhi mila.
-- Yahan kuch chhupane layak hai bhi nahi: company ka naam aur logo to
-- waise bhi page par dikhte hain.
drop policy if exists site_settings_read on public.site_settings;
create policy site_settings_read on public.site_settings
  for select using (true);

-- Badalna sirf jise permission mili ho.
drop policy if exists site_settings_write on public.site_settings;
create policy site_settings_write on public.site_settings
  for update using (public.has_perm('can_change_settings'))
  with check (public.has_perm('can_change_settings'));

create or replace function public.touch_site_settings()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  new.updated_by := auth.uid();
  return new;
end;
$$;

drop trigger if exists site_settings_touch on public.site_settings;
create trigger site_settings_touch before update on public.site_settings
  for each row execute function public.touch_site_settings();


-- ---------------------------------------------------------------- storage
-- Logo ke liye bucket. public = true, kyunki logo guest form par bina
-- login ke dikhna hai.
insert into storage.buckets (id, name, public)
values ('branding', 'branding', true)
on conflict (id) do nothing;

-- Padhna sabke liye.
drop policy if exists "branding public read" on storage.objects;
create policy "branding public read" on storage.objects
  for select using (bucket_id = 'branding');

-- Upload/badalna/hataana sirf settings badalne wale ko.
-- Teeno alag policies isliye ki Postgres me ek policy ek hi command
-- ke liye hoti hai — "for all" likhte to anon ko bhi lag jaati.
drop policy if exists "branding upload" on storage.objects;
create policy "branding upload" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'branding' and public.has_perm('can_change_settings'));

drop policy if exists "branding update" on storage.objects;
create policy "branding update" on storage.objects
  for update to authenticated
  using (bucket_id = 'branding' and public.has_perm('can_change_settings'));

drop policy if exists "branding delete" on storage.objects;
create policy "branding delete" on storage.objects
  for delete to authenticated
  using (bucket_id = 'branding' and public.has_perm('can_change_settings'));


select * from public.site_settings;
