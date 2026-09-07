-- =====================================================================
-- Operations — generation sach me chal rahi hai ya nahi
--
-- Supabase -> SQL Editor me chalaiye. Dobara chalana safe hai.
-- 27 se 30 tak PEHLE chal chuki honi chahiye.
-- =====================================================================
--
-- MASLA JO DIKHTA NAHI
--
-- 30_ops_generation.sql ne do parat lagayi thi: raat ko cron, aur page
-- khulte hi app. Dono chup-chaap kaam karti hain — aur yahi khatra hai.
--
-- Cron kisi raat na chale to koi alarm nahi bajta. Agli subah checklist
-- me sirf utni jaanchein dikhti hain jitni app ne banayi, aur wo bhi
-- tabhi jab kisi ne page khola ho. Jis din kisi ne na khola, us din ka
-- record HAMESHA ke liye nahi banta — aur mahine ke aakhir me report
-- kehti hai "us din kuch tha hi nahi", jo jhooth hai.
--
-- Ticket ka record galat ho to koi bol deta hai. Yahan koi nahi bolega,
-- kyunki na bani hui row kisi ko dikhti hi nahi.
--
-- ISLIYE YE SCRIPT DO CHEEZEIN KARTI HAI
--
--   1. ops_generation_health() — cron zinda hai ya nahi, aur pichhle N
--      din me kis din ki rows KAM hain (jitni banni chahiye thi usse).
--   2. ops_generate_due() par ek halki rok, jo cron ko nahi rokti.
--
-- "Kam hain" ka matlab: har din ke liye ginte hain ki active checklist ke
-- hisaab se us din kitni jaanchein banni chahiye thi, aur asal me kitni
-- rows hain. Kam ho to us tareekh par nishan laga dete hain.
--
-- Zyada hone par kuch nahi kehte — wo galti nahi hai. Koi task band
-- (is_active = false) kar diya jaye to aage se wo nahi banti, par uski
-- purani rows apni jagah rehti hain. Wahi to history ka matlab hai.


-- ---------------------------------------------------------------- 1/3
-- ops_generate_due par rok — par cron ko chhoot ke saath
--
-- 30 me ye function har logged-in user ko diya gaya tha, is soch ke saath
-- ki "sabse bura nateeja 0 rows hai". Baat theek hai, par is app me
-- customer bhi login karte hain, aur unka is function se koi wasta nahi.
--
-- YAHAN EK PURANI GALTI DOBARA HO SAKTI THI
--
-- Seedha `if not ops_can_read() then raise` likh dete to CRON ROZ FAIL
-- HOTA. Cron `postgres` ban kar chalta hai, jahan auth.uid() NULL hai,
-- isliye ops_can_read() false lautata — aur raat ko chup-chaap error.
-- 29_ops_functions.sql me theek yahi cheez SQL Editor me hui thi.
--
-- Isliye shart do hisso me hai: rok sirf tab lagti hai jab koi ASLI user
-- baitha ho (auth.uid() null nahi hai). Cron aur SQL Editor bina JWT ke
-- chalte hain, unhe chhoot mil jaati hai.

