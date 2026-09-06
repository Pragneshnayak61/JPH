<template>
  <div class="p-6">
    <h1 class="text-xl font-semibold text-ink-gray-9">My profile</h1>
    <p class="mt-1 text-p-base text-ink-gray-6">
      What you are good at, so tickets reach the right person
    </p>

    <div v-if="loading" class="py-16 text-center">
      <LoadingIndicator class="mx-auto h-5 w-5 text-ink-gray-5" />
    </div>

    <div v-else class="mt-6 grid gap-6 lg:grid-cols-[minmax(0,1fr)_340px]">
      <div class="space-y-6">
      <!-- pehchaan: dikhane ke liye, badalne ke liye nahi -->
      <section class="rounded-lg border border-outline-gray-2 p-4">
        <h2 class="text-p-base font-medium text-ink-gray-8">Your identity</h2>
        <dl class="mt-3 space-y-2 text-p-base">
          <div class="flex justify-between">
            <dt class="text-ink-gray-6">Your ID</dt>
            <dd class="font-medium text-ink-gray-9">
              {{ auth.profile?.agent_code || "—" }}
            </dd>
          </div>
        </dl>

        <div class="mt-4 border-t border-outline-gray-2 pt-4">
          <FormControl
            v-model="newEmail"
            type="email"
            label="Login email"
            :disabled="changingEmail"
          />
          <p class="mt-1 text-p-sm text-ink-gray-5">
            You sign in with this. Changing it sends a confirmation link to
            the new address &mdash; the change only happens after you click
            it. Your tickets move to the new address as well.
          </p>
          <Button
            v-if="newEmail.trim() && newEmail.trim() !== auth.profile?.email"
            class="mt-2"
            :loading="changingEmail"
            @click="changeEmail"
          >
            Send confirmation link
          </Button>
          <p v-if="emailMsg" class="mt-2 text-p-sm text-ink-green-8">
            {{ emailMsg }}
          </p>
          <ErrorMessage :message="emailError" class="mt-2" />
        </div>
        <p class="mt-3 text-p-sm text-ink-gray-5">
          Other agents only ever see your ID &mdash; never your name or email.
          Only an administrator can change your ID or access level.
        </p>
      </section>

      <!-- password -->
      <section class="rounded-lg border border-outline-gray-2 p-4">
        <h2 class="text-p-base font-medium text-ink-gray-8">Password</h2>
        <p class="mt-0.5 text-p-sm text-ink-gray-6">
          Change the password you sign in with
        </p>

        <div class="mt-3 space-y-3">
          <FormControl
            v-model="pw.current"
            type="password"
            label="Current password"
            :disabled="changingPw"
          />
          <FormControl
            v-model="pw.next"
            type="password"
            label="New password"
            :disabled="changingPw"
          />
          <FormControl
            v-model="pw.confirm"
            type="password"
            label="Repeat new password"
            :disabled="changingPw"
            @keyup.enter="changePassword"
          />
        </div>

        <p class="mt-2 text-p-sm text-ink-gray-5">
          At least 8 characters. You stay signed in here; other devices keep
          working until they sign out.
        </p>

        <Button class="mt-3" :loading="changingPw" @click="changePassword">
          Change password
        </Button>
        <p v-if="pwMsg" class="mt-2 text-p-sm text-ink-green-8">{{ pwMsg }}</p>
        <ErrorMessage :message="pwError" class="mt-2" />
      </section>

      <section class="rounded-lg border border-outline-gray-2 p-4">
        <h2 class="text-p-base font-medium text-ink-gray-8">About your work</h2>
        <div class="mt-3 space-y-3">
          <FormControl
            v-model="form.full_name"
            label="Your name"
            placeholder="Priya Sharma"
            :disabled="saving"
          />
          <p class="-mt-2 text-p-sm text-ink-gray-5">
            Only administrators can see this.
          </p>

          <FormControl
            v-model="form.specialization"
            label="Specialization"
            placeholder="Network"
            :disabled="saving"
          />
          <p class="-mt-2 text-p-sm text-ink-gray-5">
            One or two words. This is what other agents see next to your ID.
          </p>

          <FormControl
            v-model="form.mastery"
            type="textarea"
            :rows="3"
            label="What you handle"
            placeholder="Firewalls, VPN setup, office Wi-Fi, printer networking"
            :disabled="saving"
          />

          <FormControl
            v-model="form.experience_years"
            type="number"
            label="Years of experience"
            placeholder="6"
            :disabled="saving"
          />
        </div>
      </section>

      <section class="rounded-lg border border-outline-gray-2 p-4">
        <label class="flex items-start gap-3">
          <input
            v-model="form.show_publicly"
            type="checkbox"
            class="mt-1 rounded"
            :disabled="saving"
          />
          <span>
            <span class="text-p-base font-medium text-ink-gray-8">
              Show me on the support page
            </span>
            <span class="mt-0.5 block text-p-sm text-ink-gray-6">
              Customers will see your ID, specialization, what you handle,
              your years of experience and how many tickets you have resolved
              &mdash; never your name or email.
            </span>
          </span>
        </label>
      </section>

      <div class="flex items-center gap-3">
        <Button variant="solid" :loading="saving" @click="save">
          Save changes
        </Button>
        <span v-if="saved" class="text-p-sm text-ink-green-8">Saved</span>
      </div>
      <ErrorMessage :message="error" />
      </div>

      <!-- Preview: customer ko kya dikhta hai.
           Ye isliye zaroori hai ki ye card GUEST PORTAL par jaata hai —
           bina dekhe likhne par pata hi nahi chalta ki kaisa lagega. -->
      <div>
        <p class="mb-2 text-p-sm font-medium text-ink-gray-6">
          How customers see you
        </p>

        <div
          v-if="!form.show_publicly"
          class="rounded-xl border border-dashed border-outline-gray-3 p-6 text-center"
        >
          <p class="text-p-sm text-ink-gray-5">
            You are hidden from the support page. Tick the box on the left to
            appear there.
          </p>
        </div>

        <div
          v-else
          class="rounded-xl border border-outline-gray-2 bg-surface-base p-4"
        >
          <div class="flex items-start gap-3">
            <span
              class="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-surface-gray-7 text-p-sm font-semibold text-white"
            >
              {{ (form.specialization || "S").charAt(0).toUpperCase() }}
            </span>
            <div class="min-w-0 flex-1">
              <p class="truncate text-p-base font-medium text-ink-gray-9">
                {{ form.specialization || "Support" }}
              </p>
              <p class="text-p-sm text-ink-gray-5">
                {{ auth.profile?.agent_code || "—" }}
              </p>
            </div>
          </div>

          <p v-if="form.mastery" class="mt-3 text-p-sm leading-relaxed text-ink-gray-7">
            {{ form.mastery }}
          </p>

          <div
            v-if="resolvedCount || form.experience_years"
            class="mt-3 flex flex-wrap gap-x-4 gap-y-1 border-t border-outline-gray-2 pt-3"
          >
            <span v-if="resolvedCount" class="text-p-sm text-ink-gray-6">
              <strong class="font-semibold text-ink-gray-8">
                {{ resolvedCount }}
              </strong>
              tickets resolved
            </span>
            <span v-if="form.experience_years" class="text-p-sm text-ink-gray-6">
              <strong class="font-semibold text-ink-gray-8">
                {{ form.experience_years }}
              </strong>
              years experience
            </span>
          </div>
        </div>

        <p class="mt-2 text-p-sm text-ink-gray-5">
          Your name and email are never shown here.
        </p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { supabase } from "@/lib/supabase";
