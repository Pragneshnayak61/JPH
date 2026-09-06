-- =====================================================================
-- Operations — DEMO DATA (dekhne aur chala kar samajhne ke liye)
--
-- Supabase -> SQL Editor me chalaiye. Dobara chalana safe hai.
-- 27 se 31 tak PEHLE chal chuki honi chahiye.
-- =====================================================================
--
-- YE ASLI DATA NAHI HAI
--
-- Teen naqli client, unke devices, unki alag-alag checklists, aur
-- pichhle 14 din ki history. Maqsad sirf itna ki khali page ke bajaye
-- aap bhara hua system dekh sakein — dashboard me ginti, history me
-- pichhli tareekhein, aur report me kuch.
--
-- HAR DEMO CHEEZ KA NAAM "Demo · " se shuru hota hai. Isi se ye pehchani
-- jaati hai, aur isi se poori hataayi ja sakti hai (file ke aakhir me
-- hatane wala hissa likha hai).
--
-- Aapke apne client, ticket, user — kisi ko haath nahi lagta.
--
-- TEEN CLIENT JAAN-BOOJH KAR ALAG RAKHE HAIN
--
--   Alpha  — Active Directory + VMware + backup
--   Beta   — ek akela server + firewall + CCTV
--   Gamma  — Hyper-V + SQL + VPN
--
-- Yahi wo baat hai jo aapne khaas taur par kahi thi: har client ki list
-- ek jaisi nahi honi chahiye. Ye teen us baat ko chala kar dikhate hain.


-- ---------------------------------------------------------------- 1/5
-- Clients

insert into public.organizations (name, email_domain) values
  ('Demo · Alpha Textiles',  'demo-alpha.example'),
  ('Demo · Beta Logistics',  'demo-beta.example'),
  ('Demo · Gamma Hospital',  'demo-gamma.example')
on conflict (name) do nothing;


-- ---------------------------------------------------------------- 2/5
-- Devices
--
-- Teeno ka setup alag. Beta ke paas AD hai hi nahi, Gamma ke paas CCTV
-- nahi — aur yahi asli zindagi me hota hai.

with d(client, name, kind, hostname, ip, location) as (
  values
  ('Demo · Alpha Textiles', 'DC01',          'server',   'dc01.alpha.local',   '10.10.1.10',  'Head office'),
  ('Demo · Alpha Textiles', 'ESXi-01',       'server',   'esxi01.alpha.local', '10.10.1.20',  'Head office'),
  ('Demo · Alpha Textiles', 'VEEAM01',       'backup',   'veeam.alpha.local',  '10.10.1.30',  'Head office'),
  ('Demo · Beta Logistics', 'SRV-BETA',      'server',   'srv.beta.local',     '192.168.5.10','Warehouse'),
  ('Demo · Beta Logistics', 'FortiGate-60F', 'firewall', null,                 '192.168.5.1', 'Warehouse'),
  ('Demo · Beta Logistics', 'NVR-01',        'cctv',     null,                 '192.168.5.60','Gate'),
  ('Demo · Gamma Hospital', 'HV-01',         'server',   'hv01.gamma.local',   '172.16.2.10', 'Server room'),
  ('Demo · Gamma Hospital', 'SQL-01',        'application','sql01.gamma.local','172.16.2.20', 'Server room'),
  ('Demo · Gamma Hospital', 'FG-100F',       'firewall', null,                 '172.16.2.1',  'Server room')
)
insert into public.ops_devices (organization_id, name, kind, hostname, ip_address, location)
select o.id, d.name, d.kind::ops_device_kind, d.hostname, d.ip, d.location
  from d join public.organizations o on o.name = d.client
on conflict (organization_id, name) do nothing;


-- ---------------------------------------------------------------- 3/5
-- Har client ki apni checklist
--
-- Library (28_ops_seed.sql) se naam se milaan kar rahe hain. Naam COPY ho
-- kar jaata hai, join nahi hota — wahi baat jo app ka "Add from library"
-- karta hai.
--
-- created_at 30 din peechhe rakh rahe hain. Iske bina generator purani
-- tareekhon ki rows banata hi nahi (wo jaan-boojh kar aisa hai, taaki
-- aaj bani jaanch ka pichhla hafta jhooth-much "pending" na dikhe) —
-- aur demo ki history khali reh jaati.

