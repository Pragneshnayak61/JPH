-- =====================================================================
-- Specialization — admin likhta hai ki kaun sa agent kya kaam karta hai.
--
-- Zaroorat kyun: agent ko doosre agents sirf "AG-02" dikhte hain, jisse
-- ye pata hi nahi chalta ki ticket kise assign karna chahiye.
-- "AG-02 · Network" se wo turant samajh jaata hai.
--
-- Supabase -> SQL Editor me chalaiye. Dobara chalana safe hai.
-- =====================================================================

alter table public.profiles
  add column if not exists specialization text;


-- staff_directory ab specialization bhi jodta hai.
--
-- DROP zaroori hai: Postgres `create or replace` se function ka RETURN
-- TYPE nahi badal sakta, aur hum ek naya column jod rahe hain. Bina drop
-- ke ye error aati hai:
--   42P13: cannot change return type of existing function
drop function if exists public.staff_directory();
create or replace function public.staff_directory()
returns table (id uuid, label text, specialization text, is_active boolean)
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
    select p.id,
           case
             when public.is_admin_user()
               then coalesce(nullif(trim(p.full_name), ''), p.email)
             -- agent ko sirf ID. coalesce isliye ki ID kisi wajah se na
             -- bani ho to email leak na ho jaye.
             else coalesce(p.agent_code, 'Agent')
           end as label,
           nullif(trim(p.specialization), '') as specialization,
           p.is_active
      from public.profiles p
     where p.kind in ('admin', 'agent')
       and p.is_active
     order by p.agent_code;
end;
$$;

revoke all on function public.staff_directory() from public;
grant execute on function public.staff_directory() to authenticated;


-- agent_stats me bhi, taaki Analytics me pata rahe kaun kya karta hai.
-- Yahan bhi drop, wahi wajah — naya column jud raha hai.
drop function if exists public.agent_stats();
create or replace function public.agent_stats()
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
    left join public.tickets t_open
      on t_open.assigned_to = p.id and t_open.status in ('open', 'replied')
    left join public.tickets t_resolved
      on t_resolved.resolved_by = p.id
    where p.kind in ('admin', 'agent') and p.is_active
    group by p.id, p.full_name, p.email, p.agent_code, p.specialization
    order by count(distinct t_resolved.id) desc, p.agent_code;
end;
$$;

revoke all on function public.agent_stats() from public;
grant execute on function public.agent_stats() to authenticated;


select email, agent_code, specialization from public.profiles
 where kind in ('admin', 'agent') order by agent_code;
