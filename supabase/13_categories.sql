-- =====================================================================
-- Ticket ki category — guest form par subject ke upar dropdown.
--
-- List admin manage karta hai, code me hardcode nahi. Warna har nayi
-- category ke liye code badal kar dobara deploy karna padta.
--
-- Supabase -> SQL Editor me chalaiye. Dobara chalana safe hai.
-- =====================================================================

-- ---------------------------------------------------------------- footer
-- Footer me link ke bajaye contact email. Admin ise Settings se badal
-- sakta hai — code me likhne se har baar deploy karna padta.
alter table public.site_settings
  add column if not exists contact_email text;


create table if not exists public.ticket_categories (
  id         uuid primary key default gen_random_uuid(),
  name       text not null unique,
  -- Kis kram me dikhe. Alphabetical order aksar galat hota — "Other"
  -- hamesha sabse neeche hona chahiye, chahe naam kuch bhi ho.
  sort_order int not null default 0,
  is_active  boolean not null default true,
  created_at timestamptz not null default now()
);

insert into public.ticket_categories (name, sort_order) values
  ('Network', 10),
  ('Hardware', 20),
  ('Software', 30),
  ('Email', 40),
  ('Account access', 50),
  ('Other', 999)
on conflict (name) do nothing;

alter table public.tickets
  -- on delete set null: category hataane par ticket nahi mitna chahiye.
  add column if not exists category_id uuid
  references public.ticket_categories(id) on delete set null;

create index if not exists tickets_category_idx on public.tickets(category_id);


alter table public.ticket_categories enable row level security;

-- Padhna sabke liye — guest form bina login dropdown bharta hai.
drop policy if exists categories_read on public.ticket_categories;
create policy categories_read on public.ticket_categories
  for select using (true);

-- Badalna sirf settings wale ko.
drop policy if exists categories_write on public.ticket_categories;
create policy categories_write on public.ticket_categories
  for all using (public.has_perm('can_change_settings'))
  with check (public.has_perm('can_change_settings'));


-- ---------------------------------------------------------------- guest
-- DROP zaroori — naya parameter jodne se signature badalti hai.
drop function if exists public.create_guest_ticket(text, text, text, text, text, ticket_priority);

create function public.create_guest_ticket(
  p_email        text,
  p_contact_name text,
  p_company_name text,
  p_subject      text,
  p_description  text,
  p_priority     ticket_priority default 'medium',
  p_category_id  uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_org   uuid;
  v_token uuid;
  v_cat   uuid;
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

  -- Category ko verify karte hain, seedha bhar nahi dete. Client koi bhi
  -- uuid bhej sakta hai — band ki hui ya bani hi na hui category ka.
  select id into v_cat
    from public.ticket_categories
   where id = p_category_id and is_active;

  select id into v_org
    from public.organizations
   where email_domain = split_part(v_email, '@', 2);

  insert into public.tickets (
    subject, description, priority,
    raised_by_email, contact_name, company_name, organization_id, category_id
  ) values (
    trim(p_subject), trim(p_description), coalesce(p_priority, 'medium'),
    v_email, nullif(trim(p_contact_name), ''), nullif(trim(p_company_name), ''),
    v_org, v_cat
  )
  returning public_token into v_token;

  return v_token;
end;
$$;

revoke all on function public.create_guest_ticket(text, text, text, text, text, ticket_priority, uuid) from public;
grant execute on function public.create_guest_ticket(text, text, text, text, text, ticket_priority, uuid) to anon, authenticated;


-- Guest ko apne ticket par category bhi dikhe.
create or replace function public.get_guest_ticket(p_token uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_ticket public.tickets;
  v_msgs   jsonb;
  v_cat    text;
begin
  select * into v_ticket from public.tickets where public_token = p_token;
  if not found then
    return null;
  end if;

  select name into v_cat from public.ticket_categories
   where id = v_ticket.category_id;

  select coalesce(jsonb_agg(m order by m.created_at), '[]'::jsonb)
    into v_msgs
    from (
      select body, author_name, created_at
        from public.ticket_messages
       where ticket_id = v_ticket.id
         and is_internal = false
    ) m;

  return jsonb_build_object(
    'id',           v_ticket.id,
    'subject',      v_ticket.subject,
    'description',  v_ticket.description,
    'status',       v_ticket.status,
    'priority',     v_ticket.priority,
    'category',     v_cat,
    'contact_name', v_ticket.contact_name,
    'company_name', v_ticket.company_name,
    'created_at',   v_ticket.created_at,
    'messages',     v_msgs
  );
end;
$$;

revoke all on function public.get_guest_ticket(uuid) from public;
grant execute on function public.get_guest_ticket(uuid) to anon, authenticated;


select name, sort_order from public.ticket_categories order by sort_order;
