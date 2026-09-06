-- =====================================================================
-- Operations — saboot (evidence) ke liye alag storage bucket
--
-- Supabase -> SQL Editor me chalaiye. Dobara chalana safe hai.
-- 27 PEHLE chal chuki honi chahiye (ops_can_read chahiye).
-- =====================================================================
--
-- MAUJOODA `attachments` BUCKET KYUN NAHI
--
-- Do wajah, aur dono zaroori hain:
--
--   1. Wo bucket PUBLIC hai. Uska URL jiske paas bhi aaya, wo file dekh
--      sakta hai — bina login. Ticket ke screenshot ke liye wo theek
--      hai (customer bina login apna ticket dekhta hai). Par backup
--      report aur firewall log me hostname, IP, user name aur network
--      ka naksha hota hai. Wo cheez URL guess karne par khul jaye, ye
--      nahi hona chahiye.
--
--   2. Usme sirf image allowed hai (png/jpeg/gif/webp). Aapko PDF
--      report, .log file aur CSV bhi lagani hai — wo bucket unhe seedha
--      reject kar deta.
--
-- Isliye alag bucket: PRIVATE, aur zyada file types.
--
-- Private ka matlab: file dikhane ke liye har baar signed URL banana
-- padta hai (`createSignedUrl`), jo thodi der me khud mar jaata hai. Isi
-- wajah se ops_execution_files me file_path alag se rakha hai — signed
-- URL banane ke liye path chahiye, URL se path nikaalna bharosemand
-- nahi hota.


-- ---------------------------------------------------------------- 1/3
-- Bucket
--
-- Limit bucket PAR lagi hai, sirf client par nahi. Client wali rok koi
-- bhi hata sakta hai (browser console se seedha API call), server wali
-- nahi. Yahi soch 10_attachments.sql me bhi likhi hai.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'ops-evidence', 'ops-evidence',
  false,      -- PRIVATE. Yahi is bucket ka asli maqsad hai.
  20971520,   -- 20 MB. Backup report aur log screenshot ke liye kaafi,
              -- aur poori log directory bhejne se rokta hai.
  array[
    -- screenshot
    'image/png', 'image/jpeg', 'image/gif', 'image/webp',
    -- report
    'application/pdf',
    -- log / export
    'text/plain', 'text/csv', 'application/json',
    -- kai log ek saath
    'application/zip', 'application/x-zip-compressed'
  ]
)
on conflict (id) do update
  set public             = false,
      file_size_limit    = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;


-- ---------------------------------------------------------------- 2/3
-- Policies
--
-- anon ke liye ek bhi policy NAHI. Bina login ke is bucket ka kuch bhi
-- nahi — na padhna, na likhna.

drop policy if exists "ops evidence read" on storage.objects;
create policy "ops evidence read" on storage.objects
  for select to authenticated
  using (bucket_id = 'ops-evidence' and public.ops_can_read());

drop policy if exists "ops evidence upload" on storage.objects;
create policy "ops evidence upload" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'ops-evidence' and public.ops_can_read());

-- Delete sirf manage wale ko.
--
-- Jaanch karne wale ko delete NAHI de rahe: saboot ka matlab hi tab hai
-- jab wo baad me mitaya na ja sake. Galat file chadh gayi ho to manage
-- wala hata dega.
drop policy if exists "ops evidence delete" on storage.objects;
create policy "ops evidence delete" on storage.objects
  for delete to authenticated
  using (bucket_id = 'ops-evidence' and public.ops_can_manage());

-- Update bhi manage wale ko hi, warna koi chadhi hui file badal sakta hai.
drop policy if exists "ops evidence update" on storage.objects;
create policy "ops evidence update" on storage.objects
  for update to authenticated
  using (bucket_id = 'ops-evidence' and public.ops_can_manage());


-- ---------------------------------------------------------------- 3/3
-- Purane `attachments` bucket ko HAATH NAHI LAGAYA
--
-- Us par ticket ke screenshot chal rahe hain aur customer bina login
-- unhe dekhta hai. Use private karne se aaj ke saare ticket ki images
-- toot jaatin. Do alag kaam, do alag bucket — yahi theek hai.


-- ---------------------------------------------------------------- check

-- Bucket ban gaya aur PRIVATE hai (public = false):
select id, public, file_size_limit, allowed_mime_types
  from storage.buckets
 where id in ('attachments', 'ops-evidence')
 order by id;

-- Policies lag gayin (4 rows):
select policyname, cmd
  from pg_policies
 where schemaname = 'storage' and tablename = 'objects'
   and policyname like 'ops evidence%'
 order by policyname;
