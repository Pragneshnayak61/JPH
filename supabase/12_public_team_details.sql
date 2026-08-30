-- =====================================================================
-- Team card me aur details — kitne ticket solve kiye, aur tajurba.
--
-- Supabase -> SQL Editor me chalaiye. Dobara chalana safe hai.
-- =====================================================================

alter table public.profiles
  add column if not exists experience_years int
  -- 0 se 60 ke bahar ki value galti hi hogi. Bina rok ke koi 2024
  -- (saal) daal deta aur card par "2024 years" chhap jaata.
  check (experience_years is null
         or (experience_years >= 0 and experience_years <= 60));


-- Footer ke liye — company ka naam settings se aata hai, par saal
-- ke saath copyright line bhi chahiye.
alter table public.site_settings
  add column if not exists legal_name text;


-- DROP zaroori — return type badal raha hai (naye columns jud rahe hain),
-- aur `create or replace` return type nahi badal sakta.
drop function if exists public.public_team();

create function public.public_team()
returns table (
  code             text,
  specialization   text,
  mastery          text,
  experience_years int,
  resolved_count   bigint
)
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(p.agent_code, 'Agent'),
         nullif(trim(p.specialization), ''),
         nullif(trim(p.mastery), ''),
         p.experience_years,
         -- Ye ginti khud badhti rehti hai, koi haath se update nahi
         -- karta — isliye ye kabhi purani nahi padti.
         (select count(*) from public.tickets t where t.resolved_by = p.id)
    from public.profiles p
   where p.kind in ('admin', 'agent')
     and p.is_active
     and p.show_publicly
     and coalesce(nullif(trim(p.specialization), ''),
                  nullif(trim(p.mastery), '')) is not null
   order by p.agent_code;
$$;

revoke all on function public.public_team() from public;
grant execute on function public.public_team() to anon, authenticated;


select agent_code, specialization, experience_years, show_publicly
  from public.profiles
 where kind in ('admin', 'agent')
 order by agent_code;
