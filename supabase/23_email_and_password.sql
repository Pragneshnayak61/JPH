-- =====================================================================
-- Login email badalne ka poora fix — profile aur tickets, dono jagah.
--
-- Supabase -> SQL Editor me chalaiye. Dobara chalana safe hai.
-- =====================================================================
--
-- KYA HUA THA
--
-- Email teen jagah rehta hai:
--   auth.users.email          <- LOGIN isi se hota hai (Supabase ka table)
--   profiles.email            <- app me dikhane ke liye hamari copy
--   tickets.raised_by_email   <- ticket kis pate se aayi
--
-- Email badla to sirf pehla badla. Baaki do purane hi reh gaye. Nateeja:
--   - app purana email dikhata raha
--   - usi purane email se login karne par "Invalid login credentials"
--   - aur tickets ke jawab ek aise mailbox par jaate rahe jo ab uska
--     nahi hai
--
-- Bahar se lagta hai account hi kho gaya.
--
-- 19_email_change.sql me iske liye ek trigger tha. Wo kaafi nahi nikla:
-- wo sirf profiles.email sambhalta tha, tickets ko chhoota hi nahi. Aur
-- trigger auth.users par lagta hai — agar wo script kabhi chali hi na ho,
-- to copy hamesha ke liye peechhe reh jaati hai aur kisi ko pata bhi
-- nahi chalta.
--
-- Ab teen parat hain:
--   1. trigger              -> turant sync
--   2. sync_my_email() RPC  -> app har baar khulne par khud mila leti hai
--   3. ek baar ka reconcile -> jo farq abhi pada hai wo abhi mit jaaye
--
-- Ek parat fail ho to baaki do bacha leti hain.


-- ---------------------------------------------------------------- 1/5
-- Guard ko email ki ek soorat chhodni padegi.
--
-- 11_own_profile.sql wala guard profiles.email badalne se rokta hai —
-- theek hi rokta hai, warna agent apna email badal kar apni pehchaan
-- badal leta. Par isi rok ki wajah se sync bhi nahi ho paata tha.
--
-- Beech ka raasta: email tabhi badal sakta hai jab wo us bande ke ASLI
-- login email ke barabar ho. Yani copy ko asli se milane ki ijazat hai,
-- kuch bhi likhne ki nahi.

create or replace function public.guard_profile_columns()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Server-side call (Edge Function). service_role ka auth.uid() null
  -- hota hai; browser se aane wale har call par wo hamesha hota hai.
  if auth.uid() is null then
    return new;
  end if;

  if public.is_admin_user() then
    return new;
  end if;

  if new.kind       is distinct from old.kind
     or new.role_id    is distinct from old.role_id
     or new.is_active  is distinct from old.is_active
     or new.agent_code is distinct from old.agent_code then
    raise exception 'You cannot change your own access level or ID';
  end if;

  if new.email is distinct from old.email
     and new.email is distinct from
         (select u.email from auth.users u where u.id = new.id) then
    raise exception 'Your email can only be changed from account settings';
  end if;

  return new;
end;
$$;


-- ---------------------------------------------------------------- 2/5
-- Ek jagah, jahan se email har jagah badalta hai.
--
-- Trigger aur RPC dono yahi bulate hain. Do jagah alag-alag likhne par
-- ek din dono alag ho jaate hain, aur phir ek raasta tickets update
-- karta hai aur doosra nahi.

