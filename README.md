# JPH Helpdesk

Frappe Helpdesk jaisa helpdesk — par Supabase par, aur bina server ke.

**Stack:** Vue 3 + Vite + Tailwind 3 + `frappe-ui` (wahi library jo Frappe Helpdesk use karta hai) + Supabase + Cloudflare Workers

---

## Abhi kya ban chuka hai

| Cheez | Halat |
|---|---|
| Guest ticket form (bina login) | ✅ |
| Login + forgot password (email par code) | ✅ |
| Ticket dashboard, detail, reply, internal note | ✅ |
| Agent create / manage / roles / permissions | ✅ |
| Analytics | ✅ |
| Operations (server administration) | ✅ |
| Email bhejna (`notify` Edge Function) | ⚠️ SMTP baaki |

---

## Setup — 4 step

### 1. Supabase project banaiye

1. [supabase.com](https://supabase.com) par free account banaiye
2. **New Project** dabaiye
3. Database password kahin likh kar rakhiye
4. Region **Mumbai / Singapore** chuniye (India se tez chalega)

> Free project **7 din koi activity na ho to pause** ho jaata hai. Dashboard se ek click me wapas chalu ho jaata hai — bas pata hona chahiye, warna lagega ki kuch toot gaya.

### 2. Database bana lijiye

1. Supabase me **SQL Editor** kholiye
2. `supabase/01_schema.sql` poori file copy karke paste kijiye
3. **Run** dabaiye

Isse tables, permissions aur guest wala function sab ban jayenge.

### 3. Keys daaliye

1. Supabase me **Project Settings → API** kholiye
2. `.env.example` ko copy karke `.env` naam se save kijiye
3. Usme `Project URL` aur `anon public` key daaliye

> `service_role` key kabhi `.env` me mat daaliye — wo saari permissions bypass kar deti hai.

### 4. Chalaiye

```bash
npm install
npm run dev
```

Kholiye: `http://localhost:5173`

---

## Pehla admin kaise banayein

Sign-up se koi khud admin nahi ban sakta (jaan-boojh kar) — naya user hamesha `customer` banta hai. Pehla admin haath se banana padta hai:

1. Supabase → **Authentication → Users → Add user**
   Email aur password daal kar user banaiye
2. Supabase → **SQL Editor** me ye chalaiye:

```sql
update public.profiles
   set kind = 'admin',
       role_id = (select id from public.roles where name = 'Administrator')
 where email = 'aapka@email.com';
```

Ab us email se `/login` par login kijiye.

---

## Password bhool jaayein to

Login page par **Forgot password?** hai. Wo email par 6-digit code bhejta
hai, code sahi hone par naya password lag jaata hai. Poora kaam Supabase
Auth karta hai — na koi OTP table, na service_role.

Galat email daalne par code bhejta hi nahi — seedha "No account uses this
email" keh deta hai. Iske liye `25_account_exists.sql` chalni chahiye;
na chali ho to code phir bhi jaata hai, bas ye message nahi aata.

Ek baar ka setup, warna email me code nahi jaayega:

1. **Authentication -> Emails -> Templates -> "Reset Password"** ke
   Message body me `supabase/email_templates/reset_password.html` paste
   kijiye. Default template me `{{ .Token }}` hota hi nahi, sirf link —
   isi wajah se code email me nahi jaata.
   *(Link bhi chalta rehta hai — wo `/forgot-password` par girta hai aur
   seedha "naya password" wale step par le jaata hai.)*
2. **Authentication -> URL Configuration -> Redirect URLs** me site ka
   pata hona chahiye, warna link kahin aur gir jaayega.
3. **Custom SMTP** lagaiye. Supabase ke apne SMTP par ghante me sirf 2
   email jaati hain — teen log ek saath password bhool jaayein to teesre
   ko code milega hi nahi.

## Operations (server administration)

Helpdesk ke saath-saath 3-5 clients ke server, network, backup aur CCTV
ki rozana/haftawari/mahine ki jaanch. `/admin/operations`.

Teen page:

- **`/admin/operations`** — subah wali checklist. Gole par ek click =
  "ho gaya". Baaki paanch status "More" me, remarks aur saboot ke saath.
- **`/admin/operations/setup`** — client, device, task library, aur har
  client ki apni checklist. **Ye pehle bharna padta hai**, warna
  checklist khali rehti hai.
- **`/admin/operations/reports`** — date range, client, CSV export.

Do baatein jo dhaanche me hain:

- **Duplicate rok database par hai.** `ops_task_executions` par
  `UNIQUE (client_task_id, due_date)`. Isiliye generator ko cron *aur*
  page dono chala sakte hain — dobara chalne par row banti hi nahi.
- **History mit nahi sakti.** Task par `on delete restrict`, aur har row
  apna `task_name`/client/device khud likh leti hai. Naam badalne par
  purani report wahi bolti hai jo us din sach tha.

Permissions `roles` me hain: `can_run_operations` (jaanch karna) aur
`can_manage_operations` (checklist banana). Dono ka default `false`.

### Scripts, isi kram me

| Script | Kya karti hai |
|---|---|
| `27_ops_schema.sql` | tables, enums, permissions, RLS |
| `28_ops_seed.sql` | 6 category + 36 jaanchon ki library |
| `29_ops_functions.sql` | checklist, ticket banana, summary, report |
| `30_ops_generation.sql` | roz apne aap banna + pg_cron |
| `31_ops_evidence.sql` | private `ops-evidence` bucket |
| `32_ops_demo.sql` | *(marzi)* demo data — hatane ka tareeqa usi file me |
| `33_ops_ticket_link.sql` | ticket se wapas us jaanch tak |
| `34_ops_generation_health.sql` | generation sach me chal rahi hai ya nahi |
| `36_ops_remarks_fix.sql` | remark mitane ka sudhar |
| `35_ops_tests.sql` | *(marzi)* 15 test — **36 ke BAAD chalaiye** |

`check_status.sql` kabhi bhi chala kar dekh sakte hain ki kaunsi baaki hai.

### Asli kaam par lagane se pehle

1. **Demo data hata dijiye** — `32_ops_demo.sql` ke aakhir me hatane ka
   poora hissa likha hai. Har demo cheez ka naam `Demo · ` se shuru hota
   hai, isliye aapka apna data uske saath nahi jaata.
2. **Role dijiye.** Naye `Server Administrator` role me
   `can_run_operations` on hai. Jisko checklist banani ho use
   `can_manage_operations` chahiye.
3. **Setup page bhariye** — client, device, phir har client ki checklist
   ("Add from library" se). Iske bina rozana wali checklist khali rahegi.
4. **pg_cron on kijiye** (Database → Extensions), phir `30` dobara
   chalaiye. Band ho to checklist sirf tab banti hai jab koi page khole.

### Roz apne aap ban rahi hai ya nahi

`/admin/operations/setup` par sabse upar ek line aati hai. Sab theek ho
to hari, aur kuch chhoot gaya ho to peeli — usme wo tareekhein likhi
hoti hain jinki rows kam hain, aur ek button jo unhe bhar deta hai.

Ye poochhna zaroori isliye hai ki generation **chup-chaap** chalti hai.
Jo row bani hi nahi wo kahin nahi dikhti — na list me, na report me — aur
mahine ke aakhir me report keh deti hai "us din kuch tha hi nahi".

## Suraksha kaise kaam karti hai

Yahan koi backend server nahi hai — browser seedha Supabase se baat karta hai. Isliye **poori suraksha database ke andar** hai (Row Level Security).

**Guest ke paas `tickets` table par koi permission NAHI hai** — na padhne ki, na likhne ki. Wo sirf ek function chala sakta hai:

```sql
create_guest_ticket(...)  -- SECURITY DEFINER
```

Isse do problem apne aap hal ho jaati hain:

1. Guest kabhi kisi doosre ka ticket nahi padh sakta
2. Ticket ka token wapas mil jaata hai — bina `SELECT` permission diye

> Frappe wale system me yahi cheez galat thi: setting on karte hi har guest ko **sab guest tickets** dikhne lag jaate the, kyunki sabka owner "Guest" hi hota tha aur `if_owner` kuch rok nahi paata tha.

Anon key browser me jaati hai — ye normal hai, wo secret nahi hai. Asli taala RLS hai.

---

## Folder me kya kahan hai

```
src/
  lib/supabase.ts        Supabase client
  router/index.ts        routes (jis par requiresAuth nahi, wo sach me public hai)
  layouts/AdminLayout.vue  sidebar wala layout
  pages/
    GuestTicket.vue      public form — bina login
    TicketSubmitted.vue  thank-you + token
    Login.vue
    ForgotPassword.vue   email par code, phir naya password
    admin/
      Dashboard.vue      tickets home par
      TicketDetail.vue   ticket + reply + internal note
      Agents.vue         agent aur role
      Analytics.vue
      OperationsToday.vue    rozana wali checklist
      OperationsSetup.vue    client, device, library, checklist
      OperationsReports.vue  date range + CSV
  lib/opsEvidence.ts     saboot chadhana (private bucket)
supabase/
  01_schema.sql          tables + RLS + functions
  27..36_ops_*.sql       operations module
  check_status.sql       kaunsi script chal chuki hai
  functions/notify/      email bhejne wali Edge Function
public/
  _redirects             SPA routing (direct URL ke liye zaroori)
```

---

## Cloudflare par deploy

Site **Cloudflare Workers** par static assets ki tarah jaati hai
(`wrangler.jsonc` me sab likha hai):

```bash
npm run build
npx wrangler deploy
```

`.env` ki keys build ke waqt hi file me chali jaati hain, isliye Cloudflare
par alag se daalne ki zaroorat nahi. `public/_redirects` pehle se hai —
iske bina `/login` par seedha jaane par 404 aata.

---

## Do cheezein jo pata honi chahiye

**1. frappe-ui built package nahi, source bhejta hai.** Isliye `tailwind.config.js` ke `content` me uska path dena zaroori hai, warna uske components ki classes CSS me aayengi hi nahi aur design toota dikhega.

**2. CSS import ka sahi path `frappe-ui/style.css` hai** — `frappe-ui/src/style.css` likhne par build fail hoti hai.
