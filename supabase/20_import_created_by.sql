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

-- Pehle yahan email hardcoded thi. Wo galat nikla: 23 chalne ke baad wo
-- purana pata database me bachta hi nahi, aur ye script "koi profile nahi
-- mila" bolkar ruk jaati thi.
--
-- Ab pehchaan email se nahi, RISHTE se hoti hai: jis ticket ka from-pata
-- kisi admin/agent ka apna email hai, wo ticket usi ne andar se banayi
-- thi. Guest tickets chhoot jaati hain kyunki guest staff nahi hota —
-- aur unpar created_by lagana galat bhi hota, wo sach me bahar se aayi
-- hain.
update public.tickets t
   set created_by = p.id
  from public.profiles p
 where t.created_by is null
   and p.kind in ('admin', 'agent')
   and lower(t.raised_by_email) = lower(p.email);


select count(*) filter (where created_by is null)     as bina_creator,
       count(*) filter (where created_by is not null) as creator_ke_saath
  from public.tickets;
