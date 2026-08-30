-- =====================================================================
-- Logo ke liye storage bucket.
--
-- Ye 05a se ALAG isliye hai: storage.objects par policy banane ke liye
-- kabhi-kabhi permission nahi hoti, aur Supabase SQL Editor poori script
-- ek saath chalata hai — ek statement fail hua to TABLE BANNA BHI undo
-- ho jaata hai. Alag rakhne se wo problem nahi hoti.
--
-- Agar yahan "must be owner of table objects" jaisi error aaye, to
-- ghabraiye mat: bucket Dashboard se bhi bana sakte hain
-- (Storage -> New bucket -> naam "branding", Public ON).
-- =====================================================================
-- ---------------------------------------------------------------- storage
-- Logo ke liye bucket. public = true, kyunki logo guest form par bina
-- login ke dikhna hai.
insert into storage.buckets (id, name, public)
values ('branding', 'branding', true)
on conflict (id) do nothing;

-- Padhna sabke liye.
drop policy if exists "branding public read" on storage.objects;
create policy "branding public read" on storage.objects
  for select using (bucket_id = 'branding');

-- Upload/badalna/hataana sirf settings badalne wale ko.
-- Teeno alag policies isliye ki Postgres me ek policy ek hi command
-- ke liye hoti hai — "for all" likhte to anon ko bhi lag jaati.
drop policy if exists "branding upload" on storage.objects;
create policy "branding upload" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'branding' and public.has_perm('can_change_settings'));

drop policy if exists "branding update" on storage.objects;
create policy "branding update" on storage.objects
  for update to authenticated
  using (bucket_id = 'branding' and public.has_perm('can_change_settings'));

drop policy if exists "branding delete" on storage.objects;
create policy "branding delete" on storage.objects
  for delete to authenticated
  using (bucket_id = 'branding' and public.has_perm('can_change_settings'));


select * from public.site_settings;
