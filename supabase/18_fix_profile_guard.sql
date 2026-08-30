-- =====================================================================
-- Fix: "Add person" par account ban kar turant rollback ho jaata tha.
--
-- Supabase -> SQL Editor me chalaiye. Dobara chalana safe hai.
-- =====================================================================
--
-- KYA HO RAHA THA
--
-- 11_own_profile.sql me maine ek trigger lagaya tha jo non-admin ko
-- apna kind/role/ID badalne se rokta hai. Wo rok zaroori thi — uske
-- bina koi bhi khud ko admin bana leta.
--
-- Par usme ek soorat chhoot gayi: create-user Edge Function.
--
-- Wo function service_role se chalta hai, aur service_role ka
-- `auth.uid()` NULL hota hai — koi logged-in user hai hi nahi.
-- To `is_admin_user()` false deta tha, trigger ko lagta tha "ye koi
-- aam user hai jo apna kind badal raha hai", aur wo exception phenk
-- deta tha.
--
-- Function apni taraf se sahi kar raha tha: update fail hone par usne
-- user ko delete kar diya (aadha-adhoora account chhodne se behtar).
-- Isliye bahar se lagta tha "account bana hi nahi".
--
-- FIX: server-side (service_role) calls ko chhod dena.
-- Ye surakshit hai kyunki service_role key sirf Edge Function ke andar
-- hai, browser me kabhi nahi jaati. Aur browser se aane wale har
-- request par auth.uid() hota hai, to wahan rok pehle jaisi hi lagti hai.

create or replace function public.guard_profile_columns()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Server-side call (Edge Function). auth.uid() tabhi null hota hai
  -- jab koi logged-in user hai hi nahi. Browser se aane wale calls me
  -- ye hamesha hota hai, isliye unpar rok waise hi lagi rehti hai.
  if auth.uid() is null then
    return new;
  end if;

  -- Admin par rok nahi — wo waise bhi sab badal sakta hai.
  if public.is_admin_user() then
    return new;
  end if;

  -- Baaki sabke liye: ye columns wahi rehne chahiye jo the.
  -- Sirf full_name, avatar_url, specialization, mastery,
  -- experience_years aur show_publicly badal sakte hain.
  if new.kind       is distinct from old.kind
     or new.role_id    is distinct from old.role_id
     or new.is_active  is distinct from old.is_active
     or new.agent_code is distinct from old.agent_code
     or new.email      is distinct from old.email then
    raise exception 'You cannot change your own access level or ID';
  end if;

  return new;
end;
$$;
