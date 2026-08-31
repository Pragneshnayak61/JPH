-- =====================================================================
-- Pehchaan sabse chupa do — admin se bhi.
--
-- Supabase -> SQL Editor me chalaiye. Dobara chalana safe hai.
-- =====================================================================
--
-- Ab tak niyam ye tha: agent ko sirf "Agent 1" jaisi ID dikhti thi, aur
-- ADMIN ko asli naam/email. Ab wo chhoot bhi hata rahe hain — koi bhi,
-- admin bhi, kisi doosre ka naam ya email nahi dekhega. Sabko sirf ID
-- aur specialization.
--
-- Apna khud ka naam/email har koi dekh sakta hai (My profile). Rok
-- DOOSRON ki pehchaan par hai.
--
-- Customer ka email (tickets.raised_by_email) isme NAHI aata. Wo chhupa
-- diya to ticket ka jawab kis pate par jaayega — helpdesk ka kaam hi ruk
-- jaayega. Ye rok sirf staff (admin/agent) ki pehchaan par hai.
--
-- Data mitaya NAHI ja raha. Naam aur email profiles me jaise the waise
-- pade rahenge — sirf dikhna band ho raha hai. Wapas chaalu karna ek
-- line ka kaam hai (neeche 1/7 dekhiye).


-- ---------------------------------------------------------------- 1/7
-- Ek hi switch, jise poora system poochhta hai.
--
-- Har jagah alag-alag shart likhne par ek din koi ek jagah chhoot jaati
-- hai, aur wahin se pehchaan leak hoti hai. Isliye sawal ek hi jagah
-- poochha jaata hai.
--
-- WAPAS CHAALU KARNE KE LIYE: neeche wali `select false` ko
-- `select public.is_admin_user()` se badal kar file dobara chala dijiye.
-- Tab admin ko phir se asli naam aur email dikhne lagenge, aur agent ko
-- tab bhi nahi. Aur kahin kuch badalne ki zaroorat nahi.

create or replace function public.identity_visible()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select false;
$$;

grant execute on function public.identity_visible() to anon, authenticated;


-- ---------------------------------------------------------------- 2/7
-- Assign wali directory — ab label hamesha ID.
--
-- Return ki shakl jaan-boojh kar wahi rakhi hai (email column samet),
-- taaki app ka code badalna na pade. Email ab hamesha null jaata hai.

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
  v_show boolean := public.identity_visible();
begin
  if not public.is_staff() then
    raise exception 'Not allowed';
  end if;

  return query
    select p.id,
           case
             when v_show then coalesce(nullif(trim(p.full_name), ''), p.email)
             -- coalesce isliye ki ID kisi wajah se na bani ho to email
             -- leak na ho jaye.
             else coalesce(p.agent_code, 'Agent')
           end as label,
           case when v_show then p.email else null end as email,
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


-- ---------------------------------------------------------------- 3/7
-- Analytics ke stats — wahi niyam.

