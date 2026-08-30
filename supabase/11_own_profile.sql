-- =====================================================================
-- 1. Ek security hole band karna (ZAROORI)
-- 2. Agent apni profile khud bhar sake
-- 3. Team ki specialization guest portal par publicly dikhe (bina naam)
--
-- Supabase -> SQL Editor me chalaiye. Dobara chalana safe hai.
-- =====================================================================

-- ---------------------------------------------------------------- 1
-- HOLE: `profiles_self_update` policy sirf ye dekhti thi ki row aapki
-- hai ya nahi — KAUN SA COLUMN badal rahe ho, ye nahi dekhti thi.
--
-- Iska matlab koi bhi logged-in banda browser console se seedha
--     update profiles set kind = 'admin' where id = <apni id>
-- chala kar KHUD KO ADMIN bana sakta tha. Customer bhi.
--
-- RLS se column-wise rok nahi lagti (wo row-level hai), isliye trigger.
create or replace function public.guard_profile_columns()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Server-side call (Edge Function service_role se chalta hai, uska
  -- auth.uid() null hota hai). Bina is chhoot ke create-user function
  -- ka legit update bhi block ho jaata tha, aur wo user delete karke
  -- rollback kar deta tha — bahar se lagta "account bana hi nahi".
  --
  -- Surakshit hai: service_role key sirf Edge Function ke andar rehti
  -- hai, browser me kabhi nahi. Browser se aane wale har call me
  -- auth.uid() hota hai, to unpar rok pehle jaisi lagi rehti hai.
  if auth.uid() is null then
    return new;
  end if;

  -- Admin par rok nahi — wo waise bhi sab kuch badal sakta hai.
  if public.is_admin_user() then
    return new;
  end if;

  -- Baaki sabke liye: ye columns wahi rehne chahiye jo the.
  -- Sirf full_name, avatar_url, specialization, mastery badal sakte hain.
  if new.kind        is distinct from old.kind
     or new.role_id     is distinct from old.role_id
     or new.is_active   is distinct from old.is_active
     or new.agent_code  is distinct from old.agent_code
     or new.email       is distinct from old.email then
    raise exception 'You cannot change your own access level or ID';
  end if;

  return new;
end;
$$;

drop trigger if exists profiles_guard on public.profiles;
create trigger profiles_guard
  before update on public.profiles
  for each row execute function public.guard_profile_columns();


-- ---------------------------------------------------------------- 2
-- Mastery: specialization se lambi cheez — kis-kis cheez me mahir hai.
alter table public.profiles
  add column if not exists mastery text;

-- Ye tay karta hai ki apni profile guest portal par dikhe ya nahi.
-- Default false: kisi ki jaankari uski marzi ke bina public nahi honi
-- chahiye, chahe usme naam na bhi ho.
alter table public.profiles
  add column if not exists show_publicly boolean not null default false;


-- ---------------------------------------------------------------- 3
-- Guest portal ke liye. Naam aur email yahan aate hi nahi — sirf ID,
-- specialization aur mastery. Function me hi chhod diya hai, taaki
-- galti se bhi bahar na jaayein.
create or replace function public.public_team()
returns table (code text, specialization text, mastery text)
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(p.agent_code, 'Agent'),
         nullif(trim(p.specialization), ''),
         nullif(trim(p.mastery), '')
    from public.profiles p
   where p.kind in ('admin', 'agent')
     and p.is_active
     and p.show_publicly
     -- Khali card dikhane ka koi matlab nahi.
     and coalesce(nullif(trim(p.specialization), ''),
                  nullif(trim(p.mastery), '')) is not null
   order by p.agent_code;
$$;

revoke all on function public.public_team() from public;
grant execute on function public.public_team() to anon, authenticated;


-- Apni hi profile padhne ke liye (staff ko apna data chahiye edit karne
-- ko). profiles_self_read pehle se ye deti hai, bas yaad dilane ko:
--   using (id = auth.uid() or public.is_admin_user())

select email, agent_code, specialization, mastery, show_publicly
  from public.profiles
 where kind in ('admin', 'agent')
 order by agent_code;
