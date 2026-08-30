// Naya user banane ke liye Edge Function.
//
// Ye browser se nahi ho sakta: user banane ke liye `service_role` key chahiye,
// jo saari permissions (aur RLS) bypass kar deti hai. Wo key browser me
// aate hi poora database sabke liye khul jaayega. Isliye ye kaam server par.
//
// Deploy:
//   supabase functions deploy create-user --project-ref zzpmnffqfyiwkimsdhtl
//
// SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY Supabase khud inject karta hai —
// inhe alag se set karne ki zaroorat nahi.

import { createClient } from "jsr:@supabase/supabase-js@2";

const ALLOWED_ORIGINS = [
  "https://it-helpdesk.vahorajuned858.workers.dev",
  "http://localhost:5173",
];

function corsHeaders(origin: string | null) {
  // Sirf apni site ko allow karna hai. "*" likh dena aasan hota, par phir
  // koi bhi website user ke logged-in browser se ye function bula sakti thi.
  const allow = origin && ALLOWED_ORIGINS.includes(origin) ? origin : ALLOWED_ORIGINS[0];
  return {
    "Access-Control-Allow-Origin": allow,
    // `apikey` aur `x-client-info` bhi zaroori hain — supabase-js har
    // request me ye bhejta hai. Inhe chhod dene par browser preflight
    // fail kar deta hai aur request bhejta hi nahi. App me sirf
    // "Failed to send a request to the Edge Function" dikhta hai,
    // jisse lagta hai function deploy hi nahi hui.
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

Deno.serve(async (req) => {
  const origin = req.headers.get("Origin");

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders(origin) });
  }
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405, origin);
  }

  const url = Deno.env.get("SUPABASE_URL")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  // ---------------------------------------------------------------
  // 1. Bulane wala kaun hai?
  //
  // Ye check SABSE ZAROORI hai. Iske bina koi bhi ye function call karke
  // apne aap ko admin bana sakta hai. Hum uske apne token se poochhte hain
  // ki wo kaun hai — token jhoot nahi bol sakta, Supabase use verify karta hai.
  // ---------------------------------------------------------------
  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader.startsWith("Bearer ")) {
    return json({ error: "Not signed in" }, 401, origin);
  }

  const caller = createClient(url, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });

  const { data: userData, error: userErr } = await caller.auth.getUser();
  if (userErr || !userData.user) {
    return json({ error: "Not signed in" }, 401, origin);
  }

  const { data: callerProfile } = await caller
    .from("profiles")
    .select("kind, is_active")
    .eq("id", userData.user.id)
    .single();

  if (!callerProfile || callerProfile.kind !== "admin" || !callerProfile.is_active) {
    return json({ error: "Only an active administrator can add people" }, 403, origin);
  }

  // ---------------------------------------------------------------
  // 2. Input check
  // ---------------------------------------------------------------
  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid request body" }, 400, origin);
  }

  const email = String(body.email ?? "").trim().toLowerCase();
  const password = String(body.password ?? "");
  const fullName = String(body.full_name ?? "").trim();
  const kind = String(body.kind ?? "agent");
  const roleId = body.role_id ? String(body.role_id) : null;

  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) {
    return json({ error: "That email does not look right" }, 400, origin);
  }
  if (password.length < 8) {
    return json({ error: "Password must be at least 8 characters" }, 400, origin);
  }
  if (!["admin", "agent", "customer"].includes(kind)) {
    return json({ error: "Invalid access level" }, 400, origin);
  }

  // ---------------------------------------------------------------
  // 3. User banao
  // ---------------------------------------------------------------
  const admin = createClient(url, serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const { data: created, error: createErr } = await admin.auth.admin.createUser({
    email,
    password,
    // Email abhi set nahi hai, isliye confirmation link bhej nahi sakte.
    // Ye na karein to banda login hi nahi kar payega.
    email_confirm: true,
    user_metadata: { full_name: fullName || null },
  });

  if (createErr || !created.user) {
    return json({ error: createErr?.message ?? "Could not create the account" }, 400, origin);
  }

  // Profile trigger se apne aap ban jaati hai (kind = 'customer').
  // Ab usme sahi access aur role daal do.
  const { error: profileErr } = await admin
    .from("profiles")
    .update({
      kind,
      role_id: kind === "customer" ? null : roleId,
      full_name: fullName || null,
    })
    .eq("id", created.user.id);

  if (profileErr) {
    // Aadha kaam chhodna theek nahi — aisa user bach jaata jo login to kar
    // leta par uski access galat hoti. Rollback karke saaf error do.
    await admin.auth.admin.deleteUser(created.user.id);
    return json({ error: `Account rolled back: ${profileErr.message}` }, 400, origin);
  }

  return json({ id: created.user.id, email }, 200, origin);
});