with wanted(client, task, freq, device) as (
  values
  -- Alpha — AD wala setup
  ('Demo · Alpha Textiles', 'Server availability',    'daily',   'DC01'),
  ('Demo · Alpha Textiles', 'Disk space',             'daily',   'DC01'),
  ('Demo · Alpha Textiles', 'Domain Controller health','daily',  'DC01'),
  ('Demo · Alpha Textiles', 'AD replication',         'daily',   'DC01'),
  ('Demo · Alpha Textiles', 'Backup job status',      'daily',   'VEEAM01'),
  ('Demo · Alpha Textiles', 'Restore test',           'monthly', 'VEEAM01'),
  -- Beta — akela server, firewall, camera
  ('Demo · Beta Logistics', 'Server availability',    'daily',   'SRV-BETA'),
  ('Demo · Beta Logistics', 'Disk space',             'daily',   'SRV-BETA'),
  ('Demo · Beta Logistics', 'Firewall',               'daily',   'FortiGate-60F'),
  ('Demo · Beta Logistics', 'CCTV/NVR',               'daily',   'NVR-01'),
  ('Demo · Beta Logistics', 'Backup job status',      'daily',   'SRV-BETA'),
  ('Demo · Beta Logistics', 'Licenses/expiry',        'monthly', null),
  -- Gamma — Hyper-V, SQL, VPN
  ('Demo · Gamma Hospital', 'Server availability',    'daily',   'HV-01'),
  ('Demo · Gamma Hospital', 'Database services',      'daily',   'SQL-01'),
  ('Demo · Gamma Hospital', 'Backup job status',      'daily',   'HV-01'),
  ('Demo · Gamma Hospital', 'VPN',                    'daily',   'FG-100F'),
  ('Demo · Gamma Hospital', 'Security alerts',        'weekly',  'FG-100F')
)
insert into public.ops_client_tasks (
  organization_id, catalog_id, category_id, device_id,
  name, description, instructions, frequency, priority, assigned_to, created_at
)
select o.id,
       cat.id,
       cat.category_id,
       dev.id,
       cat.name,
       cat.description,
       cat.default_instructions,
       w.freq::ops_frequency,
       case when cat.name in ('Backup job status', 'Server availability')
            then 'high'::ticket_priority else 'medium'::ticket_priority end,
       -- Jo bhi staff maujood ho, usi ko de dete hain. Koi na ho to khali.
       (select p.id from public.profiles p
         where p.is_active and p.kind in ('admin', 'agent')
         order by p.created_at limit 1),
       now() - interval '30 days'
  from wanted w
  join public.organizations   o   on o.name = w.client
  join public.ops_task_catalog cat on cat.name = w.task
  left join public.ops_devices dev
         on dev.organization_id = o.id and dev.name = w.device
 where not exists (
   select 1 from public.ops_client_tasks t
    where t.organization_id = o.id and t.name = cat.name
 );


-- ---------------------------------------------------------------- 4/5
-- Pichhle 14 din ki history
--
-- Rows wahi generator banata hai jo asli me roz chalta hai — demo ke liye
-- alag raasta nahi. Isse ye bhi tasalli ho jaati hai ki generator sach me
-- kaam kar raha hai.

select public.ops_generate_due(current_date, 14) as demo_rows_bani;

-- Ab in par nateeje bharte hain.
--
-- random() JAAN-BOOJH KAR NAHI use kiya. Har baar chalane par alag
-- nateeje aate, aur "kal ye pass tha, aaj fail" wala confusion banta.
-- id ke remainder se pattern banta hai — wahi rows hamesha wahi nateeja
-- dikhati hain.
--
-- Sirf PENDING rows chhui ja rahi hain, taaki aapne jo haath se bharaa
-- ho wo na badle.

