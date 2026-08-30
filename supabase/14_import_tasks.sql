-- =====================================================================
-- Purane IT tasks ko tickets me daalna (64 rows).
--
-- Supabase -> SQL Editor me chalaiye.
--
-- DHYAN: ye script DOBARA chalane par ye 64 tickets DOBARA ban jayenge.
-- Ek hi baar chalaiye. Galti se do baar chal jaye to neeche wala
-- delete chala kar saaf kar sakte hain (poori file me sabse aakhir me).
-- =====================================================================

-- Due date ka column tha hi nahi — pehle wo banate hain.
alter table public.tickets
  add column if not exists due_date date;


-- Aapke kahe mutabik:
--   priority      = high   (sabhi)
--   status        = open   (sabhi — kisi row me status tha hi nahi)
--   assigned_to   = null   (kisi ko assign nahi)
--   resolved_at   = null   (koi closing date nahi)
--   working engineer wala column chhod diya
--   raised_by_email = aapka apna account
--
-- NOTE: raised_by_email khali nahi chhod sakte (column NOT NULL hai), aur
-- yahi field customer ki pehchaan hai. Aapka account daalne se ye saare
-- ticket aapke naam par aayenge — jo theek hai, kyunki ye internal tasks
-- hain, kisi customer ke bheje hue nahi.
insert into public.tickets
  (subject, company_name, priority, status, raised_by_email, created_at, due_date)
values
  ('Change All Server Passwords', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Make Another Account In Physical Server And VM With Administrator Rights', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Local System VM Also Have Two Admin AC', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('GPO Standardlization', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('TightVnc In All Systems', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Check Server Health', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Server Restore Point', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Baremetal Backup', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Change Documentation', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Check Shadow Copy Enable Or Not', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Check AV In All Server', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('AD Recyclebeen', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Export User List', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Change All Server Passwords', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Make Another Account In Physical Server And VM With Administrator Rights', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Local System VM Also Have Two Admin AC', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('GPO Standardlization', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('TightVnc In All Systems', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Check Server Health', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Server Restore Point', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Baremetal Backup', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Change Documentation', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Check Shadow Copy Enable Or Not', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Check AV In All Server', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('AD Recyclebeen', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Export User List', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Change All Server Passwords', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Make Another Account In Physical Server And VM With Administrator Rights', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Local System VM Also Have Two Admin AC', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('GPO Standardlization', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('TightVnc In All Systems', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Check Server Health', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Server Restore Point', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Baremetal Backup', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Change Documentation', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Check Shadow Copy Enable Or Not', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Check AV In All Server', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('AD Recyclebeen', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Export User List', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Change All Server Passwords', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Make Another Account In Physical Server And VM With Administrator Rights', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Local System VM Also Have Two Admin AC', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('GPO Standardlization', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('TightVnc In All Systems', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Check Server Health', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Server Restore Point', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Baremetal Backup', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Change Documentation', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Check Shadow Copy Enable Or Not', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Check AV In All Server', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('AD Recyclebeen', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Export User List', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Change All Server Passwords', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Make Another Account In Physical Server And VM With Administrator Rights', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Local System VM Also Have Two Admin AC', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('GPO Standardlization', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('TightVnc In All Systems', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Check Server Health', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Server Restore Point', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Baremetal Backup', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Change Documentation', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Check Shadow Copy Enable Or Not', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Check AV In All Server', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('AD Recyclebeen', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date);


select count(*) as inserted_now from public.tickets
 where raised_by_email = 'vahorajuned858@gmail.com';

-- Galti se do baar chal gaya to ye chalaiye (sab hata dega):
--   delete from public.tickets where raised_by_email = 'vahorajuned858@gmail.com';
