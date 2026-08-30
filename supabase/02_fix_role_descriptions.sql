-- Roles ke descriptions Hinglish me the aur wo screen par dikhte hain.
-- 01_schema.sql me theek kar diya, par jo rows PEHLE se ban chuki hain
-- unhe ye alag se update karna padta hai (insert ... on conflict do nothing
-- purani rows ko chhoota nahi).
--
-- Supabase -> SQL Editor me chalaiye.

update public.roles set description = 'Can do everything'
 where name = 'Administrator';

update public.roles set description = 'Can see and reply to every ticket'
 where name = 'Agent';

update public.roles set description = 'Can only see tickets assigned to them'
 where name = 'Junior Agent';

select name, description from public.roles order by name;
