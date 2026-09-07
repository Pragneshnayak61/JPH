-- =====================================================================
-- Operations — khud ki jaanch
--
-- Supabase -> SQL Editor me chalaiye. Jitni baar chahe chalaiye.
-- 27 se 34 tak PEHLE chal chuki honi chahiye.
-- =====================================================================
--
-- YE SCRIPT KUCH BADALTI NAHI
--
-- Jahan test ke liye kuch banana ya mitana zaroori tha, wahan kaam kar
-- ke JAAN-BOOJH KAR ek error uthaya jaata hai — usse Postgres us hisse
-- ko wapas kar deta hai. Nateeja (PASS/FAIL) plpgsql ki memory me rehta
-- hai, isliye wo wapas nahi hota.
--
-- Sirf ek cheez sach me likhi jaati hai: test 6 me ops_generate_due()
-- chalti hai. Wo waise bhi roz chalti hai, aur agar kuch banati bhi hai
-- to sirf wo rows jo waise bhi banni thi.
--
-- ROLE BADAL KAR TEST KIYE GAYE HAIN
--
-- Asli sawal "kya customer ye dekh sakta hai" ka jawab postgres ban kar
-- nahi mil sakta — postgres RLS ko upar se kood jaata hai, isliye usse
-- sab kuch dikhta hai aur har test jhoothi PASS deta.
--
-- Isliye har permission test se pehle role `authenticated` kar diya
-- jaata hai aur JWT me us bande ki id daal di jaati hai. Tab auth.uid()
-- wahi lautata hai jo browser me lautata, aur RLS bilkul waise hi lagti
-- hai jaise asli app me.
--
-- JAHAN ACCOUNT NA MILE
--
-- Kuch test ke liye ek customer ya ek admin chahiye. Na mile to wo test
-- FAIL nahi, SKIP dikhata hai — bina account ke wo sawal poochha hi
-- nahi ja sakta, aur jhoothi PASS se SKIP behtar hai.


-- `on commit drop`: SQL Editor poori script ko ek hi transaction me
-- chalata hai, isliye ye table aakhri select ke waqt maujood hota hai
-- aur uske baad khud mit jaata hai. Peechhe kuch nahi chhutta.
create temp table _ops_test (
  n      int generated always as identity,
  naam   text,
  natija text,
  note   text
) on commit drop;

create or replace function pg_temp.rec(p_naam text, p_ok boolean, p_note text default '')
returns void language sql as $fn$
  insert into _ops_test (naam, natija, note)
  values (p_naam, case when p_ok then 'PASS' else 'FAIL' end, p_note);
$fn$;

create or replace function pg_temp.skip(p_naam text, p_why text)
returns void language sql as $fn$
  insert into _ops_test (naam, natija, note) values (p_naam, 'SKIP', p_why);
$fn$;


do $$
declare
  MARK constant text := 'OPS_TEST_ROLLBACK';

  v_admin uuid;
  v_cust  uuid;
  v_ok    boolean;
  v_note  text;
  v_n     int;
  v_n2    int;
  v_org   uuid;
  v_cat   uuid;
  v_task  uuid;
  v_exec  bigint;
  v_name  text;
  v_dow   int;
