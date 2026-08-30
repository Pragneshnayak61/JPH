-- =====================================================================
-- Analytics me date filter — "last 7 days", "last 30 days", "all time".
--
-- Filter server par lagta hai, client par nahi. Client par lagate to
-- poora data browser me bhejna padta (aage chalkar hazaron rows), aur
-- ginti bhi client karta — dheema aur galat dono.
--
-- Supabase -> SQL Editor me chalaiye. Dobara chalana safe hai.
-- =====================================================================

-- DROP zaroori hai — parameter jodne se function ki signature badalti
-- hai, aur `create or replace` usse badal nahi sakta.
-- (Purana bina-parameter wala version bhi hata rahe hain.)
drop function if exists public.agent_stats();
drop function if exists public.agent_stats(int);

create function public.agent_stats(p_days int default null)
returns table (
  agent_id       uuid,
  label          text,
  specialization text,
  assigned       bigint,
  open_count     bigint,
  resolved       bigint
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  -- null = "all time". Aisi date rakhte hain jo har ticket se purani ho,
  -- taaki neeche ek hi query se dono soorat sambhal jayein.
  v_from timestamptz := case
    when p_days is null then '-infinity'::timestamptz
    else now() - make_interval(days => p_days)
  end;
begin
  if not public.is_staff() then
    raise exception 'Not allowed';
  end if;

  return query
    select
      p.id,
      case
        when public.is_admin_user()
          then coalesce(nullif(trim(p.full_name), ''), p.email)
        else coalesce(p.agent_code, 'Agent')
      end,
      nullif(trim(p.specialization), ''),
      count(distinct t_assigned.id),
      count(distinct t_open.id),
      count(distinct t_resolved.id)
    from public.profiles p
    left join public.tickets t_assigned
      on t_assigned.assigned_to = p.id
     and t_assigned.created_at >= v_from
    left join public.tickets t_open
      on t_open.assigned_to = p.id
     and t_open.status in ('open', 'replied')
     and t_open.created_at >= v_from
    left join public.tickets t_resolved
      on t_resolved.resolved_by = p.id
     -- resolved ki ginti resolve hone ki tareekh se, banne ki nahi.
     -- Warna purana ticket aaj resolve karne par kisi ke naam nahi chadhta.
     and coalesce(t_resolved.resolved_at, t_resolved.created_at) >= v_from
    where p.kind in ('admin', 'agent') and p.is_active
    group by p.id, p.full_name, p.email, p.agent_code, p.specialization
    order by count(distinct t_resolved.id) desc, p.agent_code;
end;
$$;

revoke all on function public.agent_stats(int) from public;
grant execute on function public.agent_stats(int) to authenticated;


drop function if exists public.ticket_totals();
drop function if exists public.ticket_totals(int);

create function public.ticket_totals(p_days int default null)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  r jsonb;
  v_from timestamptz := case
    when p_days is null then '-infinity'::timestamptz
    else now() - make_interval(days => p_days)
  end;
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
                                     and status in ('open', 'replied'))
  ) into r
  from public.tickets
  where created_at >= v_from;

  return r;
end;
$$;

revoke all on function public.ticket_totals(int) from public;
grant execute on function public.ticket_totals(int) to authenticated;
