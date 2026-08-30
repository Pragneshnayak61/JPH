<template>
  <div class="min-h-full bg-surface-gray-1 py-10">
    <div class="mx-auto w-full max-w-2xl px-4">
      <!-- header -->
      <div class="mb-6 flex items-center gap-3">
        <div
          class="flex h-10 w-10 items-center justify-center rounded-lg bg-surface-gray-7 text-lg font-semibold text-white"
        >
          J
        </div>
        <div>
          <h1 class="text-lg font-semibold text-ink-gray-9">JPH Support</h1>
          <p class="text-sm text-ink-gray-6">
            Tell us what went wrong &mdash; no account needed
          </p>
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

          <FormControl
            v-model="form.description"
            type="textarea"
            :rows="6"
            label="Describe the problem"
            placeholder="What happened, when it started, what you were doing..."
            :disabled="submitting"
          />

          <ErrorMessage :message="error" />

          <Button
            variant="solid"
            size="md"
            class="w-full"
            :loading="submitting"
            @click="submit"
          >
            Submit ticket
          </Button>
        </div>
      </div>

      <!-- is browser se bane purane tickets -->
      <div
        v-if="myTickets.length"
        class="mt-5 rounded-xl border border-outline-gray-2 bg-surface-base p-4"
      >
        <div class="flex items-center justify-between">
          <h2 class="text-p-base font-medium text-ink-gray-8">
            Your recent tickets
          </h2>
          <button
            class="text-p-sm text-ink-gray-5 underline hover:text-ink-gray-7"
            @click="forgetAll"
          >
            Forget
          </button>
        </div>
        <ul class="mt-2 divide-y divide-outline-gray-2">
          <li v-for="t in myTickets" :key="t.token">
            <RouterLink
              :to="{ name: 'GuestTicketView', params: { token: t.token } }"
              class="flex items-center justify-between py-2 text-p-base text-ink-gray-8 hover:text-ink-gray-9"
            >
              <span class="truncate pr-3">{{ t.subject }}</span>
              <FeatherIcon name="chevron-right" class="h-4 w-4 shrink-0 text-ink-gray-5" />
            </RouterLink>
          </li>
        </ul>
        <p class="mt-2 text-p-sm text-ink-gray-5">
          Saved on this device only. On another device or browser you will
          need the ticket link.
        </p>
      </div>

      <p class="mt-4 text-center text-p-sm text-ink-gray-5">
        Already have an account?
        <RouterLink to="/login" class="underline">Sign in</RouterLink>
      </p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { getMyTickets, forgetTickets, rememberTicket } from "@/lib/myTickets";
import { notify } from "@/lib/notify";
import { supabase } from "@/lib/supabase";
import { Button, ErrorMessage, FeatherIcon, FormControl } from "frappe-ui";
import { onMounted, reactive, ref } from "vue";
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

const myTickets = ref(getMyTickets());
function forgetAll() {
  forgetTickets();
  myTickets.value = [];
}
onMounted(() => (myTickets.value = getMyTickets()));

function validate(): string {
  if (!form.contact_name.trim()) return "Please enter your name";
  if (!form.email.trim()) return "Please enter your email";
  // Bahut sakht regex jaan-boojh kar nahi rakha — asli check to email
  // bhejne par hi hota hai. Yahan sirf saaf galtiyan pakadni hain.
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)) return "That email does not look right";
  if (!form.subject.trim()) return "Please enter a subject";
  if (!form.description.trim()) return "Please describe the problem";
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
      p_description: form.description.trim(),
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
