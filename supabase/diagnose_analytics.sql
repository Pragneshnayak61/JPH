-- =====================================================================
-- Analytics kyun update nahi ho raha — jaanch.
-- Supabase -> SQL Editor me chalaiye aur poora output bhej dijiye.
-- Ye kuch badalti nahi, sirf padhti hai.
-- =====================================================================

-- 1. Kitne tickets hain aur kis haalat me
select 'TICKETS' as jaanch,
       count(*)                                        as kul,
       count(*) filter (where status = 'open')         as open,
       count(*) filter (where status = 'resolved')     as resolved,
       count(*) filter (where status = 'closed')       as closed,
       count(assigned_to)                              as assigned,
       count(resolved_by)                              as resolved_by_bhara,
       min(id) as pehla_id, max(id) as aakhri_id
  from public.tickets;

-- 2. Kaun si company ke kitne
select company_name, count(*) as kul,
       count(*) filter (where status = 'resolved') as resolved,
       count(assigned_to) as assigned
  from public.tickets group by company_name order by company_name;

-- 3. Jo resolved hain, unka resolved_by aur resolved_at bhara hai ya nahi?
--    Analytics ki ginti IN DONO par chalti hai, status par nahi.
select id, subject, status, resolved_by, resolved_at, created_at
  from public.tickets
 where status in ('resolved', 'closed')
 order by id limit 10;

-- 4. Trigger lage hue hain ya nahi
select tgname as trigger_ka_naam
  from pg_trigger
 where tgrelid = 'public.tickets'::regclass
   and not tgisinternal
 order by tgname;

-- 5. agent_stats ke kitne version hain? (Do hone par galat wala chal
--    sakta hai. Sirf EK hona chahiye.)
select p.proname, pg_get_function_identity_arguments(p.oid) as parameters
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'public'
   and p.proname in ('agent_stats', 'ticket_totals', 'staff_directory')
 order by p.proname;

-- 6. Analytics jo dikhata hai, wahi yahan se — 30 din wala filter
select * from public.agent_stats(30);
select public.ticket_totals(30) as totals_30_din;
select public.ticket_totals(null) as totals_all_time;
