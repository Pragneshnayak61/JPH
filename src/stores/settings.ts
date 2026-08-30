import { supabase } from "@/lib/supabase";
import { defineStore } from "pinia";
import { ref } from "vue";

export type SiteSettings = {
  company_name: string;
  legal_name: string | null;
  logo_url: string | null;
  accent_color: string;
  guest_heading: string;
  guest_intro: string;
  guest_submit_label: string;
  thanks_title: string;
  thanks_message: string;
};

/**
 * Default values. Ye SIRF fallback hain — asli values database se aati hain.
 *
 * Inke bina guest form khali dikhta jab tak settings load na ho jayein,
 * ya settings load hi na ho payein (network fail, RLS badal gayi).
 * Aadha-adhoora page dikhane se behtar hai kuch sensible dikha dena.
 */
const DEFAULTS: SiteSettings = {
  company_name: "JPH Helpdesk",
  legal_name: null,
  logo_url: null,
  accent_color: "#1b2422",
  guest_heading: "JPH Support",
  guest_intro: "Tell us what went wrong — no account needed",
  guest_submit_label: "Submit ticket",
  thanks_title: "Ticket submitted",
  thanks_message: "Our team will reply to your email.",
};

export const useSettingsStore = defineStore("settings", () => {
  const settings = ref<SiteSettings>({ ...DEFAULTS });
  const loaded = ref(false);

  async function load(force = false) {
    if (loaded.value && !force) return;
    const { data } = await supabase
      .from("site_settings")
      .select("*")
      .eq("id", 1)
      .single();
    // data null ho sakta hai (row nahi mili, ya network fail). Us haalat
    // me defaults hi rehne dete hain — page phir bhi theek dikhega.
    if (data) settings.value = { ...DEFAULTS, ...(data as SiteSettings) };
    loaded.value = true;
  }

  async function save(changes: Partial<SiteSettings>) {
    const { error } = await supabase
      .from("site_settings")
      .update(changes)
      .eq("id", 1);
    if (error) throw error;
    settings.value = { ...settings.value, ...changes };
  }

  return { settings, loaded, load, save };
});