update public.ops_task_executions e
   set status = case
                  when e.id % 23 = 0 then 'failed'::ops_status
                  when e.id % 11 = 0 then 'attention'::ops_status
                  when e.id % 31 = 0 then 'skipped'::ops_status
                  else 'completed'::ops_status
                end,
       remarks = case
                   when e.id % 23 = 0 then 'Job failed — repository out of space'
                   when e.id % 11 = 0 then 'Disk at 86% — watching it'
                   when e.id % 31 = 0 then 'Server was down for maintenance'
                   else null
                 end,
       performed_by = (select p.id from public.profiles p
                        where p.is_active and p.kind in ('admin', 'agent')
                        order by p.created_at limit 1),
       performed_at = e.due_date + time '09:20'
  from public.ops_client_tasks t
  join public.organizations o on o.id = t.organization_id
 where t.id = e.client_task_id
   and o.name like 'Demo · %'
   and e.due_date < current_date
   and e.status = 'pending';

-- AAJ ka din jaan-boojh kar aadha chhoda hai — kuch ho chuka, kuch baaki.
-- Bhara hua din dekhne me achha lagta hai par usme kuch karne ko bachta
-- nahi; khali din se ye pata nahi chalta ki page bhara hua kaisa dikhta
-- hai.
update public.ops_task_executions e
   set status = 'completed'::ops_status,
       performed_by = (select p.id from public.profiles p
                        where p.is_active and p.kind in ('admin', 'agent')
                        order by p.created_at limit 1),
       performed_at = now() - interval '1 hour'
  from public.ops_client_tasks t
  join public.organizations o on o.id = t.organization_id
 where t.id = e.client_task_id
   and o.name like 'Demo · %'
   and e.due_date = current_date
   and e.status = 'pending'
   and e.id % 3 <> 0;   -- har teesri baaki chhod di

-- Ek fail hui jaanch par aaj ka masla bhi bana dete hain, taaki "Create
-- ticket" wala button khali na dikhe.
update public.ops_task_executions e
   set status = 'failed'::ops_status,
       remarks = 'Nightly-Full failed at 02:14 — repository out of space',
       performed_by = (select p.id from public.profiles p
                        where p.is_active and p.kind in ('admin', 'agent')
                        order by p.created_at limit 1),
       performed_at = now() - interval '2 hours'
 where e.id = (
   select e2.id
     from public.ops_task_executions e2
     join public.ops_client_tasks t on t.id = e2.client_task_id
     join public.organizations o on o.id = t.organization_id
    where o.name like 'Demo · %'
      and e2.due_date = current_date
      and t.name = 'Backup job status'
    order by o.name
    limit 1
 );


-- ---------------------------------------------------------------- 5/5
-- Kya bana, ek nazar me

select o.name as client,
       count(*) filter (where e.due_date = current_date) as aaj_ki_jaanch,
       count(*) filter (where e.due_date = current_date and e.status = 'completed') as aaj_poori,
       count(*) as kul_history
  from public.ops_task_executions e
  join public.organizations o on o.id = e.organization_id
 where o.name like 'Demo · %'
 group by o.name
 order by o.name;


-- =====================================================================
-- DEMO HATANE KA TAREEQA
--
-- Sab kuch mit jaata hai aur aapka apna data waise ka waisa rehta hai.
-- Kram zaroori hai: executions pehle, kyunki tasks par `on delete
-- restrict` laga hai (history galti se udayi na ja sake).
--
-- Neeche ka poora hissa uncomment kar ke chalaiye:
--
-- begin;
--
-- delete from public.ops_execution_files f
--  using public.ops_task_executions e, public.organizations o
--  where f.execution_id = e.id and o.id = e.organization_id
--    and o.name like 'Demo · %';
--
-- -- Demo se bani ticket bhi (agar aapne "Create ticket" dabaya ho).
-- delete from public.tickets t
--  using public.ops_task_executions e, public.organizations o
--  where t.id = e.ticket_id and o.id = e.organization_id
--    and o.name like 'Demo · %';
--
-- delete from public.ops_task_executions e
--  using public.organizations o
--  where o.id = e.organization_id and o.name like 'Demo · %';
--
-- delete from public.ops_client_tasks t
--  using public.organizations o
--  where o.id = t.organization_id and o.name like 'Demo · %';
--
-- delete from public.ops_devices d
--  using public.organizations o
--  where o.id = d.organization_id and o.name like 'Demo · %';
--
-- delete from public.organizations where name like 'Demo · %';
--
-- commit;
-- =====================================================================
