-- =====================================================================
-- Kaunsi script chal chuki hai aur kaunsi baaki hai.
--
-- Supabase -> SQL Editor me chalaiye. Ye sirf PADHTI hai, kuch badalti
-- nahi. Jitni baar chahe chalaiye.
-- =====================================================================
--
-- Yaad rakhne ki zaroorat nahi honi chahiye — database khud bata sakta
-- hai ki usme kya bana hua hai. Har row ek script hai aur uske saamne
-- uski haalat.
--
-- KRAM JAAN-BOOJH KAR AISA HAI
--
-- Supabase ka SQL Editor kai queries chalane par SIRF AAKHRI ka result
-- dikhata hai. Isliye script ki list — jo asli maqsad hai — sabse neeche
-- rakhi hai. Poori file paste kar ke Run dabaiye, wahi list dikhegi.


-- ---------------------------------------------------------------- 1/2
-- Email kahin peechhe to nahi reh gaya

select p.email as profile_email,
       u.email as login_email,
       (p.email = u.email) as mile_hue
  from public.profiles p
  join auth.users u on u.id = p.id
 order by u.created_at;


-- ---------------------------------------------------------------- 2/2
-- Kaunsi script chal chuki hai (YAHI wo list hai jo result me aayegi)

select '13 — ticket categories' as script,
       case when to_regclass('public.ticket_categories') is null
            then 'BAAKI HAI' else 'ho gaya' end as haalat
union all
select '19 — email sync trigger',
       case when exists (
              select 1 from pg_trigger
               where tgrelid = 'auth.users'::regclass
                 and tgname = 'on_auth_email_changed'
                 and not tgisinternal)
            then 'ho gaya' else 'BAAKI HAI' end
union all
select '20 — tickets par created_by',
       -- "Baaki hai" tabhi jab aisi ticket bachi ho jispar creator lagna
       -- chahiye tha par laga nahi.
       case when exists (
              select 1
                from public.tickets t
                join public.profiles p
                  on lower(p.email) = lower(t.raised_by_email)
               where t.created_by is null
                 and p.kind in ('admin', 'agent'))
            then 'BAAKI HAI' else 'ho gaya' end
union all
select '21 — staff_directory me email',
       -- Function to pehle se tha; 21 usme email ka column jodta hai.
       -- Isliye naam se nahi, uske nateeje ki shakl se pehchante hain.
       case when exists (
              select 1
                from pg_proc f
                join pg_namespace n on n.oid = f.pronamespace
               where n.nspname = 'public'
                 and f.proname = 'staff_directory'
                 and pg_get_function_result(f.oid) like '%email%')
            then 'ho gaya' else 'BAAKI HAI' end
union all
select '22 — deleted_accounts record',
       case when to_regclass('public.deleted_accounts') is null
            then 'BAAKI HAI' else 'ho gaya' end
union all
select '23 — email fix + sync_my_email',
       case when exists (
              select 1
                from pg_proc f
                join pg_namespace n on n.oid = f.pronamespace
               where n.nspname = 'public'
                 and f.proname in ('sync_my_email', 'apply_email_change')
               having count(*) = 2)
            then 'ho gaya' else 'BAAKI HAI' end
union all
select '24 — pehchaan sabse chhupi',
       case when exists (
              select 1
                from pg_proc f
                join pg_namespace n on n.oid = f.pronamespace
               where n.nspname = 'public'
                 and f.proname = 'identity_visible')
            then 'ho gaya' else 'BAAKI HAI' end
union all
select '25 — account_exists (forgot password)',
       case when exists (
              select 1 from pg_proc f
                join pg_namespace n on n.oid = f.pronamespace
               where n.nspname = 'public' and f.proname = 'account_exists')
            then 'ho gaya' else 'BAAKI HAI' end
union all
select '26 — customer email optional',
       case when exists (
              select 1 from information_schema.columns
               where table_schema = 'public'
                 and table_name   = 'tickets'
                 and column_name  = 'raised_by_email'
                 and is_nullable  = 'YES')
            then 'ho gaya' else 'BAAKI HAI' end
union all
select '27 — operations ka dhaancha',
       case when to_regclass('public.ops_task_executions') is null
            then 'BAAKI HAI' else 'ho gaya' end
union all
select '28 — operations task library',
       -- Ginti pg_stat se le rahe hain, `count(*) from ops_task_catalog`
       -- se nahi. Wajah: agar 27 abhi chali hi na ho to wo table hoti hi
       -- nahi, aur Postgres query ko PADHTE waqt hi error de deta —
       -- poori status script fail ho jaati. pg_stat hamesha maujood hai.
       case when coalesce((select n_live_tup from pg_stat_user_tables
                            where schemaname = 'public'
                              and relname = 'ops_task_catalog'), 0) > 0
            then 'ho gaya' else 'BAAKI HAI' end
union all
select '29 — operations ke RPC',
       case when exists (
              select 1 from pg_proc f
                join pg_namespace n on n.oid = f.pronamespace
               where n.nspname = 'public' and f.proname = 'ops_today')
            then 'ho gaya' else 'BAAKI HAI' end
union all
select '30 — recurring tasks banna',
       case when exists (
              select 1 from pg_proc f
                join pg_namespace n on n.oid = f.pronamespace
               where n.nspname = 'public' and f.proname = 'ops_generate_due')
            then 'ho gaya' else 'BAAKI HAI' end
union all
select '30b — pg_cron (marzi ki cheez)',
       case when exists (select 1 from pg_extension where extname = 'pg_cron')
            then 'ho gaya' else 'off hai — app phir bhi chalti hai' end
union all
select '31 — evidence bucket',
       case when exists (
              select 1 from storage.buckets where id = 'ops-evidence')
            then 'ho gaya' else 'BAAKI HAI' end
order by script;
