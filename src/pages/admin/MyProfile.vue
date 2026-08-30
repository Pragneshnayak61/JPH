<template>
  <div class="p-6">
    <h1 class="text-xl font-semibold text-ink-gray-9">My profile</h1>
    <p class="mt-1 text-p-base text-ink-gray-6">
      What you are good at, so tickets reach the right person
    </p>

    <div v-if="loading" class="py-16 text-center">
      <LoadingIndicator class="mx-auto h-5 w-5 text-ink-gray-5" />
    </div>

    <div v-else class="mt-6 max-w-xl space-y-6">
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
          <div class="flex justify-between">
            <dt class="text-ink-gray-6">Email</dt>
            <dd class="text-ink-gray-8">{{ auth.profile?.email }}</dd>
          </div>
        </dl>
        <p class="mt-3 text-p-sm text-ink-gray-5">
          Other agents only ever see your ID &mdash; never your name or email.
          Only an administrator can change your ID or access level.
        </p>
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
        <span v-if="saved" class="text-p-sm text-ink-green-3">Saved</span>
      </div>
      <ErrorMessage :message="error" />
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
