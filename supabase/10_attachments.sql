-- =====================================================================
-- Ticket ke saath image upload (screenshot waghera).
--
-- Editor ka image button abhi "failed to upload" deta hai, kyunki
-- frappe-ui ka default upload Frappe ke server ko dhoondhta hai —
-- hamare paas wo hai hi nahi.
--
-- Supabase -> SQL Editor me chalaiye. Dobara chalana safe hai.
-- =====================================================================

-- Limits BUCKET par lagayi hain, sirf client par nahi.
-- Client wali rok koi bhi hata sakta hai (browser console se seedha
-- API call), server wali nahi.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'attachments', 'attachments', true,
  5242880,  -- 5 MB. Screenshot ke liye bahut, aur bada file bhejne se rokta hai.
  array['image/png','image/jpeg','image/gif','image/webp']
)
on conflict (id) do update
  set public = true,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;


-- Padhna sabke liye — image ticket me dikhni hai, aur customer bina
-- login apna ticket dekhta hai.
drop policy if exists "attachments public read" on storage.objects;
create policy "attachments public read" on storage.objects
  for select using (bucket_id = 'attachments');

-- Upload guest ko bhi karna hai (wo bina login ticket bhejta hai),
-- isliye anon ko bhi ijazat.
drop policy if exists "attachments upload" on storage.objects;
create policy "attachments upload" on storage.objects
  for insert to anon, authenticated
  with check (bucket_id = 'attachments');

-- Delete SIRF staff ko. Guest ko dete to koi doosron ki files mita
-- sakta tha — file ka naam mil jaana kaafi hota.
drop policy if exists "attachments delete" on storage.objects;
create policy "attachments delete" on storage.objects
  for delete to authenticated
  using (bucket_id = 'attachments' and public.is_staff());

-- Update bhi sirf staff ko, warna koi upload ki hui image badal sakta hai.
drop policy if exists "attachments update" on storage.objects;
create policy "attachments update" on storage.objects
  for update to authenticated
  using (bucket_id = 'attachments' and public.is_staff());


select id, public, file_size_limit, allowed_mime_types
  from storage.buckets where id = 'attachments';
