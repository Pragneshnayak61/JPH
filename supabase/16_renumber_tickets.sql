-- =====================================================================
-- Saare tickets: 11 purane (Fabhind, ho chuke) + 64 naye.
-- Numbering 1 se, aur Fabhind ke tickets AG-1 ko assign.
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
-- Koi ASLI ticket (kisi customer ka bheja hua) dikhe to ruk jaaiye.
--
-- STEP 2 — sab test/import data hi ho, tab poora chalaiye.
-- =====================================================================

delete from public.ticket_messages;
delete from public.tickets;
alter table public.tickets alter column id restart with 1;


-- ---------------------------------------------------------------- purane
-- 11 Fabhind tasks jo ho chuke hain (sheet ke rows 1-14; 5, 9, 12 nahi aaye).
--
-- Teen cheezein dhyan se ki hain:
--
-- 1. Row 13 ko RESOLVED nahi kiya. Uski sheet me likha hai "Report
--    generating Done (MAIL config pending)" — yani mail ka kaam abhi
--    baaki hai. Use open rakha hai aur sheet wala status description me
--    daal diya. Galat lage to ticket kholkar ek click me resolved kar
--    dijiye.
--
-- 2. Jinki due date khali thi (rows 6 aur 13), unme close date daali —
--    wo bhi na ho to created date. Khali chhodte to trigger AAJ ki
--    tareekh bhar deta, jo mahine purane record par bilkul galat hota.
--
-- 3. Row 3 me close date (21 May) create date (23 May) se PEHLE ki hai.
--    Sheet me jo likha tha wahi rakha hai, badla nahi — par ye galti
--    lagti hai, dekh lijiyega.
insert into public.tickets
  (subject, description, company_name, priority, status, raised_by_email,
   created_at, due_date, resolved_at)
