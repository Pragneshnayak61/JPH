// Email bhejne wali Edge Function.
//
// Design ki ek soch samajh lijiye: ye function "jo bhejna ho bhej do" wali
// nahi hai. Client sirf ITNA batata hai ki "is ticket ke liye is tarah ka
// mail bhejo" — recipient aur content function KHUD database se nikalta hai.
//
// Agar client se recipient/body lete, to koi bhi logged-in banda is function
// ko spam bhejne ke liye istemal kar leta (aur wo bhi aapke Gmail se).
//
// Deploy:
//   supabase functions deploy notify --project-ref zzpmnffqfyiwkimsdhtl
//
// Secrets (Supabase -> Edge Functions -> Secrets me set karni hain):
//   SMTP_HOST      smtp.gmail.com
//   SMTP_PORT      465
//   SMTP_USER      aapka@gmail.com
//   SMTP_PASS      Gmail ka App Password (normal password kaam NAHI karega)
//   SMTP_FROM      "JPH Support <aapka@gmail.com>"
//   APP_URL        https://it-helpdesk.vahorajuned858.workers.dev

import { createClient } from "jsr:@supabase/supabase-js@2";
import { SMTPClient } from "https://deno.land/x/denomailer@1.6.0/mod.ts";

const ALLOWED_ORIGINS = [
  "https://it-helpdesk.vahorajuned858.workers.dev",
  "http://localhost:5173",
];

function corsHeaders(origin: string | null) {
  const allow = origin && ALLOWED_ORIGINS.includes(origin) ? origin : ALLOWED_ORIGINS[0];
  return {
    "Access-Control-Allow-Origin": allow,
    // apikey aur x-client-info bhi zaroori hain — supabase-js ye har request
    // me bhejta hai, aur allow na karne par browser preflight hi fail kar deta.
    "Access-Control-Allow-Headers":
      "authorization, content-type, apikey, x-client-info",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Vary": "Origin",
  };
}

function json(body: unknown, status: number, origin: string | null) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders(origin), "Content-Type": "application/json" },
  });
}

function esc(s: string) {
  return s
    .replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;").replace(/'/g, "&#39;");
}

/** HTML se plain text — mail ka text version banane ke liye. */
function toText(html: string) {
  return html
    .replace(/<br\s*\/?>/gi, "\n")
    .replace(/<\/(p|div|h[1-6]|tr|li)>/gi, "\n")
    .replace(/<li>/gi, "  - ")
    .replace(/<[^>]+>/g, "")
    .replace(/&nbsp;/g, " ").replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<").replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"').replace(/&#39;/g, "'")
    // Line ke aakhir ki spaces — yahi "=20" ban jaati hain.
    .replace(/[ \t]+$/gm, "")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}

/**
 * HTML se line-end ki spaces hatata hai.
 *
 * Yahi "=20" ki asli jad hai. Mail quoted-printable me encode hoti hai,
 * aur usme line ke aakhir ka space `=20` ban kar mail me DIKHNE lagta
 * hai. Hamara template indentation ke saath likha hai, to har line ke
 * aakhir me spaces bach jaate the.
 *
 * Khali lines bhi hata dete hain — wo bhi encode hokar shor banti hain.
 */
function tidy(html: string) {
  return html
    .split("\n")
    .map((l) => l.replace(/[ \t]+$/, ""))
    .filter((l) => l.trim().length > 0)
    .join("\n");
}

type Brand = { name: string; color: string; logo: string | null; contact: string | null };

/**
 * Poora email template.
 *
 * Sab kuch TABLE se bana hai, div/flex se nahi. Outlook aur kai purane
 * clients modern CSS samajhte hi nahi — wahan flex layout bikhar jaata
 * hai. Style bhi har tag par inline hai, kyunki <style> block Gmail
 * aksar hata deta hai.
 */
