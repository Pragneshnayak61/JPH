<template>
  <div class="min-h-full bg-surface-gray-1 py-10">
    <div class="mx-auto w-full max-w-2xl px-4">
      <!-- header -->
      <div class="mb-6 flex items-center gap-3">
        <div
          class="flex h-10 w-10 shrink-0 items-center justify-center overflow-hidden rounded-lg text-lg font-semibold text-white"
          :style="{ background: s.logo_url ? '#fff' : s.accent_color }"
        >
          <img v-if="s.logo_url" :src="s.logo_url" alt="" class="h-full w-full object-contain" />
          <span v-else>{{ s.company_name.charAt(0).toUpperCase() }}</span>
        </div>
        <div class="min-w-0">
          <h1 class="text-lg font-semibold text-ink-gray-9">{{ s.guest_heading }}</h1>
          <p class="text-sm text-ink-gray-6">{{ s.guest_intro }}</p>
        </div>
      </div>

      <!-- form card -->
      <div
        class="rounded-xl border border-outline-gray-2 bg-surface-base p-6 shadow-sm"
      >
        <div class="space-y-4">
          <FormControl
            v-model="form.contact_name"
            label="Your name"
            placeholder="Ramesh Kumar"
            :disabled="submitting"
          />

          <FormControl
            v-model="form.email"
            type="email"
            label="Email"
            placeholder="ramesh@company.com"
            :disabled="submitting"
          />
          <p class="-mt-2 text-p-sm text-ink-gray-5">
            We will reply to this address
          </p>

          <FormControl
            v-model="form.company_name"
            label="Company name"
            placeholder="New Client Pvt Ltd"
            :disabled="submitting"
          />

          <FormControl
            v-model="form.subject"
            label="Subject"
            placeholder="One line about the problem"
            :disabled="submitting"
          />

          <FormControl
            v-model="form.priority"
            type="select"
            label="Priority"
            :options="priorityOptions"
            :disabled="submitting"
          />

          <div>
            <FormLabel label="Describe the problem" />
            <!-- Frappe jaisa rich editor. textarea ki jagah isliye ki
                 customer list, bold, link waghera laga sake — problem
                 samjhane me kaafi farq padta hai. -->
            <TextEditor
              ref="editorRef"
              class="mt-1 overflow-hidden rounded border border-outline-gray-2 bg-surface-gray-2 focus-within:border-outline-gray-4 focus-within:bg-surface-base"
              editor-class="prose-sm min-h-[140px] max-h-[320px] overflow-y-auto px-2 py-1.5 focus:outline-none"
              placeholder="What happened, when it started, what you were doing..."
              :content="form.description"
              :editable="!submitting"
              :fixed-menu="true"
              :upload-function="uploadImage"
              @change="(v: string) => (form.description = v)"
            />
          </div>

          <ErrorMessage :message="error" />

          <Button
            variant="solid"
            size="md"
            class="w-full"
            :loading="submitting"
            @click="submit"
          >
            {{ s.guest_submit_label }}
          </Button>
        </div>
      </div>

      <!--
        Pehle poori list yahin khuli rehti thi. Form ke neeche list
        dikhane se page bhara-bhara lagta tha aur asli kaam (ticket
        bhejna) peeche chala jaata. Ab sirf ek line ka link.
      -->
      <div v-if="myTickets.length" class="mt-4 text-center">
        <RouterLink
          :to="{ name: 'MyTickets' }"
          class="text-p-sm text-ink-gray-6 underline hover:text-ink-gray-8"
        >
          View your {{ myTickets.length }}
          {{ myTickets.length === 1 ? "ticket" : "tickets" }}
        </RouterLink>
      </div>

      <!-- team: naam nahi, sirf kaam -->
      <div v-if="team.length" class="mt-10">
        <h2 class="text-p-base font-semibold text-ink-gray-8">
          Who picks this up
        </h2>
        <p class="mt-0.5 text-p-sm text-ink-gray-6">
          Our team, by what they handle
        </p>

        <div class="mt-4 grid gap-3 sm:grid-cols-2">
          <div
            v-for="m in team"
            :key="m.code"
            class="rounded-xl border border-outline-gray-2 bg-surface-base p-4 transition-shadow hover:shadow-sm"
          >
            <div class="flex items-start gap-3">
              <span
                class="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg text-p-sm font-semibold text-white"
                :style="{ background: s.accent_color }"
              >
                {{ initials(m) }}
              </span>
              <div class="min-w-0 flex-1">
                <p class="truncate text-p-base font-medium text-ink-gray-9">
                  {{ m.specialization || "Support" }}
                </p>
                <p class="text-p-sm text-ink-gray-5">{{ m.code }}</p>
              </div>
            </div>

            <p v-if="m.mastery" class="mt-3 text-p-sm leading-relaxed text-ink-gray-7">
              {{ m.mastery }}
            </p>

            <!-- Ye do sirf tab dikhte hain jab value ho. Khali "0 tickets"
                 ya "0 years" dikhana ulta bharosa ghatata hai. -->
            <div
              v-if="m.resolved_count || m.experience_years"
              class="mt-3 flex flex-wrap gap-x-4 gap-y-1 border-t border-outline-gray-2 pt-3"
            >
              <span v-if="m.resolved_count" class="text-p-sm text-ink-gray-6">
                <strong class="font-semibold text-ink-gray-8">
                  {{ m.resolved_count }}
                </strong>
                {{ m.resolved_count === 1 ? "ticket" : "tickets" }} resolved
              </span>
              <span v-if="m.experience_years" class="text-p-sm text-ink-gray-6">
                <strong class="font-semibold text-ink-gray-8">
                  {{ m.experience_years }}
                </strong>
                {{ m.experience_years === 1 ? "year" : "years" }} experience
              </span>
            </div>
          </div>
        </div>
      </div>

      <p class="mt-4 text-center text-p-sm text-ink-gray-5">
        Already have an account?
        <RouterLink to="/login" class="underline">Sign in</RouterLink>
      </p>

      <SiteFooter />
    </div>
  </div>
