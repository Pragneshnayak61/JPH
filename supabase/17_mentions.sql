-- =====================================================================
-- @mention — internal note me kisi agent/admin ko tag karna.
--
-- Supabase -> SQL Editor me chalaiye. Dobara chalana safe hai.
-- =====================================================================

create table if not exists public.message_mentions (
  id           bigint primary key generated always as identity,
  message_id   bigint not null references public.ticket_messages(id) on delete cascade,
  ticket_id    bigint not null references public.tickets(id) on delete cascade,
  -- kise mention kiya
  profile_id   uuid not null references public.profiles(id) on delete cascade,
  -- kisne kiya
  mentioned_by uuid references public.profiles(id) on delete set null,
  -- padh liya ya nahi. Iske bina banda ko har baar poora ticket khol kar
  -- dhoondhna padta ki usse kaha kya gaya tha.
  read_at      timestamptz,
  created_at   timestamptz not null default now(),

  -- Ek hi message me kisi ko do baar mention karne ka koi matlab nahi.
  unique (message_id, profile_id)
);

create index if not exists mentions_profile_idx
  on public.message_mentions(profile_id, read_at);

alter table public.message_mentions enable row level security;

-- Mention internal notes par hote hain, aur wo sirf staff ke liye hain.
drop policy if exists mentions_staff_read on public.message_mentions;
create policy mentions_staff_read on public.message_mentions
  for select using (public.is_staff());

drop policy if exists mentions_staff_insert on public.message_mentions;
create policy mentions_staff_insert on public.message_mentions
  for insert with check (public.is_staff());

-- Padha hua nishaan sirf khud laga sakta hai. Bina is rok ke koi doosre
-- ka mention "padha hua" bana kar chhupa sakta tha.
drop policy if exists mentions_own_update on public.message_mentions;
create policy mentions_own_update on public.message_mentions
  for update using (profile_id = auth.uid())
  with check (profile_id = auth.uid());


-- Kitne mention baaki hain — sidebar par batti jalane ke liye.
create or replace function public.my_unread_mentions()
returns bigint
language sql
stable
security definer
set search_path = public
as $$
  select count(*) from public.message_mentions
   where profile_id = auth.uid() and read_at is null;
$$;

revoke all on function public.my_unread_mentions() from public;
grant execute on function public.my_unread_mentions() to authenticated;


-- Mere mentions ki list. Ticket ka subject saath me, warna banda ko
-- pata hi nahi chalta ki baat kis ticket ki ho rahi hai.
create or replace function public.my_mentions()
returns table (
  id           bigint,
  ticket_id    bigint,
  subject      text,
  body         text,
  by_label     text,
  read_at      timestamptz,
  created_at   timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.is_staff() then
    raise exception 'Not allowed';
  end if;

  return query
    select m.id, m.ticket_id, t.subject, msg.body,
           -- Wahi niyam: admin ko asli naam, agent ko sirf ID.
           case
             when public.is_admin_user()
               then coalesce(nullif(trim(p.full_name), ''), p.email)
             else coalesce(p.agent_code, 'Agent')
           end,
           m.read_at, m.created_at
      from public.message_mentions m
      join public.tickets t          on t.id = m.ticket_id
      join public.ticket_messages msg on msg.id = m.message_id
      left join public.profiles p    on p.id = m.mentioned_by
     where m.profile_id = auth.uid()
     order by m.created_at desc
     limit 50;
end;
$$;

revoke all on function public.my_mentions() from public;
grant execute on function public.my_mentions() to authenticated;
