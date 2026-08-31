import { supabase } from "@/lib/supabase";
import type { Session } from "@supabase/supabase-js";
import { defineStore } from "pinia";
import { computed, ref } from "vue";

export type Profile = {
  id: string;
  email: string;
  full_name: string | null;
  kind: "admin" | "agent" | "customer";
  role_id: string | null;
  is_active: boolean;
  agent_code: string | null;
  specialization: string | null;
};

export type Role = {
  id: string;
  name: string;
  can_view_all_tickets: boolean;
  can_assign_tickets: boolean;
  can_delete_tickets: boolean;
  can_manage_agents: boolean;
  can_manage_customers: boolean;
  can_change_settings: boolean;
};

export const useAuthStore = defineStore("auth", () => {
  const session = ref<Session | null>(null);
  const profile = ref<Profile | null>(null);
  const role = ref<Role | null>(null);

  // `ready` batata hai ki pehli baar session check ho chuka hai.
  // Route guard ko iska intezaar karna padta hai — warna page reload par
  // Supabase ke session load hone se pehle hi guard chal jaata hai aur
  // logged-in user ko bhi login par bhej deta hai.
  const ready = ref(false);

  const isLoggedIn = computed(() => Boolean(session.value));
  const isStaff = computed(
    () => profile.value?.kind === "admin" || profile.value?.kind === "agent"
  );
  const isAdmin = computed(() => profile.value?.kind === "admin");

  /** Admin ke paas hamesha sab permissions hoti hain, role kuch bhi ho. */
  function can(perm: keyof Role): boolean {
    if (isAdmin.value) return true;
    return Boolean(role.value?.[perm]);
  }

  async function loadProfile() {
    if (!session.value) {
      profile.value = null;
      role.value = null;
      return;
    }
    const { data: p } = await supabase
      .from("profiles")
      .select("id, email, full_name, kind, role_id, is_active, agent_code, specialization")
      .eq("id", session.value.user.id)
      .single();
    profile.value = (p as Profile) ?? null;

    // profiles.email hamari apni copy hai; LOGIN auth.users se hota hai.
    // Email badalne par pehle sirf auth.users badalta tha aur ye copy
    // peechhe reh jaati thi — app purana email dikhati rehti thi, aur
    // usi purane email se login karne par account hi kho gaya lagta tha.
    //
    // Isliye har baar milaan: farq dikhe to database me hi theek kar do
    // (tickets ka email bhi wahin badal jaata hai).
    const liveEmail = session.value.user.email;
    if (profile.value && liveEmail && profile.value.email !== liveEmail) {
      const { data: synced } = await supabase.rpc("sync_my_email");
      // Fail ho jaye to bhi screen par sahi email dikhna chahiye — DB
      // baad me theek ho jaayega, par user ko galat pata nahi dikhna
      // chahiye.
      profile.value.email = (synced as string | null) ?? liveEmail;
    }

    if (profile.value?.role_id) {
      const { data: r } = await supabase
        .from("roles")
        .select("*")
        .eq("id", profile.value.role_id)
        .single();
      role.value = (r as Role) ?? null;
    } else {
      role.value = null;
    }
  }

  // onAuthStateChange sirf EK baar register hona chahiye. init() do jagah
  // se call hota hai (router guard aur login ke baad), aur bina is flag ke
  // har call ek naya listener jod deta — jisse har auth event par profile
  // kai baar load hoti.
  let listenerAttached = false;

  /** Session padhta hai aur profile load karta hai. Dobara call karna safe hai. */
  async function init() {
    const { data } = await supabase.auth.getSession();
    session.value = data.session;
    await loadProfile();
    ready.value = true;

    if (!listenerAttached) {
      listenerAttached = true;
      // Token refresh ya doosre tab me logout — dono yahan pakde jaate hain.
      supabase.auth.onAuthStateChange(async (_event, s) => {
        session.value = s;
        await loadProfile();
      });
    }
  }

  async function signOut() {
    await supabase.auth.signOut();
    session.value = null;
    profile.value = null;
    role.value = null;
  }

  return {
    session, profile, role, ready,
    isLoggedIn, isStaff, isAdmin,
    can, init, loadProfile, signOut,
  };
});
