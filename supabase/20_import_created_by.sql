-- =====================================================================
-- Import kiye hue tickets par created_by set karna.
--
-- Supabase -> SQL Editor me chalaiye. Dobara chalana safe hai.
-- =====================================================================
--
-- Import script me created_by chhoot gaya tha, to wo null pada hai.
--
-- Uska nateeja UI me dikhta hai: dashboard ke "From" column me un
-- tickets par raised_by_email chhapta hai — yani ek hi email 77 baar.
-- Wo email sirf isliye pada tha ki column NOT NULL hai, kisi ne wo
-- ticket bheja nahi tha.
--
-- created_by set hote hi UI unhe "Internal" dikhane lagega, jo sach hai:
-- ye tickets bahar se nahi aaye, andar se banaye gaye hain.

do $$
declare
  v_admin uuid;
begin
  -- Wahi banda jiska email in tickets par pada hai — usi ne ye daale the.
  select p.id into v_admin
    from public.profiles p
   where p.email = 'vahorajuned858@gmail.com'
   limit 1;

  if v_admin is null then
    raise exception 'vahorajuned858@gmail.com naam ka koi profile nahi mila.';
  end if;

  update public.tickets
     set created_by = v_admin
   where created_by is null
     and raised_by_email = 'vahorajuned858@gmail.com';
end $$;


select count(*) filter (where created_by is null)     as bina_creator,
       count(*) filter (where created_by is not null) as creator_ke_saath
  from public.tickets;
