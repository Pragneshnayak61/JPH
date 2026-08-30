-- =====================================================================
-- Due date:
--   - public portal se aaya ticket -> priority ke hisaab se apne aap
--   - admin/agent khud banaye -> jo tareekh wo daale
--
-- Supabase -> SQL Editor me chalaiye. Dobara chalana safe hai.
-- =====================================================================

-- Kitne din, kis priority par. Table isliye (code me hardcode nahi) ki
-- aap ise badal sakein bina naya deploy kiye.
create table if not exists public.priority_sla (
  priority ticket_priority primary key,
  days     int not null check (days > 0)
);

insert into public.priority_sla (priority, days) values
  ('urgent', 1),
  ('high',   3),
  ('medium', 7),
  ('low',    14)
on conflict (priority) do nothing;

alter table public.priority_sla enable row level security;

drop policy if exists priority_sla_read on public.priority_sla;
create policy priority_sla_read on public.priority_sla
  for select using (true);

drop policy if exists priority_sla_write on public.priority_sla;
create policy priority_sla_write on public.priority_sla
  for all using (public.has_perm('can_change_settings'))
  with check (public.has_perm('can_change_settings'));


-- ---------------------------------------------------------------- guest
-- Guest ke ticket par due date function KHUD lagata hai.
-- Client se nahi lete — wo koi bhi tareekh bhej sakta hai, aur customer
-- ko apni deadline khud tay karne dena galat hai.
drop function if exists public.create_guest_ticket(text, text, text, text, text, ticket_priority, uuid);

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
  v_org      uuid;
  v_token    uuid;
  v_cat      uuid;
  v_priority ticket_priority := coalesce(p_priority, 'medium');
  v_days     int;
  v_email    text := lower(trim(p_email));
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

  select id into v_cat
    from public.ticket_categories
   where id = p_category_id and is_active;

  select id into v_org
    from public.organizations
   where email_domain = split_part(v_email, '@', 2);

  -- Table me priority na mile to 7 din. Bina coalesce ke due_date null
  -- reh jaata aur ticket bina deadline ke ghoomta rehta.
  select days into v_days from public.priority_sla where priority = v_priority;
  v_days := coalesce(v_days, 7);

  insert into public.tickets (
    subject, description, priority,
    raised_by_email, contact_name, company_name,
    organization_id, category_id, due_date
  ) values (
    trim(p_subject), trim(p_description), v_priority,
    v_email, nullif(trim(p_contact_name), ''), nullif(trim(p_company_name), ''),
    v_org, v_cat, (current_date + v_days)
  )
  returning public_token into v_token;

  return v_token;
end;
$$;

revoke all on function public.create_guest_ticket(text, text, text, text, text, ticket_priority, uuid) from public;
grant execute on function public.create_guest_ticket(text, text, text, text, text, ticket_priority, uuid) to anon, authenticated;


-- ---------------------------------------------------------------- staff
-- Agent/admin seedha insert karte hain (guest wala function nahi).
-- Wo due date khud daal sakte hain — par khali chhod dein to trigger
-- wahi hisaab laga deta hai. Aise ticket bina deadline ke nahi bachta.
create or replace function public.set_default_due_date()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_days int;
begin
  if new.due_date is null then
    select days into v_days from public.priority_sla
     where priority = new.priority;
    new.due_date := current_date + coalesce(v_days, 7);
  end if;
  return new;
end;
$$;

drop trigger if exists tickets_default_due on public.tickets;
create trigger tickets_default_due
  before insert on public.tickets
  for each row execute function public.set_default_due_date();


select * from public.priority_sla order by days;