function layout(brand: Brand, opts: {
  preheader: string;
  heading: string;
  bodyHtml: string;
  ctaText?: string;
  ctaUrl?: string;
  footnote?: string;
}) {
  const { name, color } = brand;
  const initial = esc(name.charAt(0).toUpperCase());

  return `<!doctype html>
<html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>${esc(opts.heading)}</title></head>
<body style="margin:0;padding:0;background:#f4f6f5;">

<!-- Preheader: inbox me subject ke baad dikhne wali line. Chhupa hua
     rakhte hain, warna mail ke andar dobara chhap jaata hai. -->
<div style="display:none;max-height:0;overflow:hidden;opacity:0;">
  ${esc(opts.preheader)}
</div>

<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background:#f4f6f5;padding:32px 12px;">
<tr><td align="center">

  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="max-width:560px;background:#ffffff;border:1px solid #e6e9e8;border-radius:12px;overflow:hidden;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">

    <!-- header -->
    <tr><td style="padding:20px 28px;border-bottom:1px solid #eef1f0;">
      <table role="presentation" cellpadding="0" cellspacing="0" border="0">
      <tr>
        <td width="32" style="vertical-align:middle;">
          ${brand.logo
            ? `<img src="${esc(brand.logo)}" width="32" height="32" alt="" style="display:block;border-radius:6px;">`
            : `<table role="presentation" cellpadding="0" cellspacing="0" border="0"><tr>
                 <td width="32" height="32" align="center" style="background:${esc(color)};border-radius:6px;color:#ffffff;font-size:15px;font-weight:700;line-height:32px;">${initial}</td>
               </tr></table>`}
        </td>
        <td style="padding-left:10px;vertical-align:middle;font-size:15px;font-weight:600;color:#1b2422;">
          ${esc(name)}
        </td>
      </tr>
      </table>
    </td></tr>

    <!-- body -->
    <tr><td style="padding:28px;">
      <h1 style="margin:0 0 16px;font-size:19px;line-height:1.35;font-weight:600;color:#1b2422;">
        ${esc(opts.heading)}
      </h1>
      ${opts.bodyHtml}

      ${opts.ctaUrl ? `
      <table role="presentation" cellpadding="0" cellspacing="0" border="0" style="margin:24px 0 4px;">
      <tr><td align="center" style="background:${esc(color)};border-radius:8px;">
        <a href="${esc(opts.ctaUrl)}" style="display:inline-block;padding:11px 22px;font-size:14px;font-weight:600;color:#ffffff;text-decoration:none;">
          ${esc(opts.ctaText ?? "Open")}
        </a>
      </td></tr>
      </table>` : ""}

      ${opts.footnote ? `
      <p style="margin:20px 0 0;font-size:13px;line-height:1.5;color:#8a9391;">
        ${opts.footnote}
      </p>` : ""}
    </td></tr>

    <!-- footer -->
    <tr><td style="padding:16px 28px;background:#fafbfb;border-top:1px solid #eef1f0;">
      <p style="margin:0;font-size:12px;line-height:1.5;color:#8a9391;">
        ${esc(name)}${brand.contact ? ` &middot; <a href="mailto:${esc(brand.contact)}" style="color:#8a9391;">${esc(brand.contact)}</a>` : ""}
      </p>
    </td></tr>

  </table>
</td></tr>
</table>
</body></html>`;
}

async function sendMail(to: string, subject: string, html: string) {
  const client = new SMTPClient({
    connection: {
      hostname: Deno.env.get("SMTP_HOST") ?? "smtp.gmail.com",
      port: Number(Deno.env.get("SMTP_PORT") ?? 465),
      tls: true,
      auth: {
        username: Deno.env.get("SMTP_USER")!,
        password: Deno.env.get("SMTP_PASS")!,
      },
    },
  });
  try {
    await client.send({
      from: Deno.env.get("SMTP_FROM") ?? Deno.env.get("SMTP_USER")!,
      to,
      subject,
      // Plain text BHI bhejte hain, sirf html nahi.
      //
      // Iske bina do problem hoti thi: mail ke beech me "=20" jaise
      // quoted-printable ke tukde dikhte the, aur jin clients me HTML
      // band ho unhe kuch padhne ko hi nahi milta tha.
      content: toText(html),
      html: tidy(html),
    });
  } finally {
    // close() na karein to connection khula reh jaata hai aur function
    // timeout tak latka rehta hai.
    await client.close();
  }
}