create or replace function public.ops_generate_due(
  p_upto date default current_date,
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
  -- auth.uid() null = cron ya SQL Editor. Unhe rokna nahi hai.
  if auth.uid() is not null and not public.ops_can_read() then
    raise exception 'Not allowed';
  end if;

  insert into public.ops_task_executions (
    client_task_id, organization_id, device_id, category_id,
    task_name, due_date
  )
  select t.id,
         t.organization_id,
         t.device_id,
         t.category_id,
         t.name,
         d::date
    from public.ops_client_tasks t
    cross join generate_series(
           (p_upto - greatest(0, coalesce(p_back, 7)))::timestamp,
           p_upto::timestamp,
           interval '1 day') as d
   where t.is_active
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
grant execute on function public.ops_generate_due(date, int) to authenticated;


-- ---------------------------------------------------------------- 2/3
-- Health

create or replace function public.ops_generation_health(p_days int default 14)
returns table (
  pg_cron_on      boolean,
  job_active      boolean,
  job_schedule    text,
  last_run_at     timestamptz,
  last_run_status text,
  days_checked    int,
  days_missing    int,
  missing_dates   date[],
  active_tasks    int
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_days   int := least(greatest(coalesce(p_days, 14), 1), 90);
  v_cron   boolean;
  v_active boolean;
  v_sched  text;
  v_run_at timestamptz;
  v_run_st text;
begin
  if not public.ops_can_read() then
    raise exception 'Not allowed';
  end if;

  v_cron := exists (select 1 from pg_extension where extname = 'pg_cron');

  -- `cron` schema hai hi nahi jab extension band ho. Isliye ye query
  -- EXECUTE ke andar hai — string ban kar tabhi padhi jaati hai jab
  -- chalti hai. Seedha likh dete to pehli hi baar bulane par poori
  -- cheez gir jaati.
  --
  -- exception block isliye ki kal ko pg_cron ka version badle ya
  -- permission alag ho, to health screen adhoora dikhe — poora fail na
  -- ho. Cron ki khabar na milne se din ki ginti rukni nahi chahiye.
  if v_cron then
    begin
      execute $q$
        select j.active, j.schedule
          from cron.job j
         where j.jobname = 'ops-generate-daily'
         limit 1
      $q$ into v_active, v_sched;

      execute $q$
        select r.end_time, r.status
          from cron.job_run_details r
          join cron.job j on j.jobid = r.jobid
         where j.jobname = 'ops-generate-daily'
         order by r.start_time desc
         limit 1
      $q$ into v_run_at, v_run_st;
    exception when others then
      null;
    end;
  end if;

  return query
  with days as (
    select d::date as due_date
      from generate_series((current_date - (v_days - 1))::timestamp,
                           current_date::timestamp,
                           interval '1 day') as d
  ),
  expected as (
    select days.due_date, count(*)::int as n
      from days
      join public.ops_client_tasks t
        on t.is_active
       and days.due_date >= t.created_at::date
       and case t.frequency
             when 'daily' then
               true
             when 'weekly' then
               extract(dow from days.due_date)::int = t.run_weekday
             when 'monthly' then
               extract(day from days.due_date)::int = t.run_day
             when 'quarterly' then
               extract(day from days.due_date)::int = t.run_day
               and extract(month from days.due_date)::int in (1, 4, 7, 10)
           end
     group by days.due_date
  ),
  actual as (
    select e.due_date, count(*)::int as n
      from public.ops_task_executions e
     where e.due_date >= current_date - (v_days - 1)
       and e.due_date <= current_date
     group by e.due_date
  ),
  gaps as (
    select x.due_date
      from expected x
      left join actual a on a.due_date = x.due_date
     where coalesce(a.n, 0) < x.n
  )
  select v_cron,
         v_active,
         v_sched,
         v_run_at,
         v_run_st,
         v_days,
         (select count(*)::int from gaps),
         (select coalesce(array_agg(g.due_date order by g.due_date),
                          '{}'::date[])
            from gaps g),
         (select count(*)::int from public.ops_client_tasks where is_active);
end;
$$;

revoke all on function public.ops_generation_health(int) from public;
grant execute on function public.ops_generation_health(int) to authenticated;


-- ---------------------------------------------------------------- 3/3
-- Ek baar abhi bhar dete hain
--
-- Agar kal cron nahi chala tha to ye wahi khali din bhar dega. Purani
-- rows ko haath nahi lagta — UNIQUE (client_task_id, due_date) unhe
-- chhoo bhi nahi sakta.

select public.ops_generate_due(current_date, 14) as ab_kitni_nayi_rows_bani;


-- ---------------------------------------------------------------- check

-- ops_generation_health() ko yahan JAAN-BOOJH KAR nahi bula rahe. Wo
-- ops_can_read() maangta hai, aur SQL Editor `postgres` ban kar chalta
-- hai jahan auth.uid() NULL hai — ek raise poori script wapas kar deta.
-- Bilkul wahi galti 29 me hui thi.
--
-- Health app me dikhega: Operations setup page par sabse upar.

-- Cron zinda hai ya nahi. Ye pg_cron ON hone par hi chalega, isliye alag
-- se, apne aap chalaiye (comment hata kar):
--
--   select j.jobname, j.schedule, j.active,
--          r.start_time, r.status, r.return_message
--     from cron.job j
--     left join cron.job_run_details r on r.jobid = j.jobid
--    where j.jobname = 'ops-generate-daily'
--    order by r.start_time desc
--    limit 5;

-- Kis din kitni rows bani — beech me koi din TOOTA to yahan dikh jayega:
select due_date, count(*) as kitni
  from public.ops_task_executions
 where due_date >= current_date - 14
 group by due_date
 order by due_date desc;