values
  ('AV Server Movement to V to P', 'AV Server Movement to V to P', 'Fabhind', 'high', 'resolved', 'vahorajuned858@gmail.com', '2026-05-21'::timestamptz, '2026-05-30'::date, '2026-05-22'::timestamptz),
  ('Av Server Delete once tranfer', 'Av Server Delete once tranfer', 'Fabhind', 'high', 'resolved', 'vahorajuned858@gmail.com', '2026-05-21'::timestamptz, '2026-05-30'::date, '2026-06-06'::timestamptz),
  ('I Drive backup Schedule', 'I Drive backup Schedule', 'Fabhind', 'high', 'resolved', 'vahorajuned858@gmail.com', '2026-05-23'::timestamptz, '2026-05-23'::date, '2026-05-21'::timestamptz),
  ('Firewalls Backup', 'Firewalls Backup', 'Fabhind', 'high', 'resolved', 'vahorajuned858@gmail.com', '2026-06-04'::timestamptz, '2026-06-04'::date, '2026-06-04'::timestamptz),
  ('CCTV Backup', 'CCTV Backup

Status from sheet: Done(192.168.1.100 D:)', 'Fabhind', 'high', 'resolved', 'vahorajuned858@gmail.com', '2026-05-25'::timestamptz, '2026-05-25'::date, null),
  ('Antivirus Backup', 'Antivirus Backup

Status from sheet: Done(192.168..1.100 D:)', 'Fabhind', 'high', 'resolved', 'vahorajuned858@gmail.com', '2026-05-27'::timestamptz, '2026-06-07'::date, '2026-06-07'::timestamptz),
  ('Remove unwanted VM(Sequrite Antivirus,CCTV)', 'Remove unwanted VM(Sequrite Antivirus,CCTV)', 'Fabhind', 'high', 'resolved', 'vahorajuned858@gmail.com', '2026-05-26'::timestamptz, '2026-06-06'::date, '2026-06-07'::timestamptz),
  ('QNAP Study', 'QNAP Study', 'Fabhind', 'high', 'resolved', 'vahorajuned858@gmail.com', '2026-05-27'::timestamptz, '2026-06-07'::date, '2026-06-07'::timestamptz),
  ('Change VM local administrator passwords', 'Change VM local administrator passwords', 'Fabhind', 'high', 'resolved', 'vahorajuned858@gmail.com', '2026-05-28'::timestamptz, '2026-06-07'::date, '2026-06-07'::timestamptz),
  ('end point securite report setup on mail (file opening,pendrive cpy paste)', 'end point securite report setup on mail (file opening,pendrive cpy paste)

Status from sheet: Report generating Done (MAIL config pending)', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', '2026-06-06'::timestamptz, '2026-06-07'::date, null),
  ('make one AV police that stops user to surfing on internet in server only mail can run', 'make one AV police that stops user to surfing on internet in server only mail can run', 'Fabhind', 'high', 'resolved', 'vahorajuned858@gmail.com', '2026-06-06'::timestamptz, '2026-06-07'::date, '2026-06-07'::timestamptz);


-- ---------------------------------------------------------------- naye
-- 64 naye tasks — sab open, due 10 Sep, created aaj.
insert into public.tickets
  (subject, description, company_name, priority, status, raised_by_email,
   created_at, due_date, resolved_at)
values
  ('Change All Server Passwords', 'Change All Server Passwords', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Make Another Account In Physical Server And VM With Administrator Rights', 'Make Another Account In Physical Server And VM With Administrator Rights', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Local System VM Also Have Two Admin AC', 'Local System VM Also Have Two Admin AC', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('GPO Standardlization', 'GPO Standardlization', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('TightVnc In All Systems', 'TightVnc In All Systems', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Check Server Health', 'Check Server Health', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Server Restore Point', 'Server Restore Point', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Baremetal Backup', 'Baremetal Backup', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Change Documentation', 'Change Documentation', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Check Shadow Copy Enable Or Not', 'Check Shadow Copy Enable Or Not', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Check AV In All Server', 'Check AV In All Server', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('AD Recyclebeen', 'AD Recyclebeen', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Export User List', 'Export User List', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Change All Server Passwords', 'Change All Server Passwords', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Make Another Account In Physical Server And VM With Administrator Rights', 'Make Another Account In Physical Server And VM With Administrator Rights', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Local System VM Also Have Two Admin AC', 'Local System VM Also Have Two Admin AC', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('GPO Standardlization', 'GPO Standardlization', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('TightVnc In All Systems', 'TightVnc In All Systems', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Check Server Health', 'Check Server Health', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Server Restore Point', 'Server Restore Point', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Baremetal Backup', 'Baremetal Backup', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Change Documentation', 'Change Documentation', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Check Shadow Copy Enable Or Not', 'Check Shadow Copy Enable Or Not', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Check AV In All Server', 'Check AV In All Server', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('AD Recyclebeen', 'AD Recyclebeen', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Export User List', 'Export User List', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Change All Server Passwords', 'Change All Server Passwords', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Make Another Account In Physical Server And VM With Administrator Rights', 'Make Another Account In Physical Server And VM With Administrator Rights', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Local System VM Also Have Two Admin AC', 'Local System VM Also Have Two Admin AC', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('GPO Standardlization', 'GPO Standardlization', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('TightVnc In All Systems', 'TightVnc In All Systems', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Check Server Health', 'Check Server Health', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Server Restore Point', 'Server Restore Point', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Baremetal Backup', 'Baremetal Backup', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Change Documentation', 'Change Documentation', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Check Shadow Copy Enable Or Not', 'Check Shadow Copy Enable Or Not', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Check AV In All Server', 'Check AV In All Server', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('AD Recyclebeen', 'AD Recyclebeen', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Export User List', 'Export User List', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Change All Server Passwords', 'Change All Server Passwords', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Make Another Account In Physical Server And VM With Administrator Rights', 'Make Another Account In Physical Server And VM With Administrator Rights', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Local System VM Also Have Two Admin AC', 'Local System VM Also Have Two Admin AC', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('GPO Standardlization', 'GPO Standardlization', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('TightVnc In All Systems', 'TightVnc In All Systems', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Check Server Health', 'Check Server Health', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Server Restore Point', 'Server Restore Point', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Baremetal Backup', 'Baremetal Backup', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Change Documentation', 'Change Documentation', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Check Shadow Copy Enable Or Not', 'Check Shadow Copy Enable Or Not', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Check AV In All Server', 'Check AV In All Server', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('AD Recyclebeen', 'AD Recyclebeen', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Export User List', 'Export User List', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Change All Server Passwords', 'Change All Server Passwords', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Make Another Account In Physical Server And VM With Administrator Rights', 'Make Another Account In Physical Server And VM With Administrator Rights', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Local System VM Also Have Two Admin AC', 'Local System VM Also Have Two Admin AC', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('GPO Standardlization', 'GPO Standardlization', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('TightVnc In All Systems', 'TightVnc In All Systems', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Check Server Health', 'Check Server Health', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Server Restore Point', 'Server Restore Point', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Baremetal Backup', 'Baremetal Backup', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Change Documentation', 'Change Documentation', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Check Shadow Copy Enable Or Not', 'Check Shadow Copy Enable Or Not', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('Check AV In All Server', 'Check AV In All Server', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null),
  ('AD Recyclebeen', 'AD Recyclebeen', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', now(), '2026-09-10'::date, null);


-- ---------------------------------------------------------------- assign
-- Fabhind ke SAARE tickets AG-1 ko (purane bhi, naye bhi).
-- Purane wo hi hain jo unhone khud kiye the, isliye resolved_by bhi wahi.
do $$
declare
  v_agent uuid;
begin
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

  -- resolved_by se hi Analytics ginti karta hai. Ye na bharte to unke
  -- kiye hue 10 ticket kisi ke naam par nahi chadhte.
  update public.tickets
     set resolved_by = v_agent
   where company_name = 'Fabhind'
     and status = 'resolved';
end $$;


-- ---------------------------------------------------------------- check
select company_name,
       count(*) as tickets,
       count(*) filter (where status = 'resolved') as resolved,
       count(assigned_to) as assigned
  from public.tickets
 group by company_name
 order by company_name;