import { useAuthStore } from "@/stores/auth";
import { Button, ErrorMessage, FormControl, LoadingIndicator } from "frappe-ui";
import { onMounted, reactive, ref } from "vue";

const auth = useAuthStore();

const loading = ref(true);
const saving = ref(false);
const saved = ref(false);
const error = ref("");

const newEmail = ref("");
const changingEmail = ref(false);
const emailMsg = ref("");
const emailError = ref("");
const resolvedCount = ref(0);

/**
 * Login email badalna.
 *
 * Ye profiles table me nahi, Supabase ke apne auth.users me badalta hai —
 * login wahin se hota hai. Supabase naye pate par confirmation link
 * bhejta hai, aur badlav TABHI hota hai jab user us link par click kare.
 * Isliye yahan turant kuch nahi badalta.
 *
 * Purana email teen jagah pada hota hai: auth.users (login), profiles
 * (app me dikhne wala) aur tickets.raised_by_email (jawab kis pate par
 * jaayein). Teeno 23_email_and_password.sql ke apply_email_change() se
 * ek saath badalte hain — pehle sirf pehla badalta tha aur baaki do
 * peechhe reh jaate the.
 */
async function changeEmail() {
  const next = newEmail.value.trim().toLowerCase();
  if (!next || next === auth.profile?.email) return;
  changingEmail.value = true;
  emailError.value = "";
  emailMsg.value = "";
  try {
    const { error: e } = await supabase.auth.updateUser(
      { email: next },
      // Bina iske Supabase apni "Site URL" par bhejta hai, jo default me
      // localhost hoti hai. Tab link kaam to kar jaata hai, par user ek
      // khaali safed page par girta hai aur samajhta hai link toota hai.
      { emailRedirectTo: `${window.location.origin}/auth/callback` }
    );
    if (e) throw e;
    emailMsg.value =
      `Confirmation link sent to ${next}. Open it to finish. ` +
      `If a link also arrives at your current address, open that one too.`;
  } catch (e: any) {
    emailError.value = e?.message || "Could not start the email change";
  } finally {
    changingEmail.value = false;
  }
}

