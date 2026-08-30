-- =====================================================================
-- Agent ki pehchaan chupana.
--
-- Chahiye ye tha: agent ko doosre agents ka naam aur email NAHI dikhna
-- chahiye — sirf "Agent 1", "Agent 2" jaisa code. Sirf administrator
-- asli naam/email dekhe. Aur agent phir bhi ticket assign kar sake,
-- agar admin ne wo permission di ho.
--
-- Supabase -> SQL Editor me chalaiye. Dobara chalana safe hai.
-- =====================================================================

-- ---------------------------------------------------------------- code
alter table public.profiles
  add column if not exists agent_code text unique;

-- Purane agents ko code de do (jo pehle se hain).
-- created_at ke hisaab se — jo pehle juda, wo Agent 1.
with numbered as (
  select id, 'Agent ' || row_number() over (order by created_at) as code
    from public.profiles
   where kind in ('admin', 'agent')
     and agent_code is null
)
update public.profiles p
   set agent_code = n.code
  from numbered n
 where p.id = n.id;


-- Naya agent bane to code apne aap mil jaye.
create or replace function public.assign_agent_code()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_next int;
begin
  if new.kind in ('admin', 'agent') and new.agent_code is null then
    -- Sabse bada number nikaal kar +1. count(*) NAHI use kar rahe —
    -- kisi ko delete karne par count ghat jaata aur code repeat ho jaata,
    -- jabki agent_code unique hai.
    select coalesce(max(nullif(regexp_replace(agent_code, '\D', '', 'g'), '')::int), 0) + 1
      into v_next
      from public.profiles
     where agent_code is not null;

    new.agent_code := 'Agent ' || v_next;
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_agent_code on public.profiles;
create trigger profiles_agent_code
  before insert or update of kind on public.profiles
  for each row execute function public.assign_agent_code();


-- ---------------------------------------------------------------- admin check
create or replace function public.is_admin_user()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
     where id = auth.uid() and is_active and kind = 'admin'
  );
$$;


-- ---------------------------------------------------------------- RLS kasna
-- PEHLE ye tha:
--     using (id = auth.uid() or public.is_staff())
-- Yani KOI BHI agent sabki profile padh sakta tha — email sameth.
-- Ab sirf apni profile, ya admin ko sab.
drop policy if exists profiles_self_read on public.profiles;
create policy profiles_self_read on public.profiles
  for select using (id = auth.uid() or public.is_admin_user());


-- ---------------------------------------------------------------- directory
-- Assign wale dropdown ke liye. Agent ko sirf code milta hai, admin ko
-- asli naam. Ye function isliye chahiye kyunki upar wali policy ab agent
-- ko doosri profiles padhne hi nahi deti.
--
-- SECURITY DEFINER hai, isliye khud check karta hai ki bulane wala staff hai.
create or replace function public.staff_directory()
returns table (id uuid, label text, is_active boolean)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.is_staff() then
    raise exception 'Not allowed';
  end if;

  return query
    select p.id,
           case
             when public.is_admin_user()
               then coalesce(nullif(trim(p.full_name), ''), p.email)
             -- agent ko sirf code. coalesce isliye ki agar kisi wajah se
             -- code na bana ho to email leak na ho jaye.
             else coalesce(p.agent_code, 'Agent')
           end as label,
           p.is_active
      from public.profiles p
     where p.kind in ('admin', 'agent')
       and p.is_active
     order by p.agent_code;
end;
$$;

revoke all on function public.staff_directory() from public;
grant execute on function public.staff_directory() to authenticated;


-- ---------------------------------------------------------------- check
select id, email, full_name, kind, agent_code
  from public.profiles
 order by agent_code nulls last;
