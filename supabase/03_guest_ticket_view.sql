-- =====================================================================
-- Guest apna ticket dekhe aur jawab de — bina login.
--
-- Supabase -> SQL Editor me chalaiye. Dobara chalana safe hai.
-- =====================================================================

-- Guest ke paas `tickets` par koi permission nahi hai (aur nahi honi chahiye).
-- Isliye ye SECURITY DEFINER function, jo sirf public_token se kaam karta hai.
--
-- public_token ek random uuid hai. Ise guess nahi kiya ja sakta, aur ye
-- sirf ticket banane wale ko mila tha — yahi uska "password" hai.
create or replace function public.get_guest_ticket(p_token uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_ticket  public.tickets;
  v_msgs    jsonb;
begin
  select * into v_ticket from public.tickets where public_token = p_token;
  if not found then
    return null;
  end if;

  -- is_internal wale messages KABHI bahar nahi jaane chahiye.
  -- Ye filter yahan hai (client par nahi) — client ka filter bypass ho
  -- sakta hai, database ka nahi.
  select coalesce(jsonb_agg(m order by m.created_at), '[]'::jsonb)
    into v_msgs
    from (
      select body, author_name, created_at
        from public.ticket_messages
       where ticket_id = v_ticket.id
         and is_internal = false
    ) m;

  -- Sirf wahi fields bahar bhej rahe hain jo customer ko dikhne chahiye.
  -- assigned_to, organization_id waghera jaan-boojh kar chhod diye.
  return jsonb_build_object(
    'id',           v_ticket.id,
    'subject',      v_ticket.subject,
    'description',  v_ticket.description,
    'status',       v_ticket.status,
    'priority',     v_ticket.priority,
    'contact_name', v_ticket.contact_name,
    'company_name', v_ticket.company_name,
    'created_at',   v_ticket.created_at,
    'messages',     v_msgs
  );
end;
$$;

revoke all on function public.get_guest_ticket(uuid) from public;
grant execute on function public.get_guest_ticket(uuid) to anon, authenticated;


-- Guest apne ticket par jawab de sake.
create or replace function public.add_guest_reply(p_token uuid, p_body text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_ticket public.tickets;
begin
  if coalesce(trim(p_body), '') = '' then
    raise exception 'Message cannot be empty';
  end if;
  if length(p_body) > 5000 then
    raise exception 'Message is too long';
  end if;

  select * into v_ticket from public.tickets where public_token = p_token;
  if not found then
    raise exception 'Ticket not found';
  end if;

  -- Band ticket par jawab dene se wo dobara khul jaata hai. Warna customer
  -- likhta rehta aur kisi agent ki nazar hi nahi padti.
  insert into public.ticket_messages
    (ticket_id, author_email, author_name, body, is_internal)
  values
    (v_ticket.id, v_ticket.raised_by_email,
     coalesce(v_ticket.contact_name, v_ticket.raised_by_email),
     trim(p_body), false);

  update public.tickets
     set status = 'open'
   where id = v_ticket.id
     and status in ('replied', 'resolved', 'closed');

  return true;
end;
$$;

revoke all on function public.add_guest_reply(uuid, text) from public;
grant execute on function public.add_guest_reply(uuid, text) to anon, authenticated;
