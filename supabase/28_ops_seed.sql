-- =====================================================================
-- Operations — categories aur task library ka seed data
--
-- Supabase -> SQL Editor me chalaiye. Dobara chalana safe hai.
-- 27_ops_schema.sql PEHLE chal chuki honi chahiye.
-- =====================================================================
--
-- Ye sirf LIBRARY bharta hai — kisi client ki checklist nahi banata.
-- Library ka matlab: ek baar likhi hui jaanchein, jinme se aap har client
-- ke liye chun kar uski apni list banate hain. Client A ko AD chahiye,
-- Client B ko CCTV — dono yahan se uthenge par ek doosre se juday
-- rahenge.
--
-- Kuch pasand na aaye to Setup page se badal dijiye, ya yahin naam badal
-- kar dobara chala dijiye. `on conflict do nothing` ki wajah se ye script
-- kabhi kisi maujooda row ko nahi chhedti — yani aapke apne jode hue
-- items surakshit hain.


-- ---------------------------------------------------------------- 1/2
-- Categories

insert into public.ops_categories (name, sort_order) values
  ('Server',            10),
  ('Active Directory',  20),
  ('Backup',            30),
  ('Network',           40),
  ('Security',          50),
  -- "Other" hamesha sabse neeche. Isi wajah se sort_order hai, warna
  -- alphabetical order isse beech me kahin daal deta.
  ('Other',            999)
on conflict (name) do nothing;


-- ---------------------------------------------------------------- 2/2
-- Task library
--
-- Category ka naam se milaan kar rahe hain, id se nahi — id har database
-- me alag hoti hai, naam wahi rehta hai. Isse ye script kisi bhi jagah
-- bina badle chal jaati hai.

