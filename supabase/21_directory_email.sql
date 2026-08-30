-- =====================================================================
-- staff_directory me email bhi — par SIRF admin ke liye.
--
-- Supabase -> SQL Editor me chalaiye. Dobara chalana safe hai.
-- =====================================================================
--
-- Zaroorat: dashboard ke "From" column me, jab ticket kisi agent ne
-- banaya ho, to admin ko uska EMAIL dikhna chahiye aur baaki sabko
-- sirf ID.
--
-- Email column me null jaata hai jab dekhne wala admin na ho. Ye rok
-- FUNCTION KE ANDAR hai, client par nahi — client par chhupate to
-- email network par to chala hi jaata, aur browser me dekha ja sakta.

-- DROP zaroori — naya column jud raha hai, aur `create or replace`
-- return type nahi badal sakta.
drop function if exists public.staff_directory();

create function public.staff_directory()
returns table (
  id             uuid,
  label          text,
  email          text,
  specialization text,
  is_active      boolean
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_is_admin boolean := public.is_admin_user();
begin
  if not public.is_staff() then
    raise exception 'Not allowed';
  end if;

  return query
    select p.id,
           case
             when v_is_admin
               then coalesce(nullif(trim(p.full_name), ''), p.email)
             -- agent ko sirf ID. coalesce isliye ki ID kisi wajah se na
             -- bani ho to email leak na ho jaye.
             else coalesce(p.agent_code, 'Agent')
           end as label,
           -- Non-admin ko email bhejte hi nahi.
           case when v_is_admin then p.email else null end as email,
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


select * from public.staff_directory();
