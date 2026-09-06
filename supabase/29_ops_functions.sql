-- =====================================================================
-- Operations — RPC functions
--
-- Supabase -> SQL Editor me chalaiye. Dobara chalana safe hai.
-- 27 aur 28 PEHLE chal chuki honi chahiye.
-- =====================================================================
--
-- KAUNSI CHEEZ RPC HAI AUR KAUNSI SEEDHI TABLE
--
-- Setup ka saara kaam (client, device, library, checklist) seedha table
-- par hota hai — RLS kaafi hai, aur RPC likhna sirf ek parat aur jod
-- deta bina kisi faayde ke.
--
-- RPC sirf wahan hai jahan bharosa ka sawal hai:
--   1. performed_by — client se aayi hui value kabhi nahi li ja sakti,
--      warna koi bhi kisi aur ke naam par jaanch "poori" kar sakta hai
--   2. logon ke naam — 24_hide_identity.sql ke niyam server par lagne
--      chahiye, browser par nahi (browser par chhupana chhupana nahi hota)
--   3. ticket banana — ticket banana aur usse execution se jodna, dono
--      ek saath hone chahiye, aadha nahi
--
-- Yahi lakeer poore project me pehle se khichi hui hai: create_guest_ticket
-- aur ticket_messages_list RPC hain, ticket_categories seedhi table.


-- ---------------------------------------------------------------- 1/8
-- Kisi bande ka naam kaise dikhega
--
-- 24_hide_identity.sql ke baad kisi ko doosre ka naam/email nahi dikhta,
-- admin ko bhi nahi. Us niyam ko yahan DOBARA nahi likh rahe — wahi
-- switch poochh rahe hain. Kal wo niyam badle to ye function apne aap
-- saath badal jaayega, is file ko chhue bina.

create or replace function public.ops_person_label(p_id uuid)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select case
           when p.id is null then null
           when public.identity_visible()
             then coalesce(nullif(trim(p.full_name), ''), p.email)
           else coalesce(p.agent_code, 'Agent')
         end
    from public.profiles p
   where p.id = p_id;
$$;

revoke all on function public.ops_person_label(uuid) from public;
grant execute on function public.ops_person_label(uuid) to authenticated;


-- ---------------------------------------------------------------- 2/8
-- Aaj ki list
--
-- BACKLOG BHI AATA HAI, sirf aaj ka nahi.
--
-- Agar sirf p_date ki rows lautatein, to jis din koi checklist na khole
-- us din ki pending jaanchein agle din nazar se hi gayab ho jaatin —
-- record me "pending" padi rehtin aur kisi ko pata na chalta. Isliye
-- pichhle 7 din ki jo abhi tak pending/in-progress hain, wo bhi saath
-- aati hain. UI unhe alag group me dikha sakta hai (due_date column se).
--
-- 7 din ki hadd isliye ki uske baad wo "aaj ka kaam" nahi rehta; wo
-- report ka mamla ban jaata hai.

