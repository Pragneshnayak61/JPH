-- =====================================================================
-- Ticket se wapas us jaanch tak, jisse wo bani thi
--
-- Supabase -> SQL Editor me chalaiye. Dobara chalana safe hai.
-- 27 se 29 tak PEHLE chal chuki honi chahiye.
-- =====================================================================
--
-- KYA ADHOORA THA
--
-- Checklist se ticket banana ban chuka tha, aur checklist par ticket ka
-- number bhi dikhta tha. Par ULTI taraf kuch nahi tha: ticket kholne par
-- pata hi nahi chalta ki wo kahan se aayi.
--
-- Ticket ki description me sab likha hota hai, par wo sirf likhi hui
-- baat hai — usse ye nahi pata chalta ki ye jaanch pichhle hafte bhi
-- fail hui thi ya nahi. Uske liye jodne wala tar chahiye, jo
-- ops_task_executions.ticket_id me pehle se pada hai; bas use padhne ka
-- koi raasta nahi tha.
--
-- SEEDHI TABLE SE KYUN NAHI PADH SAKTE
--
-- ops_task_executions par RLS lagi hai: bina operations permission ke wo
-- table dikhti hi nahi (27_ops_schema.sql). Ye theek hai — usme hostname
-- aur IP tak pahunch jaati hai.
--
-- Par ticket par kaam karne wala aam agent ko itna to pata hona chahiye
-- ki ye ticket kis client ki kaunsi jaanch se aayi. Isliye ye definer
-- function, jo sirf UTNA deta hai:
--
--   client ka naam, device ka NAAM, jaanch, tareekh, nateeja, remarks
--
-- Aur ye NAHI deta: hostname, IP, location, notes. Jo baat sirf
-- operations walon ki hai wo wahin rehti hai.


create or replace function public.ops_ticket_source(p_ticket_id bigint)
returns table (
  execution_id    bigint,
  client_task_id  uuid,
  client_name     text,
  device_name     text,
  category_name   text,
  task_name       text,
  due_date        date,
  status          ops_status,
  remarks         text,
  performed_label text,
  performed_at    timestamptz
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

  -- Wahi shart jo tickets_staff_read policy me hai.
  --
  -- Definer function RLS ko bypass kar deta hai, isliye wo rok yahan
  -- HAATH SE dobara lagani padti hai. Bina iske jis ticket ko ye agent
  -- dekh hi nahi sakta, uske baare me bhi jaankari nikal jaati.
  -- Yahi tareeqa ticket_messages_list() me bhi hai.
  if not exists (
    select 1 from public.tickets t
     where t.id = p_ticket_id
       and (public.has_perm('can_view_all_tickets')
            or t.assigned_to = auth.uid()
            or t.created_by  = auth.uid())
  ) then
    raise exception 'Not allowed';
  end if;

  return query
    select e.id,
           e.client_task_id,
           o.name,
           d.name,
           c.name,
           e.task_name,
           e.due_date,
           e.status,
           e.remarks,
           public.ops_person_label(e.performed_by),
           e.performed_at
      from public.ops_task_executions e
      join public.organizations o on o.id = e.organization_id
      left join public.ops_devices    d on d.id = e.device_id
      left join public.ops_categories c on c.id = e.category_id
     where e.ticket_id = p_ticket_id
     limit 1;
end;
$$;

revoke all on function public.ops_ticket_source(bigint) from public;
grant execute on function public.ops_ticket_source(bigint) to authenticated;


-- ---------------------------------------------------------------- check

-- Ye khali aaye to matlab abhi kisi jaanch se ticket bani hi nahi —
-- galti nahi hai:
select t.id as ticket, o.name as client, e.task_name, e.due_date, e.status
  from public.ops_task_executions e
  join public.tickets t       on t.id = e.ticket_id
  join public.organizations o on o.id = e.organization_id
 order by t.id desc
 limit 10;
