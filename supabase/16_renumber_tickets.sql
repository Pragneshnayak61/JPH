-- =====================================================================
-- Tickets 1 se number karna, created date aaj ki, due date 10 Sep,
-- aur Fabhind wale tickets AG-1 ko assign.
--
-- ⚠️  YE SCRIPT SAARE MAUJOODA TICKETS MITA DETI HAI.
--
-- Ticket ka id `generated always as identity` hai — Postgres wo apne aap
-- deta hai aur beech me se badla nahi ja sakta. 1 se shuru karne ka
-- ek hi tarika hai: sab mitao, counter reset karo, dobara daalo.
--
-- STEP 1 — pehle YE chalaiye aur dekhiye kya-kya mitega:
--
--   select id, subject, company_name, raised_by_email, status
--     from public.tickets order by id;
--
-- Usme koi ASLI ticket (kisi customer ka bheja hua) dikhe, to ruk
-- jaaiye aur mujhe bataiye — us haalat me alag tareeka lagega.
--
-- STEP 2 — sab test/import data hi ho, tab neeche wala poora chalaiye.
-- =====================================================================

-- Messages pehle — inka ticket_id tickets par lagta hai.
delete from public.ticket_messages;
delete from public.tickets;

-- Counter 1 par. Bina iske agla ticket wahin se shuru hoga jahan purana
-- chhoda tha.
alter table public.tickets alter column id restart with 1;


-- created_at me now() hai, koi likhi hui tareekh nahi — script jab bhi
-- chale, tab ki tareekh lag jayegi.
insert into public.tickets
  (subject, description, company_name, priority, status, raised_by_email,
   created_at, due_date)
values
  ('Change All Server Passwords', 'Change All Server Passwords', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Make Another Account In Physical Server And VM With Administrator Rights', 'Make Another Account In Physical Server And VM With Administrator Rights', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Local System VM Also Have Two Admin AC', 'Local System VM Also Have Two Admin AC', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('GPO Standardlization', 'GPO Standardlization', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('TightVnc In All Systems', 'TightVnc In All Systems', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Check Server Health', 'Check Server Health', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Server Restore Point', 'Server Restore Point', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Baremetal Backup', 'Baremetal Backup', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Change Documentation', 'Change Documentation', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Check Shadow Copy Enable Or Not', 'Check Shadow Copy Enable Or Not', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Check AV In All Server', 'Check AV In All Server', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('AD Recyclebeen', 'AD Recyclebeen', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Export User List', 'Export User List', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Change All Server Passwords', 'Change All Server Passwords', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Make Another Account In Physical Server And VM With Administrator Rights', 'Make Another Account In Physical Server And VM With Administrator Rights', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Local System VM Also Have Two Admin AC', 'Local System VM Also Have Two Admin AC', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('GPO Standardlization', 'GPO Standardlization', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('TightVnc In All Systems', 'TightVnc In All Systems', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Check Server Health', 'Check Server Health', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Server Restore Point', 'Server Restore Point', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Baremetal Backup', 'Baremetal Backup', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Change Documentation', 'Change Documentation', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Check Shadow Copy Enable Or Not', 'Check Shadow Copy Enable Or Not', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Check AV In All Server', 'Check AV In All Server', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('AD Recyclebeen', 'AD Recyclebeen', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Export User List', 'Export User List', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Change All Server Passwords', 'Change All Server Passwords', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Make Another Account In Physical Server And VM With Administrator Rights', 'Make Another Account In Physical Server And VM With Administrator Rights', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Local System VM Also Have Two Admin AC', 'Local System VM Also Have Two Admin AC', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('GPO Standardlization', 'GPO Standardlization', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('TightVnc In All Systems', 'TightVnc In All Systems', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Check Server Health', 'Check Server Health', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Server Restore Point', 'Server Restore Point', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Baremetal Backup', 'Baremetal Backup', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Change Documentation', 'Change Documentation', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Check Shadow Copy Enable Or Not', 'Check Shadow Copy Enable Or Not', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Check AV In All Server', 'Check AV In All Server', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('AD Recyclebeen', 'AD Recyclebeen', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Export User List', 'Export User List', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Change All Server Passwords', 'Change All Server Passwords', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Make Another Account In Physical Server And VM With Administrator Rights', 'Make Another Account In Physical Server And VM With Administrator Rights', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Local System VM Also Have Two Admin AC', 'Local System VM Also Have Two Admin AC', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('GPO Standardlization', 'GPO Standardlization', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('TightVnc In All Systems', 'TightVnc In All Systems', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Check Server Health', 'Check Server Health', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Server Restore Point', 'Server Restore Point', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Baremetal Backup', 'Baremetal Backup', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Change Documentation', 'Change Documentation', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Check Shadow Copy Enable Or Not', 'Check Shadow Copy Enable Or Not', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Check AV In All Server', 'Check AV In All Server', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('AD Recyclebeen', 'AD Recyclebeen', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Export User List', 'Export User List', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Change All Server Passwords', 'Change All Server Passwords', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Make Another Account In Physical Server And VM With Administrator Rights', 'Make Another Account In Physical Server And VM With Administrator Rights', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Local System VM Also Have Two Admin AC', 'Local System VM Also Have Two Admin AC', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('GPO Standardlization', 'GPO Standardlization', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('TightVnc In All Systems', 'TightVnc In All Systems', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Check Server Health', 'Check Server Health', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Server Restore Point', 'Server Restore Point', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Baremetal Backup', 'Baremetal Backup', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Change Documentation', 'Change Documentation', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Check Shadow Copy Enable Or Not', 'Check Shadow Copy Enable Or Not', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('Check AV In All Server', 'Check AV In All Server', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date),
  ('AD Recyclebeen', 'AD Recyclebeen', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date);


-- ---------------------------------------------------------------- assign
-- Fabhind ke tickets AG-1 ko.
--
-- AG-1 ka id yahin dhoondh rahe hain. Na mile to script ROK DETI hai —
-- bina rok ke assignment chup-chaap chhoot jaata aur pata bhi na chalta.
do $$
declare
  v_agent uuid;
begin
  -- 'AG-1' aur 'AG-01' dono dekh lete hain: purane codes "Agent 1" se
  -- badle the aur naye "AG-01" bante hain.
  select id into v_agent
    from public.profiles
   where agent_code in ('AG-1', 'AG-01')
     and kind in ('admin', 'agent')
   limit 1;

  if v_agent is null then
    raise exception 'AG-1 naam ka koi agent nahi mila. /admin/agents par jaakar kisi ki ID "AG-1" kar dijiye, phir ye script dobara chalaiye.';
  end if;

  update public.tickets
     set assigned_to = v_agent
   where company_name = 'Fabhind';
end $$;


-- ---------------------------------------------------------------- check
select company_name,
       count(*) as tickets,
       count(assigned_to) as assigned,
       min(due_date) as due
  from public.tickets
 group by company_name
 order by company_name;
