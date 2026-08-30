import { createClient } from "@supabase/supabase-js";

const url = import.meta.env.VITE_SUPABASE_URL;
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

/**
 * `false` jab tak Supabase project bana kar .env me values nahi daali jaatin.
 * App is haalat me bhi khulti hai — bas ek saaf message dikhata hai,
 * blank white screen ke bajaye.
 */
export const isSupabaseConfigured = Boolean(url && anonKey);

/**
 * Anon key browser me jaati hai — ye by design hai, secret nahi hai.
 * Asli suraksha Postgres ki Row Level Security se aati hai, is key se nahi.
 * Isliye har table par RLS policy likhna ZAROORI hai.
 *
 * `service_role` key kabhi is folder me mat rakhiye — wo RLS ko bypass
 * karti hai aur browser me jaate hi poora database khul jayega.
 */
export const supabase = createClient(
  url ?? "http://localhost:54321",
  anonKey ?? "public-anon-key-placeholder",
  {
    auth: {
      persistSession: true,
      autoRefreshToken: true,
    },
  }
);
