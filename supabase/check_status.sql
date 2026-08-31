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
order by script;


-- Email kahin peechhe to nahi reh gaya (sab true hone chahiye):
select p.email as profile_email,
       u.email as login_email,
       (p.email = u.email) as mile_hue
  from public.profiles p
  join auth.users u on u.id = p.id
 order by u.created_at;
