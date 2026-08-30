-- =====================================================================
-- Delete kiye hue accounts ka record.
--
-- Supabase -> SQL Editor me chalaiye. Dobara chalana safe hai.
-- =====================================================================
--
-- Delete karte hi abhi saara nishaan mit jaata hai: profiles ki row
-- auth.users ke saath cascade ho jaati hai, aur tickets par uska id
-- null ho jaata hai. Baad me ye poochhna hi namumkin ho jaata hai ki
-- "AG-03 kaun tha aur kab hataya gaya".
--
-- Isliye mitane se PEHLE uski jaankari yahan copy hoti hai.

create table if not exists public.deleted_accounts (
  id             uuid primary key,          -- wahi id jo profile ki thi
  email          text not null,
  full_name      text,
  agent_code     text,
  kind           text,
  specialization text,
  -- Kitna kaam kiya tha — baad me "is ID ne kitne ticket niptaaye the"
  -- ka jawab dene ke liye. Ye ginti delete ke baad nahi nikal sakti,
  -- kyunki tickets par uska id null ho chuka hota hai.
  resolved_count int not null default 0,
  deleted_at     timestamptz not null default now(),
  deleted_by     uuid references public.profiles(id) on delete set null,
  -- deleted_by ka profile bhi kabhi mit sakta hai, isliye uska naam
  -- yahan alag se likh lete hain.
  deleted_by_label text
);

create index if not exists deleted_accounts_at_idx
  on public.deleted_accounts(deleted_at desc);

alter table public.deleted_accounts enable row level security;

-- Sirf admin. Isme email aur naam hain — wahi cheezein jo agents se
-- chhupayi jaati hain.
drop policy if exists deleted_accounts_admin_read on public.deleted_accounts;
create policy deleted_accounts_admin_read on public.deleted_accounts
  for select using (public.is_admin_user());

-- Likhna sirf Edge Function karta hai (service_role se), isliye yahan
-- koi insert policy nahi. service_role RLS ke bahar hai.
--
-- Delete ki bhi koi policy nahi — ye record mitaya nahi jaana chahiye.
-- Yahi to uska poora maqsad hai.


select count(*) as ab_tak_delete_kiye from public.deleted_accounts;