create or replace function public.agent_stats(p_days int default null)
returns table (
  agent_id       uuid,
  label          text,
  specialization text,
  assigned       bigint,
  open_count     bigint,
  resolved       bigint
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_show boolean := public.identity_visible();
  -- null = "all time". Aisi date rakhte hain jo har ticket se purani ho,
  -- taaki neeche ek hi query se dono soorat sambhal jayein.
  v_from timestamptz := case
    when p_days is null then '-infinity'::timestamptz
    else now() - make_interval(days => p_days)
  end;
begin
  if not public.is_staff() then
    raise exception 'Not allowed';
  end if;

  return query
    select
      p.id,
      case
        when v_show then coalesce(nullif(trim(p.full_name), ''), p.email)
        else coalesce(p.agent_code, 'Agent')
      end,
      nullif(trim(p.specialization), ''),
      count(distinct t_assigned.id),
      count(distinct t_open.id),
      count(distinct t_resolved.id)
    from public.profiles p
    left join public.tickets t_assigned
      on t_assigned.assigned_to = p.id
     and t_assigned.created_at >= v_from
    left join public.tickets t_open
      on t_open.assigned_to = p.id
     and t_open.status in ('open', 'replied')
     and t_open.created_at >= v_from
    left join public.tickets t_resolved
      on t_resolved.resolved_by = p.id
     -- resolved ki ginti resolve hone ki tareekh se, banne ki nahi.
     and coalesce(t_resolved.resolved_at, t_resolved.created_at) >= v_from
    where p.kind in ('admin', 'agent') and p.is_active
    group by p.id, p.full_name, p.email, p.agent_code, p.specialization
    order by count(distinct t_resolved.id) desc, p.agent_code;
end;
$$;

revoke all on function public.agent_stats(int) from public;
grant execute on function public.agent_stats(int) to authenticated;


-- ---------------------------------------------------------------- 4/7
-- Mentions — "kisne mention kiya" bhi ab ID se.

create or replace function public.my_mentions()
returns table (
  id           bigint,
  ticket_id    bigint,
  subject      text,
  body         text,
  by_label     text,
  read_at      timestamptz,
  created_at   timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_show boolean := public.identity_visible();
begin
  if not public.is_staff() then
    raise exception 'Not allowed';
  end if;

  return query
    select m.id, m.ticket_id, t.subject, msg.body,
           case
             when v_show then coalesce(nullif(trim(p.full_name), ''), p.email)
             else coalesce(p.agent_code, 'Agent')
           end,
           m.read_at, m.created_at
      from public.message_mentions m
      join public.tickets t          on t.id = m.ticket_id
      join public.ticket_messages msg on msg.id = m.message_id
      left join public.profiles p    on p.id = m.mentioned_by
     where m.profile_id = auth.uid()
     order by m.created_at desc
     limit 50;
end;
$$;

revoke all on function public.my_mentions() from public;
grant execute on function public.my_mentions() to authenticated;


-- ---------------------------------------------------------------- 5/7
-- Ab asli taala: RLS.
--
-- Upar wale function to sudhar gaye, par admin ki app abhi bhi
-- `select * from profiles` seedha chala sakti thi — aur wahan poore naam
-- aur email aate the. UI me chhupa dena kaafi nahi hota: cheez network
-- par to chali hi jaati hai aur browser ke devtools me dikh jaati hai.
-- Isliye rok yahan, database par.
--
-- SELECT: sirf apni row. (Switch wapas chalu ho to admin ko sab.)
drop policy if exists profiles_self_read on public.profiles;
create policy profiles_self_read on public.profiles
  for select using (
    id = auth.uid()
    or (public.identity_visible() and public.is_admin_user())
  );

-- `profiles_admin_all` `for all` thi — usme SELECT bhi shaamil tha, aur
-- policies OR hoti hain, isliye wo upar wali rok ko bekaar kar deti.
-- Isliye use todh kar sirf likhne wali teen policies bana rahe hain.
-- Admin ka kaam (kind/role/ID badalna, disable karna) waise ka waisa
-- chalta rahega.
drop policy if exists profiles_admin_all on public.profiles;

drop policy if exists profiles_admin_insert on public.profiles;
create policy profiles_admin_insert on public.profiles
  for insert with check (public.has_perm('can_manage_agents'));

drop policy if exists profiles_admin_update on public.profiles;
create policy profiles_admin_update on public.profiles
  for update using (public.has_perm('can_manage_agents'))
  with check (public.has_perm('can_manage_agents'));

drop policy if exists profiles_admin_delete on public.profiles;
create policy profiles_admin_delete on public.profiles
  for delete using (public.has_perm('can_manage_agents'));

-- Removed accounts me bhi naam aur email pade hain — wahi taala.
drop policy if exists deleted_accounts_admin_read on public.deleted_accounts;
create policy deleted_accounts_admin_read on public.deleted_accounts
  for select using (
    public.identity_visible() and public.is_admin_user()
  );

-- Har message par jawab dene wale agent ka asli naam aur email likha
-- hota hai (author_name / author_email). Wo customer ke liye hai — mail
-- me usi ke naam se jawab jaata hai. Par ticket kholte hi poori list
-- browser me utar aati thi, aur wahin doosre agents ke naam pade the.
--
-- Column-level grant se ye do column authenticated ke liye band. Pehle
-- table-level SELECT hatana zaroori hai — Postgres me table wala grant
-- rehte hue column wala revoke kuch nahi karta, aur rok chup-chaap
-- bekaar chali jaati.
--
-- Likhna nahi rok rahe: INSERT alag privilege hai, isliye agent ka
-- jawab pehle ki tarah in dono column me save hota rahega, aur customer
-- ko mail me naam bhi wahi dikhega. Bas staff ki screen tak ye pahunchte
-- nahi.
--
-- Guest wale raaste (get_guest_ticket) par koi asar nahi — wo SECURITY
-- DEFINER hain, unpar ye grant lagti hi nahi.
revoke select on public.ticket_messages from authenticated;
grant select (id, ticket_id, author_id, body, is_internal, created_at)
  on public.ticket_messages to authenticated;


-- ---------------------------------------------------------------- 6/7
-- People page ke liye list.
--
-- Upar RLS band kar di, to People page ko ab seedha table se kuch nahi
-- milega. Use ye function milta hai — usme wo sab hai jo managing ke
-- liye chahiye (ID, access, role, status, specialization), aur naam/email
-- tabhi jab switch chalu ho.
--
-- Yani page dono haalat me theek chalta hai; usme koi shart nahi likhni
-- padti.

create or replace function public.staff_admin_list()
returns table (
  id             uuid,
  email          text,
  full_name      text,
  kind           user_kind,
  role_id        uuid,
  is_active      boolean,
  agent_code     text,
  specialization text
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_show boolean := public.identity_visible();
begin
  if not public.has_perm('can_manage_agents') then
    raise exception 'Not allowed';
  end if;

  return query
    select p.id,
           case when v_show then p.email else null end,
           case when v_show then p.full_name else null end,
           p.kind,
           p.role_id,
           p.is_active,
           p.agent_code,
           p.specialization
      from public.profiles p
     order by p.kind, p.agent_code nulls last, p.created_at;
end;
$$;

revoke all on function public.staff_admin_list() from public;
grant execute on function public.staff_admin_list() to authenticated;


-- Wahi baat removed accounts ke liye.
create or replace function public.deleted_accounts_list()
returns table (
  id               uuid,
  email            text,
  full_name        text,
  agent_code       text,
  kind             text,
  specialization   text,
  resolved_count   int,
  deleted_at       timestamptz,
  deleted_by_label text
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_show boolean := public.identity_visible();
begin
  if not public.is_admin_user() then
    raise exception 'Not allowed';
  end if;

  return query
    select d.id,
           case when v_show then d.email else null end,
           case when v_show then d.full_name else null end,
           d.agent_code,
           d.kind,
           d.specialization,
           d.resolved_count,
           d.deleted_at,
           -- "Kisne hataya" bhi ek pehchaan hi hai.
           case when v_show then d.deleted_by_label else null end
      from public.deleted_accounts d
     order by d.deleted_at desc;
end;
$$;

revoke all on function public.deleted_accounts_list() from public;
grant execute on function public.deleted_accounts_list() to authenticated;


-- Ticket ki baat-cheet.
--
-- Upar do column band kar diye, isliye ab ticket ke messages seedha table
-- se nahi aa sakte. Par ek farq zaroori hai:
--
--   customer ka message (author_id null) -> uska naam DIKHNA CHAHIYE.
--     Wo ticket ka maalik hai, staff nahi. Uska naam chhupa denge to
--     agent ko pata hi nahi chalega kis se baat ho rahi hai.
--   staff ka message (author_id lga hua) -> naam/email null.
--     Uski jagah screen par uski ID dikhti hai.
--
-- Yahi baareek farq column-level grant akela nahi kar sakta — wo poora
-- column band karti hai, chaahe kisi ka bhi ho. Isliye ye function.
--
-- SECURITY DEFINER hai, to ticket dikhne ka niyam yahan HAATH SE dobara
-- lagana padta hai — warna jis agent ko sirf apne assigned tickets
-- dikhte hain, wo id badal-badal kar kisi bhi ticket ki baat-cheet
-- padh leta.

create or replace function public.ticket_messages_list(p_ticket_id bigint)
returns table (
  id           bigint,
  body         text,
  is_internal  boolean,
  author_id    uuid,
  author_name  text,
  author_email text,
  created_at   timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_show boolean := public.identity_visible();
begin
  if not public.is_staff() then
    raise exception 'Not allowed';
  end if;

  -- Wahi shart jo tickets_staff_read policy me hai.
  if not exists (
    select 1
      from public.tickets t
     where t.id = p_ticket_id
       and (public.has_perm('can_view_all_tickets')
            or t.assigned_to = auth.uid()
            or t.created_by  = auth.uid())
  ) then
    raise exception 'Not allowed';
  end if;

  return query
    select m.id,
           m.body,
           m.is_internal,
           m.author_id,
           case when m.author_id is null or v_show then m.author_name end,
           case when m.author_id is null or v_show then m.author_email end,
           m.created_at
      from public.ticket_messages m
     where m.ticket_id = p_ticket_id
     order by m.created_at;
end;
$$;

revoke all on function public.ticket_messages_list(bigint) from public;
grant execute on function public.ticket_messages_list(bigint) to authenticated;


-- ---------------------------------------------------------------- 7/7
-- Check.

-- Switch abhi kya keh raha hai (false hona chahiye):
select public.identity_visible() as pehchaan_dikhti_hai;

-- profiles par ab kaun si policy lagi hai. SELECT wali sirf EK honi
-- chahiye, aur usme is_admin_user() akela nahi — identity_visible() ke
-- saath hona chahiye.
select polname as policy_ka_naam,
       case polcmd when 'r' then 'select' when 'a' then 'insert'
                   when 'w' then 'update' when 'd' then 'delete'
                   else 'all' end as kis_par
  from pg_policy
 where polrelid = 'public.profiles'::regclass
 order by polcmd, polname;

-- Naam aur email abhi bhi database me salaamat hain (sirf chhupe hain):
select agent_code, kind,
       (full_name is not null) as naam_maujood,
       (email is not null) as email_maujood
  from public.profiles
 order by agent_code nulls last;