// -------------------------------------------------------------- password
const pw = reactive({ current: "", next: "", confirm: "" });
const changingPw = ref(false);
const pwMsg = ref("");
const pwError = ref("");

async function changePassword() {
  pwError.value = "";
  pwMsg.value = "";

  if (pw.next.length < 8) {
    pwError.value = "The new password must be at least 8 characters";
    return;
  }
  if (pw.next !== pw.confirm) {
    pwError.value = "The two new passwords do not match";
    return;
  }
  if (pw.next === pw.current) {
    pwError.value = "The new password is the same as the current one";
    return;
  }

  const email = auth.session?.user.email;
  if (!email) {
    pwError.value = "You are not signed in";
    return;
  }

  changingPw.value = true;
  try {
    // Purana password poochhna zaroori hai. Supabase khud nahi maangta —
    // uske liye session hi kaafi hai. Yani khuli hui screen chhod dene
    // par guzarne wala koi bhi password badal kar account le ja sakta
    // hai. Isliye pehle usi password se ek baar login karke tasalli.
    const { error: wrong } = await supabase.auth.signInWithPassword({
      email,
      password: pw.current,
    });
    if (wrong) {
      pwError.value = "Your current password is not right";
      return;
    }

    const { error: e } = await supabase.auth.updateUser({ password: pw.next });
    if (e) throw e;

    pw.current = "";
    pw.next = "";
    pw.confirm = "";
    pwMsg.value = "Password changed. Use the new one the next time you sign in.";
  } catch (e: any) {
    pwError.value = e?.message || "Could not change the password";
  } finally {
    changingPw.value = false;
  }
}

const form = reactive({
  full_name: "",
  specialization: "",
  mastery: "",
  experience_years: "" as string | number,
  show_publicly: false,
});

onMounted(async () => {
  const { data } = await supabase
    .from("profiles")
    .select("full_name, specialization, mastery, experience_years, show_publicly")
    .eq("id", auth.profile?.id ?? "")
    .single();
  if (data) {
    form.full_name = data.full_name ?? "";
    form.specialization = data.specialization ?? "";
    form.mastery = data.mastery ?? "";
    form.experience_years = data.experience_years ?? "";
    form.show_publicly = data.show_publicly ?? false;
  }
  newEmail.value = auth.profile?.email ?? "";

  // Preview me asli ginti dikhani hai, banaawati nahi — customer ko
  // yahi number dikhega.
  const { count } = await supabase
    .from("tickets")
    .select("id", { count: "exact", head: true })
    .eq("resolved_by", auth.profile?.id ?? "");
  resolvedCount.value = count ?? 0;

  loading.value = false;
});

async function save() {
  saving.value = true;
  error.value = "";
  saved.value = false;
  try {
    // kind / role_id / agent_code yahan bheje hi nahi jaate. Bhejte bhi
    // to DB ka trigger rok deta — par bhejna hi galat hai.
    const { error: e } = await supabase
      .from("profiles")
      .update({
        full_name: form.full_name.trim() || null,
        specialization: form.specialization.trim() || null,
        mastery: form.mastery.trim() || null,
        // Khali chhodne par null — "" bhejte to number column par error
        // aata, aur 0 bhejte to card par "0 years" chhap jaata.
        experience_years:
          form.experience_years === "" ? null : Number(form.experience_years),
        show_publicly: form.show_publicly,
      })
      .eq("id", auth.profile?.id ?? "");
    if (e) throw e;
    await auth.loadProfile();
    saved.value = true;
    setTimeout(() => (saved.value = false), 2500);
  } catch (e: any) {
    error.value = e?.message || "Could not save";
  } finally {
    saving.value = false;
  }
}
</script>
