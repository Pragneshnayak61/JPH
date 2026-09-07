-- =====================================================================
-- Operations — remark mitaya nahi ja sakta tha
--
-- Supabase -> SQL Editor me chalaiye. Dobara chalana safe hai.
-- 29 PEHLE chal chuki honi chahiye. 35 (tests) ISKE BAAD chalaiye.
-- =====================================================================
--
-- KYA GALAT THA
--
-- ops_complete() me remarks aise lagti thi:
--
--     remarks = coalesce(nullif(trim(p_remarks), ''), remarks)
--
-- Iska matlab: khaali remark bheji to purani remark bani rehti thi.
-- Yaani ek baar likhi hui baat kabhi mitayi hi nahi ja sakti thi.
--
-- Ye sirf takleef ki baat nahi hai, record jhooth bolne lagta hai. Aaj
-- backup fail hua, aadmi ne likha "repository out of space", ticket
-- banayi, masla theek kiya, aur wahi jaanch ko completed kar diya —
-- remark box khaali kar ke. Remark phir bhi wahin chipki rehti thi.
-- Report me wo row aage se aisi dikhti: "completed — repository out of
-- space". Padhne wala samjhega backup abhi bhi tuta hua hai.
--
-- SUDHAR
--
-- Do alag baatein ab alag maani jaati hain:
--
--   p_remarks NULL   -> "maine remark chhui hi nahi" -> purani rehne do
--   p_remarks ''     -> "maine mita di"              -> mita do
--
-- Ye farq isliye zaroori hai ki checklist par ek-click wala "ho gaya"
-- p_remarks bhejta hi nahi (NULL jaata hai). Agar NULL ka matlab bhi
-- "mita do" kar dete, to ek click me aadmi ki likhi hui baat ud jaati.
--
-- Baaki poora function jaisa tha waisa hi hai.


create or replace function public.ops_complete(
  p_execution_id bigint,
  p_status       ops_status,
  p_remarks      text default null
)
returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare
  v_task   public.ops_client_tasks;
  v_exec   public.ops_task_executions;
  v_ticket bigint;
begin
  if not public.ops_can_read() then
    raise exception 'Not allowed';
  end if;

  if p_status = 'pending' then
    -- 'pending' par wapas jaana matlab "maine kuch nahi kiya". Us soorat
    -- me kisne kiya wo bhi mitna chahiye, warna record jhooth bolta hai.
    update public.ops_task_executions
       set status       = 'pending',
           remarks      = nullif(trim(p_remarks), ''),
           performed_by = null,
           performed_at = null
     where id = p_execution_id
    returning * into v_exec;
  else
    update public.ops_task_executions
       set status       = p_status,
           -- NULL = chhui nahi, '' = mita di. Dekhiye upar wali wajah.
           remarks      = case
                            when p_remarks is null then remarks
                            else nullif(trim(p_remarks), '')
                          end,
           performed_by = auth.uid(),
           performed_at = now()
     where id = p_execution_id
    returning * into v_exec;
  end if;

  if not found then
    raise exception 'That check was not found';
  end if;

  -- Apne aap ticket — sirf tab jab is task par saaf-saaf chalu ki gayi
  -- ho. Default false hai aur aise hi rehni chahiye jab tak haath se
  -- banane ka tajurba na ho jaye.
  if p_status = 'failed' and v_exec.ticket_id is null then
    select * into v_task from public.ops_client_tasks
     where id = v_exec.client_task_id;
    if v_task.auto_ticket_on_fail then
      v_ticket := public.ops_ticket_for_execution(p_execution_id, null);
    end if;
  end if;

  return v_exec.id;
end;
$$;

revoke all on function public.ops_complete(bigint, ops_status, text) from public;
grant execute on function public.ops_complete(bigint, ops_status, text) to authenticated;


-- ---------------------------------------------------------------- check

-- Ye function ops_can_read() maangta hai, aur SQL Editor bina JWT ke
-- chalta hai — isliye yahan bulana nahi chahiye, warna 'Not allowed'
-- poori script wapas kar dega (wahi galti jo 29 me hui thi).
--
-- Jaanch 35_ops_tests.sql me hai (test 15). Wo ISKE BAAD chalaiye.

select 'ops_complete badal gaya' as kaam,
       (select count(*) from pg_proc f
          join pg_namespace n on n.oid = f.pronamespace
         where n.nspname = 'public' and f.proname = 'ops_complete') as kitne;
