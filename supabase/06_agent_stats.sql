-- =====================================================================
-- Agent-wise stats — kisne kitne ticket resolve kiye.
--
-- Supabase -> SQL Editor me chalaiye. Dobara chalana safe hai.
-- =====================================================================

-- ---------------------------------------------------------------- resolved_by
-- Abhi tak ye pata hi nahi chalta tha ki ticket KISNE resolve kiya.
-- `assigned_to` se kaam chala sakte the, par wo galat hota: ticket kisi
-- aur ko assign hokar kisi aur se resolve ho sakta hai, aur assign baad
-- me badal bhi sakta hai — to purana record bhi badal jaata.
alter table public.tickets
  add column if not exists resolved_by uuid references public.profiles(id) on delete set null;

-- Trigger, client par bharosa nahi. Client se bharwate to koi bhi apne
-- naam se doosre ka resolve chadha sakta tha, aur email/API se aane wale
-- update me ye field chhoot jaati.
create or replace function public.set_resolved_by()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- resolved/closed me PEHLI baar jaate waqt hi likho.
  if new.status in ('resolved', 'closed')
     and (old.status is distinct from new.status)
     and new.resolved_by is null then
    new.resolved_by := auth.uid();
    new.resolved_at := coalesce(new.resolved_at, now());
  end if;

  -- Ticket dobara khul gaya to purana record hata do, warna wo agent
  -- ko count hota rahega jabki kaam abhi baaki hai.
  if new.status not in ('resolved', 'closed')
     and old.status in ('resolved', 'closed') then
    new.resolved_by := null;
    new.resolved_at := null;
  end if;

  return new;
end;
$$;

drop trigger if exists tickets_resolved_by on public.tickets;
create trigger tickets_resolved_by
  before update of status on public.tickets
  for each row execute function public.set_resolved_by();

-- Purane resolved tickets ka credit assigned_to ko de do — behtar kuch
-- pata hai hi nahi. Aage se trigger sahi record rakhega.
update public.tickets
   set resolved_by = assigned_to
 where status in ('resolved', 'closed')
   and resolved_by is null
   and assigned_to is not null;


-- ---------------------------------------------------------------- stats
create or replace function public.agent_stats()
returns table (
  agent_id   uuid,
  label      text,
  assigned   bigint,
  open_count bigint,
  resolved   bigint
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.is_staff() then
    raise exception 'Not allowed';
  end if;

  return query
    select
      p.id,
      -- Admin ko asli naam, agent ko sirf code. Wahi niyam jo baaki
      -- jagah lagaya hai — stats se pehchaan leak nahi honi chahiye.
      case
        when public.is_admin_user()
          then coalesce(nullif(trim(p.full_name), ''), p.email)
        else coalesce(p.agent_code, 'Agent')
      end,
      count(distinct t_assigned.id),
      count(distinct t_open.id),
      count(distinct t_resolved.id)
    from public.profiles p
    left join public.tickets t_assigned
      on t_assigned.assigned_to = p.id
    left join public.tickets t_open
      on t_open.assigned_to = p.id and t_open.status in ('open', 'replied')
    left join public.tickets t_resolved
      on t_resolved.resolved_by = p.id
    where p.kind in ('admin', 'agent') and p.is_active
    group by p.id, p.full_name, p.email, p.agent_code
    order by count(distinct t_resolved.id) desc, p.agent_code;
end;
$$;

revoke all on function public.agent_stats() from public;
grant execute on function public.agent_stats() to authenticated;


-- ---------------------------------------------------------------- totals
create or replace function public.ticket_totals()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  r jsonb;
begin
  if not public.is_staff() then
    raise exception 'Not allowed';
  end if;

  select jsonb_build_object(
    'total',      count(*),
    'open',       count(*) filter (where status = 'open'),
    'replied',    count(*) filter (where status = 'replied'),
    'resolved',   count(*) filter (where status = 'resolved'),
    'closed',     count(*) filter (where status = 'closed'),
    'unassigned', count(*) filter (where assigned_to is null
                                     and status in ('open', 'replied')),
    'last_7_days', count(*) filter (where created_at > now() - interval '7 days')
  ) into r
  from public.tickets;

  return r;
end;
$$;

revoke all on function public.ticket_totals() from public;
grant execute on function public.ticket_totals() to authenticated;
