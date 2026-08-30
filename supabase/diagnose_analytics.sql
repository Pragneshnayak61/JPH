-- =====================================================================
-- Analytics kyun update nahi ho raha — jaanch.
--
-- Supabase -> SQL Editor me chalaiye aur poora output bhej dijiye.
-- Ye kuch badalti nahi, sirf padhti hai.
--
-- NOTE: yahan agent_stats() ko SEEDHA call nahi kar rahe. Wo function
-- is_staff() check karta hai, aur SQL Editor me koi logged-in user
-- hota hi nahi (auth.uid() null) — to wo "Not allowed" de deta hai.
-- Isliye wahi ginti neeche haath se likhi hai.
-- =====================================================================

-- 1. Kitne tickets hain aur kis haalat me
select 'TICKETS' as jaanch,
       count(*)                                     as kul,
       count(*) filter (where status = 'open')      as open,
       count(*) filter (where status = 'replied')   as replied,
       count(*) filter (where status = 'resolved')  as resolved,
       count(*) filter (where status = 'closed')    as closed,
       count(assigned_to)                           as assigned,
       count(resolved_by)                           as resolved_by_bhara,
       min(id) as pehla_id, max(id) as aakhri_id
  from public.tickets;


-- 2. Company ke hisaab se
select company_name,
       count(*) as kul,
       count(*) filter (where status in ('resolved','closed')) as nipta_diye,
       count(assigned_to) as assigned
  from public.tickets
 group by company_name
 order by company_name;


-- 3. SABSE ZAROORI
-- Jo resolved/closed hain, unme resolved_by bhara hai ya nahi?
-- Analytics ki ginti RESOLVED_BY par chalti hai, status par nahi.
-- Yahan resolved_by null dikhe, to chart khali rehne ki wajah wahi hai.
select id, status, resolved_by, resolved_at, assigned_to,
       left(subject, 40) as subject
  from public.tickets
 where status in ('resolved', 'closed')
 order by id
 limit 15;


-- 4. Trigger lage hain ya nahi
select tgname as trigger_ka_naam
  from pg_trigger
 where tgrelid = 'public.tickets'::regclass
   and not tgisinternal
 order by tgname;


-- 5. Function ke DO version to nahi ban gaye?
-- Har naam ke saamne SIRF EK line honi chahiye.
select p.proname as function_ka_naam,
       pg_get_function_identity_arguments(p.oid) as parameters
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'public'
   and p.proname in ('agent_stats', 'ticket_totals', 'staff_directory',
                     'public_team', 'create_guest_ticket')
 order by p.proname, parameters;


-- 6. Agent-wise ginti — wahi hisaab jo Analytics lagata hai,
--    par bina is_staff() rok ke.
select coalesce(p.agent_code, '(no id)') as agent,
       p.specialization,
       count(distinct ta.id) as assigned,
       count(distinct tr.id) as resolved
  from public.profiles p
  left join public.tickets ta on ta.assigned_to = p.id
  left join public.tickets tr on tr.resolved_by  = p.id
 where p.kind in ('admin', 'agent') and p.is_active
 group by p.id, p.agent_code, p.specialization
 order by p.agent_code;


-- 7. Wahi ginti, par 30 din ke filter ke saath — Analytics me default
--    yahi range chuni hoti hai. Agar #6 me numbers hain par yahan 0,
--    to matlab data 30 din se purana hai aur filter use chhupa raha hai.
select coalesce(p.agent_code, '(no id)') as agent,
       count(distinct tr.id) as resolved_30_din
  from public.profiles p
  left join public.tickets tr
    on tr.resolved_by = p.id
   and coalesce(tr.resolved_at, tr.created_at) >= now() - interval '30 days'
 where p.kind in ('admin', 'agent') and p.is_active
 group by p.id, p.agent_code
 order by p.agent_code;