with items(category, name, description, instructions, sort_order) as (
  values
  -- ---------------------------------------------------------- Server
  ('Server', 'Server availability',
   'Har server up hai aur network par pahunch me hai',
   'Ping ya monitoring dashboard se har server check kijiye. Koi down ho to turant Failed aur ticket.', 10),
  ('Server', 'CPU usage',
   'CPU load samanya hai',
   'Task Manager / monitoring me sustained load dekhiye. 80% se upar der tak rahe to Attention.', 20),
  ('Server', 'RAM usage',
   'Memory samanya hai',
   'Available memory dekhiye. 90% se upar ya swap chal raha ho to Attention.', 30),
  ('Server', 'Disk space',
   'Har drive par jagah bachi hai',
   'Har volume dekhiye. 85% se upar bhare par Attention, 95% par Failed.', 40),
  ('Server', 'Server uptime',
   'Bina bataye reboot to nahi hua',
   'Uptime dekhiye. Achanak kam uptime ka matlab hai koi reboot hua — Event Viewer se wajah dhoondhiye.', 50),
  ('Server', 'Windows Services',
   'Zaroori services chal rahi hain',
   'Automatic par lagi jo services band hain unhe dekhiye.', 60),
  ('Server', 'Event Viewer',
   'System aur Application log me nayi errors',
   'Pichhle 24 ghante ke Critical aur Error dekhiye. Naya pattern mile to Attention.', 70),
  ('Server', 'Windows Updates',
   'Update ki haalat',
   'Pending aur fail hue updates dekhiye. Security updates ko pehle rakhiye.', 80),

  -- ------------------------------------------------ Active Directory
  ('Active Directory', 'Domain Controller health',
   'DC theek chal raha hai',
   'dcdiag chalaiye. Koi bhi fail hua test Attention.', 10),
  ('Active Directory', 'AD replication',
   'DCs ke beech replication chal rahi hai',
   'repadmin /replsummary. Koi bhi failure Failed.', 20),
  ('Active Directory', 'DNS',
   'DNS jawab de raha hai',
   'Andar aur bahar ke naam resolve kar ke dekhiye. Stale records par nazar rakhiye.', 30),
  ('Active Directory', 'DHCP',
   'DHCP scope aur lease',
   'Scope me kitna bacha hai dekhiye. 85% se upar istemal ho to Attention.', 40),
  ('Active Directory', 'GPO',
   'Group Policy lag rahi hai',
   'gpresult se dekhiye ki policy sach me apply ho rahi hai. Naye/badle hue GPO note kijiye.', 50),
  ('Active Directory', 'User/account issues',
   'Account se judi shikayatein',
   'Nayi shikayatein, disable/expire hote accounts dekhiye.', 60),
  ('Active Directory', 'Locked accounts',
   'Lock hue accounts',
   'Lock hue accounts ki list dekhiye. Ek hi account baar-baar lock ho to wajah dhoondhiye.', 70),

  -- ---------------------------------------------------------- Backup
  ('Backup', 'Backup job status',
   'Raat ki backup jobs chali',
   'Backup console kholiye. Har job Success honi chahiye. Ek bhi fail ho to Failed aur ticket.', 10),
  ('Backup', 'Backup storage',
   'Repository me jagah bachi hai',
   'Repository ka free space dekhiye. 85% par Attention — bharne ke baad jobs chup-chaap fail hoti hain.', 20),
  ('Backup', 'Failed backup jobs',
   'Pichhle fail hue jobs',
   'Fail hue jobs ki wajah dekhiye aur dobara chalaiye.', 30),
  ('Backup', 'Backup verification',
   'Backup file sach me padhi ja sakti hai',
   'Verification / health check ka nateeja dekhiye. "Job chal gayi" aur "backup theek hai" do alag baatein hain.', 40),
  ('Backup', 'Restore test',
   'Restore karke dekha',
   'Ek file ya ek VM restore kar ke dekhiye. Bina restore test ke backup sirf ek umeed hai.', 50),
  ('Backup', 'Offsite/cloud backup',
   'Bahar ki copy sync ho rahi hai',
   'Offsite/cloud copy ka last sync time dekhiye. Peechhe reh gayi ho to Attention.', 60),

  -- --------------------------------------------------------- Network
  ('Network', 'Internet connectivity',
   'Internet chal raha hai',
   'Speed aur latency dekhiye. Do line hain to dono alag-alag.', 10),
  ('Network', 'Firewall',
   'Firewall theek haalat me hai',
   'Firewall ki haalat, license, aur alerts dekhiye.', 20),
  ('Network', 'Router/switch',
   'Network hardware theek hai',
   'Uptime, port errors aur temperature/alarm dekhiye.', 30),
  ('Network', 'VPN',
   'VPN chal raha hai',
   'Site-to-site tunnel up hain? Remote users connect ho pa rahe hain?', 40),
  ('Network', 'Network connectivity',
   'Andar ka network theek hai',
   'Zaroori raaste ping kar ke dekhiye — server, printer, branch office.', 50),

  -- -------------------------------------------------------- Security
  ('Security', 'Antivirus/EDR',
   'Har machine par protection chal raha hai',
   'Console me: kitne machine protected hain, definition kitni purani hai, koi machine chhoot to nahi rahi.', 10),
  ('Security', 'Security alerts',
   'Nayi security alerts',
   'Pichhle 24 ghante ke alerts dekhiye. Kuch bhi shaq wala mile to Attention aur ticket.', 20),
  ('Security', 'Failed login/lockout review',
   'Fail hue login',
   'Fail hue login aur lockout dekhiye. Ek hi source se bahut saare fail = Failed.', 30),
  ('Security', 'Firewall/security events',
   'Firewall ke security events',
   'Blocked attacks, IPS alerts, geo-block hits dekhiye.', 40),

  -- ----------------------------------------------------------- Other
  ('Other', 'CCTV/NVR',
   'Camera recording ho rahe hain',
   'NVR chal raha hai, saare camera online hain, aur recording ke din poore hain — teeno dekhiye.', 10),
  ('Other', 'Application services',
   'Client ki apni applications chal rahi hain',
   'Kaam ki applications kholkar dekhiye ki chal rahi hain.', 20),
  ('Other', 'Database services',
   'Database chal raha hai',
   'Service chalu hai, jagah bachi hai, aur DB ka apna backup ho raha hai.', 30),
  ('Other', 'Storage',
   'NAS/SAN theek hai',
   'Array ki haalat, fail hui disk, aur RAID rebuild dekhiye.', 40),
  ('Other', 'Licenses/expiry',
   'License khatam to nahi ho rahe',
   'Antivirus, firewall, backup, SSL certificate — agle 30 din me kya khatam ho raha hai.', 50),
  ('Other', 'Client-specific checks',
   'Is client ki apni khaas jaanch',
   'Client ki list ke hisaab se yahan likhiye.', 60)
)
insert into public.ops_task_catalog
  (category_id, name, description, default_instructions, sort_order)
select c.id, i.name, i.description, i.instructions, i.sort_order
  from items i
  join public.ops_categories c on c.name = i.category
on conflict (category_id, name) do nothing;


-- ---------------------------------------------------------------- check

-- Category ke hisaab se kitni jaanchein aayin:
select c.name as category, count(t.id) as kitni
  from public.ops_categories c
  left join public.ops_task_catalog t on t.category_id = c.id
 group by c.name, c.sort_order
 order by c.sort_order;

-- Kul milakar 36 aani chahiye:
select count(*) as kul_library_items from public.ops_task_catalog;