begin
  select id into v_admin from public.profiles
   where kind = 'admin' and is_active order by created_at limit 1;
  select id into v_cust from public.profiles
   where kind = 'customer' and is_active order by created_at limit 1;
  select id into v_cat from public.ops_categories order by sort_order limit 1;

  -- ================================================================ 1
  -- Customer ko operations ki rows dikhti hain?
  --
  -- Inme hostname aur IP tak pahunch hai. Ye sirf RLS rokti hai, aur RLS
  -- chup-chaap kaam karti hai — isliye ise haath se jaanchna zaroori hai.
  if v_cust is null then
    perform pg_temp.skip('1. Customer ko checklist ki rows nahi dikhti',
                         'koi customer account nahi mila');
  else
    begin
      perform set_config('role', 'authenticated', true);
      perform set_config('request.jwt.claims',
                         json_build_object('sub', v_cust::text,
                                           'role', 'authenticated')::text, true);
      select count(*) into v_n from public.ops_task_executions;
      v_ok := (v_n = 0);
      v_note := v_n || ' rows dikhi';
    exception when others then
      -- Table par pahunch hi na mile to wo bhi theek hai.
      v_ok := true;
      v_note := sqlerrm;
    end;
    perform set_config('role', 'none', true);
    perform set_config('request.jwt.claims', '', true);
    perform pg_temp.rec('1. Customer ko checklist ki rows nahi dikhti', v_ok, v_note);
  end if;

  -- ================================================================ 2
  -- ops_today() customer ke liye band hai?
  --
  -- RLS table par lagti hai, par ops_today() definer hai — wo RLS ke
  -- upar se chalta hai. Isliye uski apni rok alag se jaanchni padti hai.
  if v_cust is null then
    perform pg_temp.skip('2. ops_today() customer ko mana karta hai',
                         'koi customer account nahi mila');
  else
    begin
      perform set_config('role', 'authenticated', true);
      perform set_config('request.jwt.claims',
                         json_build_object('sub', v_cust::text,
                                           'role', 'authenticated')::text, true);
      perform public.ops_today(current_date);
      v_ok := false;
      v_note := 'chal gaya — rok nahi lagi';
    exception when others then
      v_ok := (sqlerrm = 'Not allowed');
      v_note := sqlerrm;
    end;
    perform set_config('role', 'none', true);
    perform set_config('request.jwt.claims', '', true);
    perform pg_temp.rec('2. ops_today() customer ko mana karta hai', v_ok, v_note);
  end if;

  -- ================================================================ 3
  -- ops_generate_due() customer ke liye band hai?
  if v_cust is null then
    perform pg_temp.skip('3. ops_generate_due() customer ko mana karta hai',
                         'koi customer account nahi mila');
  else
    begin
      perform set_config('role', 'authenticated', true);
      perform set_config('request.jwt.claims',
                         json_build_object('sub', v_cust::text,
                                           'role', 'authenticated')::text, true);
      perform public.ops_generate_due(current_date, 0);
      v_ok := false;
      v_note := 'chal gaya — rok nahi lagi';
    exception when others then
      v_ok := (sqlerrm = 'Not allowed');
      v_note := sqlerrm;
    end;
    perform set_config('role', 'none', true);
    perform set_config('request.jwt.claims', '', true);
    perform pg_temp.rec('3. ops_generate_due() customer ko mana karta hai', v_ok, v_note);
  end if;

  -- ================================================================ 4
  -- ...par cron ko wahi rok NAHI lagni chahiye
  --
  -- Ye test us jaal ke liye hai jisme 29 phansi thi. Cron bina JWT ke
  -- chalta hai; agar rok binaa shart lag jaye to job roz raat ko chup-
  -- chaap fail hoga aur kisi ko pata bhi nahi chalega.
  begin
    perform public.ops_generate_due(current_date, 0);
    v_ok := true;
    v_note := 'bina JWT ke chal gaya, jaisa cron chalata hai';
  exception when others then
    v_ok := false;
    v_note := 'CRON ROZ FAIL HOGA: ' || sqlerrm;
  end;
  perform pg_temp.rec('4. ops_generate_due() cron ke liye khula hai', v_ok, v_note);

  -- ================================================================ 5
  -- ops_ticket_source() customer ke liye band hai?
  if v_cust is null then
    perform pg_temp.skip('5. ops_ticket_source() customer ko mana karta hai',
                         'koi customer account nahi mila');
  else
    begin
      perform set_config('role', 'authenticated', true);
      perform set_config('request.jwt.claims',
                         json_build_object('sub', v_cust::text,
                                           'role', 'authenticated')::text, true);
      perform public.ops_ticket_source(1);
      v_ok := false;
      v_note := 'chal gaya — rok nahi lagi';
    exception when others then
      v_ok := (sqlerrm = 'Not allowed');
      v_note := sqlerrm;
    end;
    perform set_config('role', 'none', true);
    perform set_config('request.jwt.claims', '', true);
    perform pg_temp.rec('5. ops_ticket_source() customer ko mana karta hai', v_ok, v_note);
  end if;

  -- ================================================================ 6
  -- Duplicate ban sakte hain?
  --
  -- Poori do-parat wali design isi ek shart par khadi hai: cron aur app
  -- dono generate karte hain, aur ye tabhi safe hai jab doosri baar
  -- kuch na bane. Ye ek test us poore faisle ko jaanchta hai.
  v_n  := public.ops_generate_due(current_date, 7);
  v_n2 := public.ops_generate_due(current_date, 7);
  perform pg_temp.rec('6. Dobara generate karne par duplicate nahi bante',
                      v_n2 = 0,
                      'pehli baar ' || v_n || ', doosri baar ' || v_n2);

  -- ================================================================ 7
  -- Jis task ki history hai wo delete ho sakti hai?
  --
  -- Yahi wo cheez hai jise `on delete restrict` rokta hai. Ek galat
  -- click se mahino ka record nahi jaana chahiye.
  select t.id into v_task
    from public.ops_client_tasks t
   where exists (select 1 from public.ops_task_executions e
                  where e.client_task_id = t.id)
   limit 1;

  if v_task is null then
    perform pg_temp.skip('7. History wali task delete nahi hoti',
                         'abhi kisi task ki history hi nahi hai');
  else
    begin
      delete from public.ops_client_tasks where id = v_task;
      -- Yahan pahunch gaye matlab delete chal gayi. Ab jaan-boojh kar
      -- error uthate hain taaki wo delete wapas ho jaye.
      raise exception '%', MARK;
    exception when others then
      if sqlerrm = MARK then
        v_ok := false;
        v_note := 'delete ho gayi — history surakshit nahi hai';
      else
        v_ok := true;
        v_note := 'database ne roka (' || sqlstate || ')';
      end if;
    end;
    perform pg_temp.rec('7. History wali task delete nahi hoti', v_ok, v_note);
  end if;

  -- ================================================================ 8
  -- Task ka naam badalne par purani history ka naam badalta hai?
  --
  -- Har row apna naam khud sambhaal kar rakhti hai. Bina iske, naam
  -- badalte hi saal bhar purani report bhi naya naam bolne lagti — aur
  -- ye chup-chaap hota, kisi ko pata bhi nahi chalta.
  if v_task is null then
    perform pg_temp.skip('8. Naam badalne se purani history nahi badalti',
                         'abhi kisi task ki history hi nahi hai');
  else
    begin
      select task_name into v_name from public.ops_task_executions
       where client_task_id = v_task limit 1;

      update public.ops_client_tasks
         set name = 'ZZ badla hua naam'
       where id = v_task;

      select count(*) into v_n from public.ops_task_executions
       where client_task_id = v_task and task_name = 'ZZ badla hua naam';

      v_ok := (v_n = 0);
      v_note := 'purana naam: ' || coalesce(v_name, '—');
      raise exception '%', MARK;
    exception when others then
      if sqlerrm <> MARK then
        v_ok := false;
        v_note := sqlerrm;
      end if;
    end;
    perform pg_temp.rec('8. Naam badalne se purani history nahi badalti', v_ok, v_note);
  end if;

  -- ================================================================ 9
  -- Weekly jaanch sirf apne din banti hai?
  --
  -- Ek scratch client banate hain, uspar aaj ke din wali weekly task
  -- lagate hain, generator chalate hain aur ginti dekhte hain. 15 din
  -- (aaj se 14 din peechhe tak) me koi bhi ek weekday theek 3 baar aata
  -- hai — isliye jawab 3 hona chahiye, na kam na zyada.
  if v_cat is null then
    perform pg_temp.skip('9. Weekly jaanch sirf apne din banti hai',
                         'koi category nahi mili — 28 chalayi hai?');
  else
    v_dow := extract(dow from current_date)::int;
    begin
      insert into public.organizations (name) values ('ZZ ops self-test')
        returning id into v_org;

      insert into public.ops_client_tasks
        (organization_id, category_id, name, frequency, run_weekday, created_at)
      values (v_org, v_cat, 'ZZ weekly test', 'weekly', v_dow,
              now() - interval '30 days')
        returning id into v_task;

      perform public.ops_generate_due(current_date, 14);

      select count(*) into v_n from public.ops_task_executions
       where client_task_id = v_task;
      select count(*) into v_n2 from public.ops_task_executions
       where client_task_id = v_task
         and extract(dow from due_date)::int <> v_dow;

      v_ok := (v_n = 3 and v_n2 = 0);
      v_note := v_n || ' rows bani (3 chahiye), galat din par ' || v_n2;
      raise exception '%', MARK;
    exception when others then
      if sqlerrm <> MARK then
        v_ok := false;
        v_note := sqlerrm;
      end if;
    end;
    perform pg_temp.rec('9. Weekly jaanch sirf apne din banti hai', v_ok, v_note);
  end if;

  -- ================================================================ 10
  -- Aaj bani task ka pichhla hafta bhi ban jaata hai?
  --
  -- Nahi banna chahiye. Warna aaj ek nayi jaanch jodte hi pichhle hafte
  -- ki saat "pending" rows ban jaatin — jo kabhi hui hi nahi thi — aur
  -- report jhooth bolne lagti.
  if v_cat is null then
    perform pg_temp.skip('10. Aaj bani task ka pichhla hafta nahi banta',
                         'koi category nahi mili — 28 chalayi hai?');
  else
    begin
      insert into public.organizations (name) values ('ZZ ops self-test 2')
        returning id into v_org;

      insert into public.ops_client_tasks
        (organization_id, category_id, name, frequency, created_at)
      values (v_org, v_cat, 'ZZ daily test', 'daily', now())
        returning id into v_task;

      perform public.ops_generate_due(current_date, 7);

      select count(*) into v_n from public.ops_task_executions
       where client_task_id = v_task;

      v_ok := (v_n = 1);
      v_note := v_n || ' rows bani (sirf aaj ki, yaani 1 chahiye)';
      raise exception '%', MARK;
    exception when others then
      if sqlerrm <> MARK then
        v_ok := false;
        v_note := sqlerrm;
      end if;
    end;
    perform pg_temp.rec('10. Aaj bani task ka pichhla hafta nahi banta', v_ok, v_note);
  end if;

  -- ================================================================ 11
  -- ops_complete() performed_by khud lagata hai?
  --
  -- Kisne kiya, ye browser se aata to koi bhi kisi aur ka naam bhej
  -- sakta tha. Ye test wahi jaanchta hai: function ke paas kaun hai, ye
  -- sirf server ki JWT se aana chahiye.
  if v_admin is null then
    perform pg_temp.skip('11. ops_complete() performed_by server par lagta hai',
                         'koi admin account nahi mila');
  else
    select id into v_exec from public.ops_task_executions
     where status = 'pending' order by due_date desc limit 1;

    if v_exec is null then
      perform pg_temp.skip('11. ops_complete() performed_by server par lagta hai',
                           'koi pending jaanch nahi mili');
    else
      begin
        perform set_config('role', 'authenticated', true);
        perform set_config('request.jwt.claims',
                           json_build_object('sub', v_admin::text,
                                             'role', 'authenticated')::text, true);
        perform public.ops_complete(v_exec, 'completed'::ops_status, 'self-test');

        select count(*) into v_n from public.ops_task_executions
         where id = v_exec and performed_by = v_admin;

        v_ok := (v_n = 1);
        v_note := case when v_ok then 'sahi bande par laga'
                       else 'performed_by nahi laga' end;
        raise exception '%', MARK;
      exception when others then
        if sqlerrm <> MARK then
          v_ok := false;
          v_note := sqlerrm;
        end if;
      end;
      perform set_config('role', 'none', true);
      perform set_config('request.jwt.claims', '', true);
      perform pg_temp.rec('11. ops_complete() performed_by server par lagta hai',
                          v_ok, v_note);
    end if;
  end if;

  -- ================================================================ 12
  -- Report galat range par mana karti hai?
  if v_admin is null then
    perform pg_temp.skip('12. Report ulti tareekh par mana karti hai',
                         'koi admin account nahi mila');
  else
    begin
      perform set_config('role', 'authenticated', true);
      perform set_config('request.jwt.claims',
                         json_build_object('sub', v_admin::text,
                                           'role', 'authenticated')::text, true);
      perform public.ops_report(current_date, current_date - 5);
      v_ok := false;
      v_note := 'ulti range chal gayi';
    exception when others then
      v_ok := true;
      v_note := sqlerrm;
    end;
    perform set_config('role', 'none', true);
    perform set_config('request.jwt.claims', '', true);
    perform pg_temp.rec('12. Report ulti tareekh par mana karti hai', v_ok, v_note);
  end if;

  -- ================================================================ 13
  -- Kisi bhi label me naam ya email to nahi nikal raha?
  --
  -- Poori app me pehchaan chhupi rehni chahiye — admin se bhi. Ye test
  -- har profile ka label bana kar dekhta hai ki usme '@' hai ya nahi,
  -- aur wo full_name se to nahi mil raha.
  select count(*) into v_n
    from public.profiles p
   where public.ops_person_label(p.id) is not null
     and (public.ops_person_label(p.id) like '%@%'
          or public.ops_person_label(p.id) = nullif(trim(p.full_name), ''));

  perform pg_temp.rec('13. Kisi label me naam ya email nahi nikalta',
                      v_n = 0,
                      v_n || ' label me pehchaan dikhi');

  -- ================================================================ 14
  -- Report ke aankde asli rows se milte hain?
  --
  -- Report apna hisaab khud lagati hai. Agar wo kabhi asli ginti se hat
  -- jaye to koi shak nahi karega — report hamesha bharosemand DIKHTI
  -- hai. Isliye dono taraf se gin kar milaate hain.
  if v_admin is null then
    perform pg_temp.skip('14. ops_summary ki ginti asli rows se milti hai',
                         'koi admin account nahi mila');
  else
    begin
      perform set_config('role', 'authenticated', true);
      perform set_config('request.jwt.claims',
                         json_build_object('sub', v_admin::text,
                                           'role', 'authenticated')::text, true);
      select coalesce(sum(total), 0)::int into v_n
        from public.ops_summary(current_date);
    exception when others then
      v_n := -1;
      v_note := sqlerrm;
    end;
    perform set_config('role', 'none', true);
    perform set_config('request.jwt.claims', '', true);

    select count(*) into v_n2 from public.ops_task_executions
     where due_date = current_date;

    perform pg_temp.rec('14. ops_summary ki ginti asli rows se milti hai',
                        v_n = v_n2,
                        'summary ' || v_n || ', asli rows ' || v_n2);
  end if;

  -- ================================================================ 15
  -- Likhi hui remark mitayi ja sakti hai?
  --
  -- Ye 36_ops_remarks_fix.sql ki jaanch hai. Wo na chalayi ho to ye
  -- FAIL aayega — aur wahi sahi jawab hai.
  --
  -- Baat sirf suvidha ki nahi: aaj backup fail hua, aadmi ne likha
  -- "repository out of space", masla theek kiya aur jaanch completed
  -- kar di — remark box khaali kar ke. Purani remark chipki reh jaye to
  -- report aage se kehti hai "completed — repository out of space", aur
  -- padhne wala samjhega backup abhi bhi tuta hua hai.
  if v_admin is null then
    perform pg_temp.skip('15. Remark mitayi ja sakti hai',
                         'koi admin account nahi mila');
  else
    select id into v_exec from public.ops_task_executions
     order by due_date desc limit 1;

    if v_exec is null then
      perform pg_temp.skip('15. Remark mitayi ja sakti hai',
                           'abhi koi jaanch hi nahi hai');
    else
      begin
        update public.ops_task_executions
           set remarks = 'ZZ test remark', status = 'completed'
         where id = v_exec;

        perform set_config('role', 'authenticated', true);
        perform set_config('request.jwt.claims',
                           json_build_object('sub', v_admin::text,
                                             'role', 'authenticated')::text, true);

        -- '' bheji = "mita do"
        perform public.ops_complete(v_exec, 'completed'::ops_status, '');

        perform set_config('role', 'none', true);
        perform set_config('request.jwt.claims', '', true);

        select count(*) into v_n from public.ops_task_executions
         where id = v_exec and remarks is null;

        -- ...aur NULL bhejne par purani remark bachi rehni chahiye,
        -- warna checklist ka ek-click wala "ho gaya" aadmi ki likhi hui
        -- baat ud a deta.
        update public.ops_task_executions
           set remarks = 'ZZ test remark' where id = v_exec;

        perform set_config('role', 'authenticated', true);
        perform set_config('request.jwt.claims',
                           json_build_object('sub', v_admin::text,
                                             'role', 'authenticated')::text, true);
        perform public.ops_complete(v_exec, 'completed'::ops_status, null);
        perform set_config('role', 'none', true);
        perform set_config('request.jwt.claims', '', true);

        select count(*) into v_n2 from public.ops_task_executions
         where id = v_exec and remarks = 'ZZ test remark';

        v_ok := (v_n = 1 and v_n2 = 1);
        v_note := case
                    when v_n <> 1 then 'khaali bhejne par remark mitti nahi — 36 chalayi hai?'
                    when v_n2 <> 1 then 'NULL bhejne par remark ud gayi'
                    else 'dono taraf sahi'
                  end;
        raise exception '%', MARK;
      exception when others then
        if sqlerrm <> MARK then
          v_ok := false;
          v_note := sqlerrm;
        end if;
      end;
      perform pg_temp.rec('15. Remark mitayi ja sakti hai', v_ok, v_note);
    end if;
  end if;
end $$;


-- ---------------------------------------------------------------- nateeja
--
-- Sab PASS ya SKIP hona chahiye. Ek bhi FAIL ho to us line ka note
-- padhiye — usme likha hai ki kya hua.

select naam as test, natija, note from _ops_test order by n;
