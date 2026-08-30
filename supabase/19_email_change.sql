-- =====================================================================
-- User apna login email khud badal sake.
--
-- Supabase -> SQL Editor me chalaiye. Dobara chalana safe hai.
-- =====================================================================
--
-- Email do jagah rehta hai:
--   auth.users.email   <- LOGIN isi se hota hai (Supabase ka apna table)
--   profiles.email     <- app me dikhane ke liye hamari copy
--
-- Supabase pehle wala khud sambhalta hai (confirmation link ke baad).
-- Par doosre wala apne aap nahi badalta — aur tab dono alag ho jaate
-- hain: login naye email se hota hai, par app puraana dikhata rehta hai.
--
-- Isliye ye trigger.

create or replace function public.sync_profile_email()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Sirf tab jab email SACH ME badla ho. auth.users har login par
  -- update hoti hai (last_sign_in_at waghera), aur bina is check ke
  -- ye trigger har baar bekaar me chalta.
  if new.email is distinct from old.email then
    update public.profiles
       set email = new.email
     where id = new.id;
  end if;
  return new;
end;
$$;

drop trigger if exists on_auth_email_changed on auth.users;
create trigger on_auth_email_changed
  after update of email on auth.users
  for each row execute function public.sync_profile_email();


-- Ek baar abhi bhi mila lete hain — agar pehle se koi farq pada ho.
update public.profiles p
   set email = u.email
  from auth.users u
 where u.id = p.id
   and p.email is distinct from u.email;


select p.email as profile_email, u.email as login_email,
       (p.email = u.email) as mile_hue
  from public.profiles p
  join auth.users u on u.id = p.id
 order by p.email;
