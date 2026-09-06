# JPH Helpdesk

Frappe Helpdesk jaisa helpdesk — par Supabase par, aur bina server ke.

**Stack:** Vue 3 + Vite + Tailwind 3 + `frappe-ui` (wahi library jo Frappe Helpdesk use karta hai) + Supabase + Cloudflare Pages

---

## Abhi kya ban chuka hai

| Cheez | Halat |
|---|---|
| Project setup, design/theme | ✅ ban gaya |
| Guest ticket form (bina login) | ✅ ban gaya |
| Login page | ✅ ban gaya |
| Admin dashboard (tickets home par) | ✅ ban gaya |
| Database schema + permissions | ✅ likh diya, chalana baaki |
| Ticket detail page | ⏳ agla step |
| Agent create / invite / manage | ⏳ agla step |
| Email | ⏳ baad me |

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

1. **Authentication -> Emails -> "Reset Password"** template me
   `{{ .Token }}` daaliye. Default template me sirf link hota hai.
   *(Link bhi chalta rehta hai — wo `/forgot-password` par girta hai aur
   seedha "naya password" wale step par le jaata hai.)*
2. **Authentication -> URL Configuration -> Redirect URLs** me site ka
   pata hona chahiye, warna link kahin aur gir jaayega.
3. **Custom SMTP** lagaiye. Supabase ke apne SMTP par ghante me sirf 2
   email jaati hain — teen log ek saath password bhool jaayein to teesre
   ko code milega hi nahi.

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
    admin/
      Dashboard.vue      tickets home par
      TicketDetail.vue   (abhi khali)
      Agents.vue         (abhi khali)
supabase/
  01_schema.sql          tables + RLS + functions
public/
  _redirects             SPA routing (Cloudflare Pages ke liye zaroori)
```

---

## Cloudflare Pages par deploy

1. Code GitHub par push kijiye
2. Cloudflare Pages me repo connect kijiye
3. Build settings:
   - **Build command:** `npm run build`
   - **Output directory:** `dist`
4. Environment variables me `VITE_SUPABASE_URL` aur `VITE_SUPABASE_ANON_KEY` daaliye

`public/_redirects` pehle se hai — iske bina `/login` par direct jaane par 404 aata.

---

## Do cheezein jo pata honi chahiye

**1. frappe-ui built package nahi, source bhejta hai.** Isliye `tailwind.config.js` ke `content` me uska path dena zaroori hai, warna uske components ki classes CSS me aayengi hi nahi aur design toota dikhega.

**2. CSS import ka sahi path `frappe-ui/style.css` hai** — `frappe-ui/src/style.css` likhne par build fail hoti hai.
