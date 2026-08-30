-- =====================================================================
-- Purane IT tasks ko tickets me daalna (64 rows).
--
-- Supabase -> SQL Editor me chalaiye.
--
-- DHYAN: ye script DOBARA chalane par ye 64 tickets DOBARA ban jayenge.
-- Ek hi baar chalaiye. Galti se do baar chal jaye to file ke aakhir me
-- diya delete chala kar saaf kar sakte hain.
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
--
-- Do column majboori se bhare hain, kyunki wo NOT NULL hain:
--   description     = task ka naam (usse alag koi vivran hai hi nahi)
--   raised_by_email = aapka apna account
-- Isse ye tickets aapke naam par aayenge — theek hai, kyunki ye internal
-- tasks hain, kisi customer ke bheje hue nahi.
insert into public.tickets
  (subject, description, company_name, priority, status, raised_by_email,
   created_at, due_date)
values
  ('Change All Server Passwords', 'Change All Server Passwords', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Make Another Account In Physical Server And VM With Administrator Rights', 'Make Another Account In Physical Server And VM With Administrator Rights', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Local System VM Also Have Two Admin AC', 'Local System VM Also Have Two Admin AC', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('GPO Standardlization', 'GPO Standardlization', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('TightVnc In All Systems', 'TightVnc In All Systems', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Check Server Health', 'Check Server Health', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Server Restore Point', 'Server Restore Point', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Baremetal Backup', 'Baremetal Backup', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Change Documentation', 'Change Documentation', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Check Shadow Copy Enable Or Not', 'Check Shadow Copy Enable Or Not', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Check AV In All Server', 'Check AV In All Server', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('AD Recyclebeen', 'AD Recyclebeen', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Export User List', 'Export User List', 'Leo', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Change All Server Passwords', 'Change All Server Passwords', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Make Another Account In Physical Server And VM With Administrator Rights', 'Make Another Account In Physical Server And VM With Administrator Rights', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Local System VM Also Have Two Admin AC', 'Local System VM Also Have Two Admin AC', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('GPO Standardlization', 'GPO Standardlization', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('TightVnc In All Systems', 'TightVnc In All Systems', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Check Server Health', 'Check Server Health', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Server Restore Point', 'Server Restore Point', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Baremetal Backup', 'Baremetal Backup', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Change Documentation', 'Change Documentation', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Check Shadow Copy Enable Or Not', 'Check Shadow Copy Enable Or Not', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Check AV In All Server', 'Check AV In All Server', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('AD Recyclebeen', 'AD Recyclebeen', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Export User List', 'Export User List', 'Connot', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Change All Server Passwords', 'Change All Server Passwords', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Make Another Account In Physical Server And VM With Administrator Rights', 'Make Another Account In Physical Server And VM With Administrator Rights', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Local System VM Also Have Two Admin AC', 'Local System VM Also Have Two Admin AC', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('GPO Standardlization', 'GPO Standardlization', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('TightVnc In All Systems', 'TightVnc In All Systems', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Check Server Health', 'Check Server Health', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Server Restore Point', 'Server Restore Point', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Baremetal Backup', 'Baremetal Backup', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Change Documentation', 'Change Documentation', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Check Shadow Copy Enable Or Not', 'Check Shadow Copy Enable Or Not', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Check AV In All Server', 'Check AV In All Server', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('AD Recyclebeen', 'AD Recyclebeen', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Export User List', 'Export User List', 'DLPL', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Change All Server Passwords', 'Change All Server Passwords', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Make Another Account In Physical Server And VM With Administrator Rights', 'Make Another Account In Physical Server And VM With Administrator Rights', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Local System VM Also Have Two Admin AC', 'Local System VM Also Have Two Admin AC', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('GPO Standardlization', 'GPO Standardlization', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('TightVnc In All Systems', 'TightVnc In All Systems', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Check Server Health', 'Check Server Health', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Server Restore Point', 'Server Restore Point', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Baremetal Backup', 'Baremetal Backup', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Change Documentation', 'Change Documentation', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Check Shadow Copy Enable Or Not', 'Check Shadow Copy Enable Or Not', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Check AV In All Server', 'Check AV In All Server', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('AD Recyclebeen', 'AD Recyclebeen', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Export User List', 'Export User List', 'ANO', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Change All Server Passwords', 'Change All Server Passwords', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Make Another Account In Physical Server And VM With Administrator Rights', 'Make Another Account In Physical Server And VM With Administrator Rights', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Local System VM Also Have Two Admin AC', 'Local System VM Also Have Two Admin AC', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('GPO Standardlization', 'GPO Standardlization', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('TightVnc In All Systems', 'TightVnc In All Systems', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Check Server Health', 'Check Server Health', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Server Restore Point', 'Server Restore Point', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Baremetal Backup', 'Baremetal Backup', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Change Documentation', 'Change Documentation', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Check Shadow Copy Enable Or Not', 'Check Shadow Copy Enable Or Not', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('Check AV In All Server', 'Check AV In All Server', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date),
  ('AD Recyclebeen', 'AD Recyclebeen', 'Fabhind', 'high', 'open', 'vahorajuned858@gmail.com', '2026-08-07'::timestamptz, '2026-08-16'::date);


select company_name, count(*) from public.tickets
 where raised_by_email = 'vahorajuned858@gmail.com'
 group by company_name order by company_name;

-- Galti se do baar chal gaya to ye chalaiye:
--   delete from public.tickets where raised_by_email = 'vahorajuned858@gmail.com';
