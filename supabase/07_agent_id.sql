-- =====================================================================
-- "Agent 1" ki jagah asli ID — aur admin use khud badal sake.
--
-- Supabase -> SQL Editor me chalaiye. Dobara chalana safe hai.
-- =====================================================================

-- Purane "Agent 1" wale codes ko "AG-01" bana do.
-- Sirf wahi badal rahe hain jo humne banaye the — agar admin ne pehle
-- se koi apni ID daal di hai, use haath nahi lagana.
update public.profiles
   set agent_code = 'AG-' || lpad(regexp_replace(agent_code, '\D', '', 'g'), 2, '0')
 where agent_code ~ '^Agent [0-9]+$';


-- Naya agent bane to ID apne aap mile.
create or replace function public.assign_agent_code()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_next int;
begin
  if new.kind in ('admin', 'agent')
     and coalesce(trim(new.agent_code), '') = '' then

    -- Sabse bade number me +1. count(*) NAHI — kisi ko delete karne par
    -- count ghat jaata aur ID repeat ho jaati, jabki wo unique hai.
    --
    -- '\D' se sirf ank nikalte hain, isliye admin ki apni ID (jaise
    -- "JPH-104") bhi is ginti me sahi tarah aa jaati hai.
    select coalesce(max(nullif(regexp_replace(agent_code, '\D', '', 'g'), '')::int), 0) + 1
      into v_next
      from public.profiles
     where agent_code is not null;

    new.agent_code := 'AG-' || lpad(v_next::text, 2, '0');
  end if;

  -- Khali string ko null bana do. Warna unique index do khali strings
  -- ko takra hua maanta hai, par do null ko nahi — aur admin ke field
  -- khali chhodne par ajeeb error aata.
  if coalesce(trim(new.agent_code), '') = '' then
    new.agent_code := null;
  end if;

  return new;
end;
$$;

-- Trigger ab agent_code par bhi chalta hai (pehle sirf kind par tha),
-- taaki admin field khali karke save kare to nayi ID apne aap mil jaye.
drop trigger if exists profiles_agent_code on public.profiles;
create trigger profiles_agent_code
  before insert or update of kind, agent_code on public.profiles
  for each row execute function public.assign_agent_code();


select email, kind, agent_code from public.profiles
 where kind in ('admin', 'agent')
 order by agent_code;
