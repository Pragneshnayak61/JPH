-- =====================================================================
-- Operations — recurring tasks apne aap banna
--
-- Supabase -> SQL Editor me chalaiye. Dobara chalana safe hai.
-- 27, 28, 29 PEHLE chal chuki honi chahiye.
-- =====================================================================
--
-- DO PARAT, JAAN-BOOJH KAR
--
--   1. pg_cron  — har raat 00:05 UTC par apne aap
--   2. app      — Operations page khulte hi ek baar (safety net)
--
-- Ek hi kaafi lagta hai, par nahi hai. Cron kisi raat na chale (extension
-- band ho jaye, Supabase ka maintenance ho) to agli subah checklist khali
-- milegi aur us din ka record hamesha ke liye gayab. Aur sirf app par
-- rakhein to jis din koi na khole us din kuch bane hi na.
--
-- Dono chalane ka kharcha ZERO hai, kyunki
-- ops_task_executions par UNIQUE (client_task_id, due_date) laga hai —
-- doosri baar generate karne par database chup-chaap `do nothing` kar
-- deta hai. Duplicate ban hi nahi sakte.
--
-- Yahi tareeqa is project me pehle se hai: 23_email_and_password.sql me
-- email sync ke liye trigger + app-side RPC + ek baar ka reconcile,
-- teeno hain, aur wajah wahin likhi hai — "ek parat fail ho to baaki do
-- bacha leti hain."


-- ---------------------------------------------------------------- 1/3
-- Generator

create or replace function public.ops_generate_due(
  p_upto date default current_date,
  -- Kitne din peechhe tak bharna hai. Cron do din band raha ho to wo din
  -- bhi bhar jaayein. 7 se zyada ka koi matlab nahi — utna purana kaam
  -- "aaj ki checklist" nahi rehta.
  p_back int default 7
)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count int;
begin
  insert into public.ops_task_executions (
    client_task_id, organization_id, device_id, category_id,
    task_name, due_date
  )
  select t.id,
         t.organization_id,
         t.device_id,
         t.category_id,
         -- Naam ab likh liya jaata hai. Baad me task ka naam badla to
         -- purani rows apna purana naam rakhengi — report tabhi sach
         -- bolti hai.
         t.name,
         d::date
    from public.ops_client_tasks t
    cross join generate_series(
           (p_upto - greatest(0, coalesce(p_back, 7)))::timestamp,
           p_upto::timestamp,
           interval '1 day') as d
   where t.is_active
     -- Task banne se PEHLE ke din nahi bharne. Warna aaj ek nayi jaanch
     -- jodte hi pichhle haftey ki saat "pending" rows ban jaatin, jo
     -- kabhi hui hi nahi thi — aur report jhooth bolti.
     and d::date >= t.created_at::date
     and case t.frequency
           when 'daily' then
             true
           when 'weekly' then
             extract(dow from d)::int = t.run_weekday
           when 'monthly' then
             extract(day from d)::int = t.run_day
           when 'quarterly' then
             extract(day from d)::int = t.run_day
             and extract(month from d)::int in (1, 4, 7, 10)
         end
  on conflict (client_task_id, due_date) do nothing;

  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

revoke all on function public.ops_generate_due(date, int) from public;
-- App bhi bulati hai (page khulte hi), isliye authenticated ko chahiye.
-- Ye sirf rows BANATA hai, padhta ya badalta kuch nahi — koi bhi staff
-- ise chala de to sabse bura nateeja "0 rows" hai.
grant execute on function public.ops_generate_due(date, int) to authenticated;


-- ---------------------------------------------------------------- 2/3
-- Cron
--
-- pg_cron Supabase me ek extension hai. Agar wo on nahi hai to ye hissa
-- chup-chaap chhod diya jaata hai aur baaki script phir bhi chalti hai —
-- app wali parat akele bhi kaam karti rehti hai.
--
-- On karne ke liye: Dashboard -> Database -> Extensions -> "pg_cron"
-- dhoondh kar enable kijiye, phir ye script dobara chala dijiye.
--
-- WAQT UTC ME HAI. 00:05 UTC = IST me subah 5:35. Ye theek hai: aap jab
-- subah kaam shuru karenge, us din ki checklist pehle se bani hogi.

do $$
begin
  if not exists (select 1 from pg_extension where extname = 'pg_cron') then
    raise notice '--------------------------------------------------------';
    raise notice 'pg_cron abhi enable nahi hai — cron wala hissa chhoda ja';
    raise notice 'raha hai. App khulte hi tasks phir bhi ban jaayenge.';
    raise notice 'Chaahein to: Dashboard -> Database -> Extensions ->';
    raise notice 'pg_cron enable kijiye, phir ye script dobara chalaiye.';
    raise notice '--------------------------------------------------------';
    return;
  end if;

  -- Purana job hata kar naya lagate hain, taaki ye script dobara chalane
  -- par do job na ban jaayein.
  perform cron.unschedule(jobid)
     from cron.job
    where jobname = 'ops-generate-daily';

  perform cron.schedule(
    'ops-generate-daily',
    '5 0 * * *',
    'select public.ops_generate_due();'
  );

  raise notice 'pg_cron laga diya: roz 00:05 UTC par ops_generate_due()';
end $$;


-- ---------------------------------------------------------------- 3/3
-- Abhi ke liye ek baar chala dete hain
--
-- Taaki script chalate hi checklist khali na mile. Abhi koi client task
-- bana hi nahi hai, isliye pehli baar ye 0 lautayega — Setup page se
-- checklist banane ke baad ye apne aap bharne lagega.

select public.ops_generate_due() as abhi_kitni_rows_bani;


-- ---------------------------------------------------------------- check

-- Cron laga ya nahi (khali aaye to matlab pg_cron off hai):
select jobname, schedule, active
  from cron.job
 where jobname = 'ops-generate-daily';

-- Kis din kitni jaanchein bani hain:
select due_date, count(*) as kitni
  from public.ops_task_executions
 group by due_date
 order by due_date desc
 limit 14;

-- DUPLICATE ka test — ye do baar chalaiye. Doosri baar 0 aana chahiye.
-- 0 se zyada aaye to unique index kaam nahi kar raha:
--   select public.ops_generate_due();
