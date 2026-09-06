-- =====================================================================
-- "Is email ka account hai ya nahi" — forgot password ke liye.
--
-- Supabase -> SQL Editor me chalaiye. Dobara chalana safe hai.
-- =====================================================================
--
-- KYUN
--
-- Forgot password wala page pehle har email par ek jaisa jawab deta tha:
-- code bheja ho ya na bheja ho, screen wahi. Ab aap chahte hain ki galat
-- email daalne par saaf-saaf bata diya jaaye aur code bheja hi na jaaye.
--
-- Browser se ye seedha nahi poochha ja sakta. profiles par RLS lagi hai
-- aur auth.users to waise bhi Supabase ka apna table hai — bina login ke
-- dono me se kuch nahi dikhta. Isliye ye ek chhota sa definer function,
-- jo sirf haan/na kehta hai aur iske alawa kuch nahi.
--
-- JO BAAT MAAN KAR YE BANAYA JA RAHA HAI
--
-- Ye function bina login ke sabke liye khula hai — yani koi bhi ek-ek
-- karke pate daal kar ye ginn sakta hai ki yahan kaun-kaun hai. Isi
-- wajah se Supabase khud kabhi nahi batata ki account hai ya nahi.
--
-- Aapka faisla hai, aur ek andar ke helpdesk par ye chalta hai: yahan
-- naye account admin banata hai, khud koi sign-up nahi karta, isliye
-- "kaun-kaun hai" waise bhi office bhar ko pata hota hai.
--
-- Do cheezein isse phir bhi nahi milti: naam aur email ki jodi. Function
-- sirf true/false deta hai — na naam, na kind, na ID. Aur pehchaan wala
-- lockdown (24) apni jagah kayam hai.
--
-- Wapas chhupana ho to sirf itna: is function ka grant hata dijiye aur
-- ForgotPassword.vue me lookup wala hissa nikaal dijiye. Baaki flow
-- jaisa hai waisa chalta rahega.


-- ---------------------------------------------------------------- 1/2
-- Sawal auth.users se poochha jaata hai, profiles se nahi.
--
-- LOGIN auth.users se hota hai. Password reset bhi wahi table chhoota
-- hai. profiles hamari apni copy hai — wo kabhi peechhe reh jaaye
-- (aisa pehle ho chuka hai, 23 dekhiye) to ye function "account nahi
-- hai" keh kar us bande ko bahar hi khada rakh deta, jabki uska login
-- theek se maujood hai.

create or replace function public.account_exists(p_email text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
      from auth.users u
     where lower(u.email) = lower(trim(coalesce(p_email, '')))
  );
$$;

revoke all on function public.account_exists(text) from public;
-- anon ko dena ZAROORI hai: password bhoolne wala logged out hi hota
-- hai. authenticated isliye ki koi login screen kabhi khuli chhod deta
-- hai aur purana session pada rehta hai.
grant execute on function public.account_exists(text) to anon, authenticated;


-- ---------------------------------------------------------------- 2/2
-- Check

-- Ye true aana chahiye (apna email daaliye):
-- select public.account_exists('you@company.com');

-- Ye hamesha false:
select public.account_exists('koi-aisa-pata-nahi-hai@example.com') as jhoota_pata,
       public.account_exists(null)                                as khaali,
       public.account_exists('')                                  as bilkul_khaali;

-- Kis-kis pate ka account hai (sirf aapki apni tasalli ke liye):
select email from auth.users order by created_at;
