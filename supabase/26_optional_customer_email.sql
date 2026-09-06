-- =====================================================================
-- Staff khud ticket banaye to customer ka email zaroori na ho.
--
-- Supabase -> SQL Editor me chalaiye. Dobara chalana safe hai.
-- =====================================================================
--
-- KYA HO RAHA THA
--
-- tickets.raised_by_email par NOT NULL laga tha. Guest form ke liye wo
-- theek hai — wahan email ke bina ticket ka koi matlab hi nahi, uske
-- bina to customer ko uska apna link bhi nahi bheja ja sakta.
--
-- Par Dashboard ka "New ticket" bhi usi column me likhta hai. Aur wahan
-- aksar email hota hi nahi: kisi ne phone kiya, koi paas aakar bol gaya,
-- ya kaam andar ka hai jiska koi customer hai hi nahi. NOT NULL ki wajah
-- se staff ko kuch na kuch bharna padta tha — aksar apna hi email. Nateeja
-- Dashboard ke "From" column me ek hi pata 77 baar.
--
-- Ye jhoot data me baith jaata hai. Baad me koi "kis-kis customer ne
-- kitne ticket bheje" ginega to ye rows use galat jawab denge.
--
-- Isliye ab khali chhodna ALLOWED hai — aur khali ka matlab saaf hai:
-- is ticket ka koi bahar wala customer nahi.
--
-- GUEST FORM PAR KOI FARQ NAHI
--
-- create_guest_ticket() me email ki jaanch jaisi thi waisi hai. Wo raasta
-- bahar ke logon ke liye hai; unka email na ho to na ticket ka link ja
-- sakta hai, na jawab. Rok wahan wajib hai, isliye hataayi nahi.
--
-- Ye script sirf DATABASE ki rok hataati hai. App ki taraf Dashboard aur
-- TicketDetail dono ko khali email sambhalna aata hai (dekhiye
-- Dashboard.vue ka createTicket, aur TicketDetail ka reply box jo bata
-- deta hai ki jawab kahin nahi jaayega).


-- ---------------------------------------------------------------- 1/2
-- Rok hata do.

alter table public.tickets
  alter column raised_by_email drop not null;

-- Khali string aur NULL do alag cheezein ban jaayein, ye theek nahi.
-- Dono ka matlab ek hi hai — "email nahi hai" — par query me do alag
-- shakl. Jo pehle se '' pada ho use abhi NULL kar dete hain, aage se app
-- khud NULL bhejti hai.
update public.tickets
   set raised_by_email = null
 where trim(coalesce(raised_by_email, '')) = '';

-- lower(raised_by_email) wala index NULL ke saath theek chalta hai —
-- Postgres NULL ko index me rakhta hai aur usse koi lookup nahi bigadta.
-- Isliye use chhedne ki zaroorat nahi.


-- ---------------------------------------------------------------- 2/2
-- Check

-- Rok sach me hati (nullable 'YES' aana chahiye):
select column_name, is_nullable
  from information_schema.columns
 where table_schema = 'public'
   and table_name   = 'tickets'
   and column_name  = 'raised_by_email';

-- Kitne ticket bina email ke hain:
select count(*) filter (where raised_by_email is null) as bina_email,
       count(*) filter (where raised_by_email is not null) as email_ke_saath,
       count(*) as kul
  from public.tickets;

-- Guest form ki rok abhi bhi lagi honi chahiye. Ye chalana FAIL hona
-- chahiye ("Email sahi nahi hai") — agar chal gaya to kuch galat hai:
--
--   select public.create_guest_ticket('', 'test', 'test', null, null, 'medium');