create or replace function public.apply_email_change(
  p_id  uuid,
  p_old text,
  p_new text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if coalesce(trim(p_new), '') = '' then
    return;
  end if;

  update public.profiles
     set email = p_new
   where id = p_id
     and email is distinct from p_new;

  -- Purana pata maloom na ho to tickets ko haath mat lagao — kis email
  -- ko badalna hai, yahi pata nahi.
  if coalesce(trim(p_old), '') = '' or lower(p_old) = lower(p_new) then
    return;
  end if;

  -- Ticket ka email badalna zaroori hai, warna uske jawab us mailbox par
  -- jaate rehte hain jo ab is bande ka hai hi nahi.
  --
  -- Milan lower() se, kyunki guest form se aaya email kisi bhi case me
  -- ho sakta hai.
  --
  -- Ye tickets.updated_at ko chhed dega (tickets_touch trigger). App me
  -- updated_at kahin dikhta ya sort nahi hota, isliye koi farq nahi
  -- padta.
  update public.tickets
     set raised_by_email = p_new
   where lower(raised_by_email) = lower(p_old);

  update public.ticket_messages
     set author_email = p_new
   where lower(author_email) = lower(p_old);
end;
$$;

revoke all on function public.apply_email_change(uuid, text, text) from public;
-- Sirf andar se bulaya jaata hai (trigger aur sync_my_email). Kisi client
-- ko iska seedha access nahi — warna koi bhi kisi ka bhi email likh deta.


-- ---------------------------------------------------------------- 3/5
-- Trigger: auth.users me email badle to sab jagah mila do.

create or replace function public.sync_profile_email()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Sirf tab jab email SACH ME badla ho. auth.users har login par update
  -- hoti hai (last_sign_in_at waghera) — bina is check ke ye trigger har
  -- baar bekaar me chalta.
  if new.email is distinct from old.email then
    perform public.apply_email_change(new.id, old.email, new.email);
  end if;
  return new;
end;
$$;

drop trigger if exists on_auth_email_changed on auth.users;
create trigger on_auth_email_changed
  after update of email on auth.users
  for each row execute function public.sync_profile_email();


-- ---------------------------------------------------------------- 4/5
-- App khud bhi mila le — trigger par poora bharosa nahi karna.
--
-- auth.users par lagaya hua trigger Supabase ke apne table ko chhoota
-- hai. Wo kabhi chale hi na (script na chali ho, ya Supabase apni taraf
-- se kuch badal de) to app ko pata tak nahi chalega. Isliye app har
-- login/reload par ye function bulati hai aur farq wahin khatam kar
-- deti hai.

create or replace function public.sync_my_email()
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id  uuid := auth.uid();
  v_old text;
  v_new text;
begin
  -- SQL Editor se chalane par auth.uid() null hota hai. Yahan exception
  -- phenkna galat hoga — ye function har page load par chalta hai, aur
  -- ek exception poori app rok deti.
  if v_id is null then
    return null;
  end if;

  select u.email into v_new from auth.users u where u.id = v_id;
  select p.email into v_old from public.profiles p where p.id = v_id;

  if v_new is null then
    return null;
  end if;

  perform public.apply_email_change(v_id, v_old, v_new);
  return v_new;
end;
$$;

revoke all on function public.sync_my_email() from public;
grant execute on function public.sync_my_email() to authenticated;


-- ---------------------------------------------------------------- 5/5
-- Jo farq abhi pada hua hai, wo abhi mita do — tickets samet.

do $$
declare
  r record;
begin
  for r in
    select p.id, p.email as old_email, u.email as new_email
      from public.profiles p
      join auth.users u on u.id = p.id
     where p.email is distinct from u.email
  loop
    perform public.apply_email_change(r.id, r.old_email, r.new_email);
  end loop;
end $$;


-- ---------------------------------------------------------------- check
-- Trigger sach me laga ya nahi:
select tgname as trigger_ka_naam,
       case tgenabled when 'O' then 'chalu' else tgenabled::text end as haalat
  from pg_trigger
 where tgrelid = 'auth.users'::regclass
   and not tgisinternal;

-- Ab koi farq bacha to nahi (mile_hue sab true hone chahiye):
select p.email as profile_email,
       u.email as login_email,
       (p.email = u.email) as mile_hue
  from public.profiles p
  join auth.users u on u.id = p.id
 order by u.created_at;

-- Tickets kis-kis pate par hain:
select raised_by_email, count(*) as kitni
  from public.tickets
 group by raised_by_email
 order by kitni desc;
