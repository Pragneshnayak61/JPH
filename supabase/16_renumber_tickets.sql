-- =====================================================================
-- Saare tickets: 13 purane (Fabhind, ho chuke) + 64 naye = 77.
-- Numbering 1 se, aur Fabhind ke saare tickets AG-1 ko.
--
-- ⚠️  YE SCRIPT SAARE MAUJOODA TICKETS MITA DETI HAI.
--
-- Ticket ka id `generated always as identity` hai — beech me se badla
-- nahi ja sakta. 1 se shuru karne ka ek hi tarika: sab mitao, counter
-- reset karo, dobara daalo.
--
-- STEP 1 — pehle YE chalaiye aur dekhiye kya-kya mitega:
--   select id, subject, company_name, status from public.tickets order by id;
-- Koi ASLI ticket (customer ka bheja hua) dikhe to ruk jaaiye.
--
-- STEP 2 — sab test/import data hi ho, tab poora chalaiye.
-- =====================================================================

delete from public.ticket_messages;
delete from public.tickets;
alter table public.tickets alter column id restart with 1;


-- ---------------------------------------------------------------- purane
-- Sheet ke rows 1-16 me se 13 (5, 9, 12 nahi the).
--
-- STATUS ka faisla:
--   "Done" / "Done(...)"  -> resolved  (10 rows)
--   baaki teen            -> closed    (band to hue, par kaam poora nahi)
--
--     #13  "Report generating Done (MAIL config pending)"
--     #15  "This option not available in our version"
--     #16  "Required sender and reciver mail"
--
-- Inhe bhi 'resolved' kar dete to Analytics me ye "kar diye" me gin
-- jaate — jabki #15 to ho hi nahi sakta tha. 'closed' se farq bana
-- rehta hai. Galat lage to ticket kholkar badal dijiye.
--
-- Sheet ka status text description me bhi daala hai, warna
-- "Done(192.168.1.100 D:)" jaisi jaankari (backup kahan pada hai)
-- hamesha ke liye kho jaati.
--
-- DEKH LIJIYEGA:
--   #6   'Done' hai par close date nahi thi — resolved_at khali chhoda
--   #16  created 8 June hai par due 7 June, yani due date create se
--        PEHLE. Sheet me jo tha wahi rakha, badla nahi.
insert into public.tickets
  (subject, description, company_name, priority, status, raised_by_email,
   created_at, due_date, resolved_at)
values
  ('AV Server Movement to V to P', 'AV Server Movement to V to P', 'Fabhind', 'high', 'resolved', 'vahorajuned858@gmail.com', '2026-05-21'::timestamptz, '2026-05-30'::date, '2026-05-22'::timestamptz),
  ('Av Server Delete once tranfer', 'Av Server Delete once tranfer', 'Fabhind', 'high', 'resolved', 'vahorajuned858@gmail.com', '2026-05-21'::timestamptz, '2026-05-30'::date, '2026-06-06'::timestamptz),
  ('I Drive backup Schedule', 'I Drive backup Schedule', 'Fabhind', 'high', 'resolved', 'vahorajuned858@gmail.com', '2026-05-21'::timestamptz, '2026-05-23'::date, '2026-05-21'::timestamptz),
  ('Firewalls Backup', 'Firewalls Backup', 'Fabhind', 'high', 'resolved', 'vahorajuned858@gmail.com', '2026-06-04'::timestamptz, '2026-06-04'::date, '2026-06-04'::timestamptz),
  ('CCTV Backup', 'CCTV Backup

Status from sheet: Done(192.168.1.100 D:)', 'Fabhind', 'high', 'resolved', 'vahorajuned858@gmail.com', '2026-05-25'::timestamptz, '2026-06-07'::date, null),
  ('Antivirus Backup', 'Antivirus Backup

Status from sheet: Done(192.168..1.100 D:)', 'Fabhind', 'high', 'resolved', 'vahorajuned858@gmail.com', '2026-05-27'::timestamptz, '2026-06-07'::date, '2026-06-07'::timestamptz),
  ('Remove unwanted VM(Sequrite Antivirus,CCTV)', 'Remove unwanted VM(Sequrite Antivirus,CCTV)', 'Fabhind', 'high', 'resolved', 'vahorajuned858@gmail.com', '2026-05-26'::timestamptz, '2026-06-06'::date, '2026-06-07'::timestamptz),
  ('QNAP Study', 'QNAP Study', 'Fabhind', 'high', 'resolved', 'vahorajuned858@gmail.com', '2026-05-27'::timestamptz, '2026-06-07'::date, '2026-06-07'::timestamptz),
  ('Change VM local administrator passwords', 'Change VM local administrator passwords', 'Fabhind', 'high', 'resolved', 'vahorajuned858@gmail.com', '2026-05-28'::timestamptz, '2026-06-07'::date, '2026-06-07'::timestamptz),
  ('end point securite report setup on mail (file opening,pendrive cpy paste)', 'end point securite report setup on mail (file opening,pendrive cpy paste)

Status from sheet: Report generating Done (MAIL config pending)', 'Fabhind', 'high', 'closed', 'vahorajuned858@gmail.com', '2026-06-06'::timestamptz, '2026-06-07'::date, '2026-06-07'::timestamptz),
  ('make one AV police that stops user to surfing on internet in server only mail can run', 'make one AV police that stops user to surfing on internet in server only mail can run', 'Fabhind', 'high', 'resolved', 'vahorajuned858@gmail.com', '2026-06-06'::timestamptz, '2026-06-07'::date, '2026-06-07'::timestamptz),
  ('QNAP screening ON(only .csv) file only', 'QNAP screening ON(only .csv) file only

Status from sheet: This option not available in our version', 'Fabhind', 'high', 'closed', 'vahorajuned858@gmail.com', '2026-06-07'::timestamptz, '2026-06-07'::date, '2026-06-07'::timestamptz),
  ('Notify when the QNAP device is turn OFF/ON', 'Notify when the QNAP device is turn OFF/ON

Status from sheet: Required sender and reciver mail', 'Fabhind', 'high', 'closed', 'vahorajuned858@gmail.com', '2026-06-08'::timestamptz, '2026-06-07'::date, '2026-06-07'::timestamptz);


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

  -- Analytics ki ginti resolved_by se hoti hai, status se nahi. Ye na
  -- bharte to unke niptaaye hue 13 ticket kisi ke naam par na chadhte.
  update public.tickets
     set resolved_by = v_agent
   where company_name = 'Fabhind'
     and status in ('resolved', 'closed');
end $$;


-- created_by bhi set karte hain. Ye tickets kisi customer ne nahi
-- bheje, andar se daale gaye hain — aur UI isi field se tay karta hai
-- ki "From" me email dikhaye ya "Internal".
update public.tickets t
   set created_by = p.id
  from public.profiles p
 where p.email = t.raised_by_email
   and t.created_by is null;


-- ---------------------------------------------------------------- check
select company_name,
       count(*) as tickets,
       count(*) filter (where status = 'resolved') as resolved,
       count(*) filter (where status = 'closed')   as closed,
       count(*) filter (where status = 'open')     as open,
       count(assigned_to) as assigned
  from public.tickets
 group by company_name
 order by company_name;