</template>

<script setup lang="ts">
import { getMyTickets, rememberTicket } from "@/lib/myTickets";
import { notify } from "@/lib/notify";
import { uploadImage } from "@/lib/uploadImage";
import SiteFooter from "@/components/SiteFooter.vue";
import { useSettingsStore } from "@/stores/settings";
import { supabase } from "@/lib/supabase";
import {
  Button, ErrorMessage, FeatherIcon, FormControl, FormLabel, TextEditor,
} from "frappe-ui";
import { computed, onMounted, reactive, ref } from "vue";
import { useRouter } from "vue-router";

const router = useRouter();

const priorityOptions = [
  { label: "Low", value: "low" },
  { label: "Medium", value: "medium" },
  { label: "High", value: "high" },
  { label: "Urgent", value: "urgent" },
];

const form = reactive({
  contact_name: "",
  email: "",
  company_name: "",
  subject: "",
  priority: "medium",
  description: "",
});

const submitting = ref(false);
const error = ref("");

const settingsStore = useSettingsStore();
const s = computed(() => settingsStore.settings);

const myTickets = ref(getMyTickets());
type TeamMember = {
  code: string;
  specialization: string | null;
  mastery: string | null;
  experience_years: number | null;
  resolved_count: number;
};
const team = ref<TeamMember[]>([]);

/**
 * Badge par kya likhein. Specialization ka pehla akshar sabse kaam ka
 * hai ("N" for Network) — ID ka number us se kam batata hai.
 */
function initials(m: TeamMember) {
  const src = m.specialization?.trim();
  if (src) return src.charAt(0).toUpperCase();
  return m.code.replace(/[^0-9]/g, "") || "?";
}
onMounted(async () => {
  myTickets.value = getMyTickets();
  settingsStore.load();
  // Team na aaye to section chhupa rehta hai — koi error nahi dikhate,
  // ye page ka zaroori hissa nahi hai.
  const { data } = await supabase.rpc("public_team");
  team.value = data ?? [];
});

function validate(): string {
  if (!form.contact_name.trim()) return "Please enter your name";
  if (!form.email.trim()) return "Please enter your email";
  // Bahut sakht regex jaan-boojh kar nahi rakha — asli check to email
  // bhejne par hi hota hai. Yahan sirf saaf galtiyan pakadni hain.
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)) return "That email does not look right";
  if (!form.subject.trim()) return "Please enter a subject";
  // Editor khali hone par bhi "<p></p>" deta hai, isliye trim kaafi nahi.
  // Tags hata kar dekhte hain ki andar sach me kuch likha hai ya nahi.
  if (!form.description.replace(/<[^>]*>/g, "").trim())
    return "Please describe the problem";
  return "";
}

async function submit() {
  error.value = validate();
  if (error.value) return;

  submitting.value = true;
  try {
    // Seedha table par insert JAAN-BOOJH KAR nahi kiya.
    // Guest ke paas `tickets` table par koi permission nahi hai — sirf
    // ye function chala sakta hai. Isse do faayde:
    //   1. anon kabhi SELECT nahi kar sakta, to doosron ke ticket nahi padh sakta
    //   2. token wapas mil jaata hai (insert().select() ke liye SELECT
    //      permission chahiye hoti, jo hum dena hi nahi chahte)
    const { data, error: err } = await supabase.rpc("create_guest_ticket", {
      p_email: form.email.trim().toLowerCase(),
      p_contact_name: form.contact_name.trim(),
      p_company_name: form.company_name.trim(),
      p_subject: form.subject.trim(),
      p_description: form.description,
      p_priority: form.priority,
    });

    if (err) throw err;

    // Confirmation mail. Await NAHI kar rahe — mail bhejne me 2-3 second
    // lagte hain aur user ko itni der "Submitting..." dekhna padta.
    // Mail na jaye to bhi ticket ban chuka hai, wahi zyada zaroori hai.
    // Browser me yaad rakh lo, warna bookmark bhoolne par customer ka
    // ticket tak pahunchne ka koi raasta hi nahi bachta.
    rememberTicket({
      token: data,
      id: "",
      subject: form.subject.trim(),
      saved_at: new Date().toISOString(),
    });

    notify("ticket_created", { public_token: data });

    router.push({ name: "TicketSubmitted", params: { token: data } });
  } catch (e: any) {
    error.value = e?.message || "Could not submit the ticket. Please try again.";
  } finally {
    submitting.value = false;
  }
}
</script>