Deno.serve(async (req) => {
  const origin = req.headers.get("Origin");
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders(origin) });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405, origin);

  const url = Deno.env.get("SUPABASE_URL")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const appUrl = Deno.env.get("APP_URL") ?? ALLOWED_ORIGINS[0];

  if (!Deno.env.get("SMTP_USER") || !Deno.env.get("SMTP_PASS")) {
    return json({ error: "Email is not configured yet" }, 503, origin);
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid request body" }, 400, origin);
  }

  const type = String(body.type ?? "");
  const db = createClient(url, serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  // Branding settings se — mail me wahi naam aur rang jo site par hai.
  // Hardcode karte to settings badalne par mail purane naam se jaati.
  const { data: st } = await db
    .from("site_settings")
    .select("company_name, legal_name, accent_color, logo_url, contact_email")
    .eq("id", 1)
    .single();

  const brand: Brand = {
    name: st?.company_name || "Support",
    color: st?.accent_color || "#1b2422",
    logo: st?.logo_url || null,
    contact: st?.contact_email || null,
  };

  // ---------------------------------------------------------------- 1
  // Ticket bana — customer ko confirmation.
  //
  // Ye anon bhi bula sakta hai (guest form se). Isliye public_token
  // maangte hain: wo random uuid hai jo sirf ticket banane wale ko mila
  // hai. Mail hamesha USI ticket ke apne email par jaata hai.
  if (type === "ticket_created") {
    const token = String(body.public_token ?? "");
    if (!token) return json({ error: "Missing token" }, 400, origin);

    const { data: t } = await db
      .from("tickets")
      .select("id, subject, raised_by_email, contact_name, public_token")
      .eq("public_token", token)
      .single();
    if (!t) return json({ error: "Ticket not found" }, 404, origin);

    // Staff ne khud banaya ticket ho to customer ka email hota hi nahi
    // (26_optional_customer_email.sql). Ye galti nahi hai, isliye error
    // nahi dete — warna caller ko lagta hai kuch toota hai.
    if (!t.raised_by_email) {
      return json({ ok: true, skipped: "no customer email" }, 200, origin);
    }

    const html = layout(brand, {
      preheader: `Ticket #${t.id} — we have your request and will reply by email.`,
      heading: "We have your request",
      bodyHtml: `
        <p style="margin:0 0 14px;font-size:15px;line-height:1.6;color:#3a4644;">
          Hi ${esc(t.contact_name || "there")},
        </p>
        <p style="margin:0 0 18px;font-size:15px;line-height:1.6;color:#3a4644;">
          Our team has received your request and will get back to you by email.
        </p>
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background:#f7f9f8;border-radius:8px;">
        <tr><td style="padding:14px 16px;">
          <p style="margin:0 0 6px;font-size:12px;text-transform:uppercase;letter-spacing:.04em;color:#8a9391;">Your request</p>
          <p style="margin:0 0 10px;font-size:15px;font-weight:600;color:#1b2422;">${esc(t.subject)}</p>
          <p style="margin:0;font-size:13px;line-height:1.5;color:#8a9391;">
            Your link:<br>
            <a href="${appUrl}/ticket/${t.public_token}" style="color:${esc(brand.color)};word-break:break-all;">${appUrl}/ticket/${t.public_token}</a>
          </p>
        </td></tr>
        </table>`,
      ctaText: "View your ticket",
      ctaUrl: `${appUrl}/ticket/${t.public_token}`,
      footnote:
        "Keep this email &mdash; the link above takes you straight back to " +
        "your ticket, so there is nothing to bookmark. You can also just " +
        "reply to this email.",
    });

    // Subject me "#7" nahi. Wo andar ka number hai, customer ke kisi
    // kaam ka nahi — use link chahiye. Number body me reference ke saath
    // dikh hi jaata hai.
    await sendMail(t.raised_by_email, t.subject, html);
    return json({ ok: true }, 200, origin);
  }

  // ---------------------------------------------------------------- 2
  // Agent ne reply likha — customer ko bhejo.
  if (type === "agent_reply") {
    const authHeader = req.headers.get("Authorization") ?? "";
    const caller = createClient(url, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: u } = await caller.auth.getUser();
    if (!u?.user) return json({ error: "Not signed in" }, 401, origin);

    const { data: me } = await caller
      .from("profiles").select("kind, is_active").eq("id", u.user.id).single();
    if (!me || !me.is_active || !["admin", "agent"].includes(me.kind)) {
      return json({ error: "Not allowed" }, 403, origin);
    }

    const messageId = Number(body.message_id);
    const { data: m } = await db
      .from("ticket_messages")
      .select("id, body, is_internal, author_name, ticket_id")
      .eq("id", messageId)
      .single();
    if (!m) return json({ error: "Message not found" }, 404, origin);

    // Internal note customer ko kabhi nahi jaana chahiye. Ye check yahan
    // BHI hai (client par bhi hai) — kyunki galti se bhej diya to wapas
    // nahi le sakte.
    if (m.is_internal) return json({ error: "Internal notes are not emailed" }, 400, origin);

    const { data: t } = await db
      .from("tickets")
      .select("id, subject, raised_by_email, contact_name, public_token")
      .eq("id", m.ticket_id)
      .single();
    if (!t) return json({ error: "Ticket not found" }, 404, origin);

    // Bhejne ki jagah hi nahi. Message table me save ho chuka hai — team
    // use dekh legi — bas mail nahi jaata.
    if (!t.raised_by_email) {
      return json({ ok: true, skipped: "no customer email" }, 200, origin);
    }

    const html = layout(brand, {
      preheader: String(m.body).slice(0, 120),
      heading: t.subject,
      bodyHtml: `
        <p style="margin:0 0 14px;font-size:15px;line-height:1.6;color:#3a4644;">
          Hi ${esc(t.contact_name || "there")},
        </p>
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background:#f7f9f8;border-left:3px solid ${esc(brand.color)};border-radius:6px;">
        <tr><td style="padding:14px 16px;font-size:15px;line-height:1.6;color:#1b2422;white-space:pre-wrap;">${esc(m.body)}</td></tr>
        </table>
        <p style="margin:14px 0 0;font-size:13px;color:#8a9391;">
          &mdash; ${esc(m.author_name || "Support")}
        </p>
        <p style="margin:14px 0 0;font-size:13px;line-height:1.5;color:#8a9391;">
          Your ticket link:<br>
          <a href="${appUrl}/ticket/${t.public_token}" style="color:${esc(brand.color)};word-break:break-all;">${appUrl}/ticket/${t.public_token}</a>
        </p>`,
      ctaText: "View the full ticket",
      ctaUrl: `${appUrl}/ticket/${t.public_token}`,
      footnote: "Reply to this email to continue the conversation.",
    });

    await sendMail(t.raised_by_email, `Re: ${t.subject}`, html);
    return json({ ok: true }, 200, origin);
  }

  // ---------------------------------------------------------------- 3
  // Ticket kisi agent ko assign hua — usko bata do.
  //
  // Ek hi mail me kai ticket ja sakte hain (bulk assign ke liye). 77
  // ticket assign karne par 77 alag mail bhejna Gmail ki din bhar ki
  // limit hi kha jaata, aur agent ke inbox ka bhi bura haal karta.
  if (type === "ticket_assigned") {
    const authHeader = req.headers.get("Authorization") ?? "";
    const caller = createClient(url, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: u } = await caller.auth.getUser();
    if (!u?.user) return json({ error: "Not signed in" }, 401, origin);

    const { data: me } = await caller
      .from("profiles").select("kind, is_active").eq("id", u.user.id).single();
    if (!me || !me.is_active || !["admin", "agent"].includes(me.kind)) {
      return json({ error: "Not allowed" }, 403, origin);
    }

    const agentId = String(body.agent_id ?? "");
    const ids = Array.isArray(body.ticket_ids) ? body.ticket_ids.map(Number) : [];
    if (!agentId || !ids.length) return json({ error: "Missing details" }, 400, origin);

    // Apne aap ko assign kiya to mail bhejne ka koi matlab nahi — abhi
    // to khud hi kiya hai.
    if (agentId === u.user.id) return json({ ok: true, skipped: "self" }, 200, origin);

    // Agent ka email service_role se padhte hain, client se nahi lete.
    // Isse assign karne wale ko uska email kabhi pata nahi chalta —
    // wahi pehchaan wala niyam jo poore app me hai.
    const { data: agent } = await db
      .from("profiles")
      .select("email, full_name, agent_code, is_active")
      .eq("id", agentId)
      .single();
    if (!agent || !agent.is_active) {
      return json({ error: "Agent not found" }, 404, origin);
    }

    const { data: rows } = await db
      .from("tickets")
      .select("id, subject, priority, company_name, due_date")
      .in("id", ids)
      .order("due_date", { ascending: true });
    if (!rows?.length) return json({ error: "Tickets not found" }, 404, origin);

    const list = rows.slice(0, 20).map((t) => `
      <tr>
        <td style="padding:8px 10px;border-top:1px solid #eef1f0;font-size:14px;color:#1b2422;">
          ${esc(t.subject)}
          <span style="display:block;font-size:12px;color:#8a9391;">
            ${esc(t.company_name || "—")}${t.due_date ? ` &middot; due ${esc(t.due_date)}` : ""}
          </span>
        </td>
      </tr>`).join("");

    const more = rows.length > 20
      ? `<p style="margin:10px 0 0;font-size:13px;color:#8a9391;">
           &hellip; and ${rows.length - 20} more.
         </p>`
      : "";

    const html = layout(brand, {
      preheader: `${rows.length} ticket${rows.length === 1 ? "" : "s"} assigned to you.`,
      heading:
        rows.length === 1
          ? "A ticket was assigned to you"
          : `${rows.length} tickets were assigned to you`,
      bodyHtml: `
        <p style="margin:0 0 16px;font-size:15px;line-height:1.6;color:#3a4644;">
          Hi ${esc(agent.full_name || agent.agent_code || "there")},
        </p>
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background:#f7f9f8;border-radius:8px;">
          ${list}
        </table>
        ${more}`,
      ctaText: rows.length === 1 ? "Open the ticket" : "Open your queue",
      ctaUrl: rows.length === 1
        ? `${appUrl}/admin/tickets/${rows[0].id}`
        : `${appUrl}/admin`,
    });

    await sendMail(
      agent.email,
      rows.length === 1
        ? `Assigned to you: ${rows[0].subject}`
        : `${rows.length} tickets assigned to you`,
      html
    );
    return json({ ok: true }, 200, origin);
  }

  // ---------------------------------------------------------------- 4
  // Naye agent ko welcome mail. Sirf admin bhej sakta hai.
  if (type === "user_invited") {
    const authHeader = req.headers.get("Authorization") ?? "";
    const caller = createClient(url, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: u } = await caller.auth.getUser();
    if (!u?.user) return json({ error: "Not signed in" }, 401, origin);

    const { data: me } = await caller
      .from("profiles").select("kind, is_active").eq("id", u.user.id).single();
    if (!me || !me.is_active || me.kind !== "admin") {
      return json({ error: "Not allowed" }, 403, origin);
    }

    const to = String(body.email ?? "").trim();
    const password = String(body.password ?? "");
    const name = String(body.full_name ?? "").trim();
    if (!to || !password) return json({ error: "Missing details" }, 400, origin);

    const html = layout(brand, {
      preheader: `Your ${brand.name} account is ready.`,
      heading: "Your account is ready",
      bodyHtml: `
        <p style="margin:0 0 18px;font-size:15px;line-height:1.6;color:#3a4644;">
          Hi ${esc(name || "there")}, an account has been created for you.
        </p>
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background:#f7f9f8;border-radius:8px;">
        <tr><td style="padding:14px 16px;">
          <p style="margin:0 0 8px;font-size:13px;color:#8a9391;">
            Email<br>
            <span style="font-size:15px;color:#1b2422;">${esc(to)}</span>
          </p>
          <p style="margin:0;font-size:13px;color:#8a9391;">
            Temporary password<br>
            <span style="font-size:15px;font-family:ui-monospace,Menlo,Consolas,monospace;color:#1b2422;">${esc(password)}</span>
          </p>
        </td></tr>
        </table>`,
      ctaText: "Sign in",
      ctaUrl: `${appUrl}/login`,
      footnote: "Please change this password after you sign in.",
    });

    await sendMail(to, `Your ${brand.name} account`, html);
    return json({ ok: true }, 200, origin);
  }

  return json({ error: "Unknown notification type" }, 400, origin);
});
