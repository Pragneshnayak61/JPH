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

function escapeHtml(s: string) {
  return s
    .replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;").replace(/'/g, "&#39;");
}

function layout(title: string, bodyHtml: string) {
  return `<!doctype html><html><body style="margin:0;background:#f6f8f7;padding:24px;font-family:-apple-system,Segoe UI,Roboto,sans-serif;color:#1b2422">
<div style="max-width:560px;margin:0 auto;background:#fff;border:1px solid #e5e7eb;border-radius:12px;padding:24px">
  <h1 style="margin:0 0 12px;font-size:18px">${escapeHtml(title)}</h1>
  ${bodyHtml}
  <p style="margin:24px 0 0;padding-top:16px;border-top:1px solid #eee;font-size:12px;color:#8a9391">
    JPH Helpdesk
  </p>
</div></body></html>`;
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
      html,
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

  // ---------------------------------------------------------------- 1
  // Ticket bana — customer ko confirmation.
  //
  // Ye anon bhi bula sakta hai (guest form se). Isliye public_token
  // maangte hain: wo random uuid hai jo sirf ticket banane wale ko mila
  // hai. Mail hamesha USI ticket ke apne email par jaata hai, client ke
  // bheje kisi address par nahi.
  if (type === "ticket_created") {
    const token = String(body.public_token ?? "");
    if (!token) return json({ error: "Missing token" }, 400, origin);

    const { data: t } = await db
      .from("tickets")
      .select("id, subject, raised_by_email, contact_name, public_token")
      .eq("public_token", token)
      .single();
    if (!t) return json({ error: "Ticket not found" }, 404, origin);

    await sendMail(
      t.raised_by_email,
      `[#${t.id}] We received your request`,
      layout("Thanks, we have your request", `
        <p style="margin:0 0 12px">Hi ${escapeHtml(t.contact_name || "there")},</p>
        <p style="margin:0 0 12px">We received your request and our team will get back to you by email.</p>
        <p style="margin:0 0 6px"><strong>Ticket #${t.id}</strong></p>
        <p style="margin:0 0 12px;color:#5a6563">${escapeHtml(t.subject)}</p>
        <p style="margin:0;font-size:13px;color:#8a9391">Just reply to this email if you want to add anything.</p>`)
    );
    return json({ ok: true }, 200, origin);
  }

  // ---------------------------------------------------------------- 2
  // Agent ne reply likha — customer ko bhejo.
  // Yahan caller ka staff hona zaroori hai.
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
    // bhi hai (client par bhi hai) — kyunki galti se bhej diya to wapas
    // nahi le sakte.
    if (m.is_internal) return json({ error: "Internal notes are not emailed" }, 400, origin);

    const { data: t } = await db
      .from("tickets")
      .select("id, subject, raised_by_email, contact_name")
      .eq("id", m.ticket_id)
      .single();
    if (!t) return json({ error: "Ticket not found" }, 404, origin);

    await sendMail(
      t.raised_by_email,
      `Re: [#${t.id}] ${t.subject}`,
      layout(t.subject, `
        <p style="margin:0 0 12px">Hi ${escapeHtml(t.contact_name || "there")},</p>
        <div style="margin:0 0 16px;padding:12px;background:#f6f8f7;border-radius:8px;white-space:pre-wrap">${escapeHtml(m.body)}</div>
        <p style="margin:0;font-size:13px;color:#8a9391">
          &mdash; ${escapeHtml(m.author_name || "Support")}<br>
          Reply to this email to continue the conversation.
        </p>`)
    );
    return json({ ok: true }, 200, origin);
  }

  // ---------------------------------------------------------------- 3
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

    await sendMail(
      to,
      "Your JPH Helpdesk account",
      layout("Your account is ready", `
        <p style="margin:0 0 12px">Hi ${escapeHtml(name || "there")},</p>
        <p style="margin:0 0 12px">An account has been created for you on JPH Helpdesk.</p>
        <table style="margin:0 0 16px;font-size:14px">
          <tr><td style="padding:2px 12px 2px 0;color:#5a6563">Email</td><td>${escapeHtml(to)}</td></tr>
          <tr><td style="padding:2px 12px 2px 0;color:#5a6563">Password</td><td><code>${escapeHtml(password)}</code></td></tr>
        </table>
        <a href="${appUrl}/login" style="display:inline-block;background:#1b2422;color:#fff;padding:9px 16px;border-radius:8px;text-decoration:none;font-size:14px">Sign in</a>
        <p style="margin:16px 0 0;font-size:13px;color:#8a9391">Please change this password after you sign in.</p>`)
    );
    return json({ ok: true }, 200, origin);
  }

  return json({ error: "Unknown notification type" }, 400, origin);
});