create or replace function public.ops_today(
  p_date     date    default current_date,
  p_org      uuid    default null,
  p_category uuid    default null,
  p_device   uuid    default null,
  p_assignee uuid    default null,
  p_status   ops_status default null
)
returns table (
  execution_id    bigint,
  client_task_id  uuid,
  organization_id uuid,
  client_name     text,
  device_id       uuid,
  device_name     text,
  device_kind     ops_device_kind,
  category_id     uuid,
  category_name   text,
  task_name       text,
  instructions    text,
  frequency       ops_frequency,
  priority        ticket_priority,
  assigned_to     uuid,
  assigned_label  text,
  due_date        date,
  is_backlog      boolean,
  status          ops_status,
  remarks         text,
  performed_by    uuid,
  performed_label text,
  performed_at    timestamptz,
  ticket_id       bigint,
  ticket_status   ticket_status,
  file_count      bigint
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.ops_can_read() then
    raise exception 'Not allowed';
  end if;

  return query
    select e.id,
           e.client_task_id,
           e.organization_id,
           o.name,
           e.device_id,
           d.name,
           d.kind,
           e.category_id,
           c.name,
           e.task_name,
           t.instructions,
           t.frequency,
           t.priority,
           t.assigned_to,
           public.ops_person_label(t.assigned_to),
           e.due_date,
           (e.due_date < p_date),
           e.status,
           e.remarks,
           e.performed_by,
           public.ops_person_label(e.performed_by),
           e.performed_at,
           e.ticket_id,
           tk.status,
           (select count(*) from public.ops_execution_files f
             where f.execution_id = e.id)
      from public.ops_task_executions e
      join public.ops_client_tasks   t  on t.id = e.client_task_id
      join public.organizations      o  on o.id = e.organization_id
      left join public.ops_devices    d  on d.id = e.device_id
      left join public.ops_categories c  on c.id = e.category_id
      left join public.tickets       tk on tk.id = e.ticket_id
     where (
             e.due_date = p_date
             or (e.due_date < p_date
                 and e.due_date >= p_date - 7
                 and e.status in ('pending', 'in_progress'))
           )
       and (p_org      is null or e.organization_id = p_org)
       and (p_category is null or e.category_id     = p_category)
       and (p_device   is null or e.device_id       = p_device)
       and (p_assignee is null or t.assigned_to     = p_assignee)
       and (p_status   is null or e.status          = p_status)
     order by o.name, c.sort_order, e.task_name;
end;
$$;

revoke all on function public.ops_today(date, uuid, uuid, uuid, uuid, ops_status) from public;
grant execute on function public.ops_today(date, uuid, uuid, uuid, uuid, ops_status) to authenticated;


-- ---------------------------------------------------------------- 3/8
-- Ticket banane wala andar ka hissa
--
-- Do jagah se bulaya jaata hai: haath se "Create ticket" dabane par, aur
-- auto_ticket_on_fail lagi ho to ops_complete() se. Ek hi jagah likha
-- hai taaki dono ticket ek jaisi banayein — do jagah likhne par ek din
-- dono alag ho jaate hain.

create or replace function public.ops_ticket_for_execution(
  p_execution_id bigint,
  p_priority     ticket_priority default null
)
returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare
  e        public.ops_task_executions;
  v_org    text;
  v_device text;
  v_cat    text;
  v_who    text;
  v_prio   ticket_priority;
  v_id     bigint;
begin
  select * into e from public.ops_task_executions where id = p_execution_id;
  if not found then
    raise exception 'That check was not found';
  end if;

  -- Ek jaanch se ek hi ticket. Dobara dabane par purani hi wapas milti
  -- hai — warna ek fail hui backup jaanch se paanch ticket ban jaatin.
  if e.ticket_id is not null then
    return e.ticket_id;
  end if;

  select o.name into v_org    from public.organizations  o where o.id = e.organization_id;
  select d.name into v_device from public.ops_devices    d where d.id = e.device_id;
  select c.name into v_cat    from public.ops_categories c where c.id = e.category_id;

  v_who := public.ops_person_label(e.performed_by);

  select coalesce(p_priority, t.priority)
    into v_prio
    from public.ops_client_tasks t
   where t.id = e.client_task_id;

  -- description HTML hai kyunki app usse waise hi dikhati hai
  -- (looksLikeHtml + safeHtml). Plain text me ye saari lines ek saath
  -- chipak jaati hain.
  insert into public.tickets (
    subject, description, priority,
    organization_id,
    -- Customer ka email JAAN-BOOJH KAR khali. Ye andar ka ticket hai,
    -- iska koi bahar wala customer nahi. Ye 26_optional_customer_email.sql
    -- ke baad hi mumkin hua.
    raised_by_email,
    contact_name,
    created_by
  ) values (
    '[' || coalesce(v_org, 'Client') || '] ' || e.task_name || ' — ' ||
      upper(e.status::text),
    '<p><strong>Raised from the operations checklist.</strong></p>' ||
    '<p>' ||
      '<strong>Client:</strong> '   || coalesce(v_org, '—')    || '<br>' ||
      '<strong>Device:</strong> '   || coalesce(v_device, '—') || '<br>' ||
      '<strong>Task:</strong> '     || e.task_name             || '<br>' ||
      '<strong>Category:</strong> ' || coalesce(v_cat, '—')    || '<br>' ||
      '<strong>Check date:</strong> ' || to_char(e.due_date, 'DD Mon YYYY') || '<br>' ||
      '<strong>Result:</strong> '   || upper(e.status::text)   || '<br>' ||
      '<strong>Checked by:</strong> ' || coalesce(v_who, '—')  ||
    '</p>' ||
    '<p><strong>Remarks</strong><br>' ||
      coalesce(nullif(trim(e.remarks), ''), 'No remarks were added.') || '</p>',
    v_prio,
    e.organization_id,
    null,
    coalesce(v_org, 'Operations'),
    auth.uid()
  )
  returning id into v_id;

  update public.ops_task_executions
     set ticket_id = v_id
   where id = p_execution_id;

  return v_id;
end;
$$;

revoke all on function public.ops_ticket_for_execution(bigint, ticket_priority) from public;
-- Ye sirf andar se bulaya jaata hai. Bahar ka darwaza agla function hai,
-- jismein permission ki jaanch lagi hai.


create or replace function public.ops_create_ticket(
  p_execution_id bigint,
  p_priority     ticket_priority default null
)
returns bigint
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.ops_can_read() then
    raise exception 'Not allowed';
  end if;
  return public.ops_ticket_for_execution(p_execution_id, p_priority);
end;
$$;

revoke all on function public.ops_create_ticket(bigint, ticket_priority) from public;
grant execute on function public.ops_create_ticket(bigint, ticket_priority) to authenticated;


-- ---------------------------------------------------------------- 4/8
-- Jaanch poori karna
--
-- performed_by yahan SERVER par bharta hai, auth.uid() se. Client se
-- aayi hui value lene par koi bhi kisi aur ke naam par jaanch nipta
-- sakta tha — aur audit ka poora matlab hi khatam ho jaata.

create or replace function public.ops_complete(
  p_execution_id bigint,
  p_status       ops_status,
  p_remarks      text default null
)
returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare
  v_task   public.ops_client_tasks;
  v_exec   public.ops_task_executions;
  v_ticket bigint;
begin
  if not public.ops_can_read() then
    raise exception 'Not allowed';
  end if;

  if p_status = 'pending' then
    -- 'pending' par wapas jaana matlab "maine kuch nahi kiya". Us soorat
    -- me kisne kiya wo bhi mitna chahiye, warna record jhooth bolta hai.
    update public.ops_task_executions
       set status       = 'pending',
           remarks      = nullif(trim(p_remarks), ''),
           performed_by = null,
           performed_at = null
     where id = p_execution_id
    returning * into v_exec;
  else
    update public.ops_task_executions
       set status       = p_status,
           remarks      = coalesce(nullif(trim(p_remarks), ''), remarks),
           performed_by = auth.uid(),
           performed_at = now()
     where id = p_execution_id
    returning * into v_exec;
  end if;

  if not found then
    raise exception 'That check was not found';
  end if;

  -- Apne aap ticket — sirf tab jab is task par saaf-saaf chalu ki gayi
  -- ho. Default false hai aur aise hi rehni chahiye jab tak haath se
  -- banane ka tajurba na ho jaye.
  if p_status = 'failed' and v_exec.ticket_id is null then
    select * into v_task from public.ops_client_tasks
     where id = v_exec.client_task_id;
    if v_task.auto_ticket_on_fail then
      v_ticket := public.ops_ticket_for_execution(p_execution_id, null);
    end if;
  end if;

  return v_exec.id;
end;
$$;

revoke all on function public.ops_complete(bigint, ops_status, text) from public;
grant execute on function public.ops_complete(bigint, ops_status, text) to authenticated;


-- ---------------------------------------------------------------- 5/8
-- Ek saath kai jaanchein

create or replace function public.ops_bulk_complete(
  p_ids    bigint[],
  p_status ops_status
)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id    bigint;
  v_count int := 0;
begin
  if not public.ops_can_read() then
    raise exception 'Not allowed';
  end if;

  -- Ek-ek karke isliye ki ops_complete() me auto-ticket ka faisla bhi
  -- lagta hai. Seedha ek UPDATE likhne par wo chhoot jaata.
  foreach v_id in array coalesce(p_ids, '{}')
  loop
    perform public.ops_complete(v_id, p_status, null);
    v_count := v_count + 1;
  end loop;

  return v_count;
end;
$$;

revoke all on function public.ops_bulk_complete(bigint[], ops_status) from public;
grant execute on function public.ops_bulk_complete(bigint[], ops_status) to authenticated;


-- ---------------------------------------------------------------- 6/8
-- Dashboard ke ginti-ginne wale aankde
--
-- Ek hi call me sab, kyunki dashboard par har client ke liye alag query
-- chalane par 5 clients = 5 round trip, aur screen tukdon me bharti hai.

create or replace function public.ops_summary(p_date date default current_date)
returns table (
  organization_id uuid,
  client_name     text,
  total           bigint,
  completed       bigint,
  pending         bigint,
  in_progress     bigint,
  failed          bigint,
  attention       bigint,
  skipped         bigint,
  open_tickets    bigint,
  percent_done    int
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.ops_can_read() then
    raise exception 'Not allowed';
  end if;

  return query
    select o.id,
           o.name,
           count(*),
           count(*) filter (where e.status = 'completed'),
           count(*) filter (where e.status = 'pending'),
           count(*) filter (where e.status = 'in_progress'),
           count(*) filter (where e.status = 'failed'),
           count(*) filter (where e.status = 'attention'),
           count(*) filter (where e.status = 'skipped'),
           count(*) filter (where e.ticket_id is not null
                              and tk.status in ('open', 'replied')),
           -- skipped ko hisaab se bahar rakhte hain: jo jaanch jaan-boojh
           -- kar chhodi gayi wo "adhoori" nahi hai. Warna maintenance
           -- wale din har client 60% dikhta.
           case
             when count(*) filter (where e.status <> 'skipped') = 0 then 100
             else (100 * count(*) filter (where e.status = 'completed')
                   / count(*) filter (where e.status <> 'skipped'))::int
           end
      from public.ops_task_executions e
      join public.organizations o  on o.id = e.organization_id
      left join public.tickets  tk on tk.id = e.ticket_id
     where e.due_date = p_date
     group by o.id, o.name
     order by o.name;
end;
$$;

revoke all on function public.ops_summary(date) from public;
grant execute on function public.ops_summary(date) to authenticated;


-- ---------------------------------------------------------------- 7/8
-- Ek task ki poori history
--
-- "Client -> Server -> Task -> History" wala nazariya. Rows kabhi
-- overwrite nahi hotin, isliye ye sirf padhne ka kaam hai.

create or replace function public.ops_task_history(
  p_client_task_id uuid,
  p_limit          int default 60
)
returns table (
  execution_id    bigint,
  due_date        date,
  status          ops_status,
  remarks         text,
  performed_label text,
  performed_at    timestamptz,
  ticket_id       bigint,
  file_count      bigint
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.ops_can_read() then
    raise exception 'Not allowed';
  end if;

  return query
    select e.id, e.due_date, e.status, e.remarks,
           public.ops_person_label(e.performed_by),
           e.performed_at, e.ticket_id,
           (select count(*) from public.ops_execution_files f
             where f.execution_id = e.id)
      from public.ops_task_executions e
     where e.client_task_id = p_client_task_id
     order by e.due_date desc
     limit greatest(1, least(coalesce(p_limit, 60), 365));
end;
$$;

revoke all on function public.ops_task_history(uuid, int) from public;
grant execute on function public.ops_task_history(uuid, int) to authenticated;


-- ---------------------------------------------------------------- 8/8
-- Report — daily / weekly / monthly, client-wise
--
-- Ek hi function teeno ke liye. "Daily" ka matlab ek din ka range hai,
-- "monthly" ka teen sau ka — do alag function likhne ka koi faayda nahi.

create or replace function public.ops_report(
  p_from date,
  p_to   date,
  p_org  uuid default null
)
returns table (
  due_date        date,
  organization_id uuid,
  client_name     text,
  device_name     text,
  category_name   text,
  task_name       text,
  status          ops_status,
  remarks         text,
  performed_label text,
  performed_at    timestamptz,
  ticket_id       bigint,
  ticket_status   ticket_status
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.ops_can_read() then
    raise exception 'Not allowed';
  end if;

  if p_from is null or p_to is null or p_to < p_from then
    raise exception 'Please choose a valid date range';
  end if;
  if p_to - p_from > 400 then
    raise exception 'Please choose a range of one year or less';
  end if;

  return query
    select e.due_date,
           e.organization_id,
           o.name,
           d.name,
           c.name,
           e.task_name,
           e.status,
           e.remarks,
           public.ops_person_label(e.performed_by),
           e.performed_at,
           e.ticket_id,
           tk.status
      from public.ops_task_executions e
      join public.organizations o on o.id = e.organization_id
      left join public.ops_devices    d  on d.id = e.device_id
      left join public.ops_categories c  on c.id = e.category_id
      left join public.tickets        tk on tk.id = e.ticket_id
     where e.due_date between p_from and p_to
       and (p_org is null or e.organization_id = p_org)
     order by e.due_date desc, o.name, c.sort_order, e.task_name;
end;
$$;

revoke all on function public.ops_report(date, date, uuid) from public;
grant execute on function public.ops_report(date, date, uuid) to authenticated;


-- ---------------------------------------------------------------- check

-- Saare function ban gaye (8 rows):
select proname
  from pg_proc f
  join pg_namespace n on n.oid = f.pronamespace
 where n.nspname = 'public' and proname like 'ops\_%'
 order by proname;

-- Aaj ki list (abhi khali aayegi — generator 30 wali script me hai):
select * from public.ops_today();
