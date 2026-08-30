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
            Apni problem bataiye &mdash; account banane ki zaroorat nahi
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
            label="Aapka naam"
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
            Iss email par hum jawab bhejenge
          </p>

          <FormControl
            v-model="form.company_name"
            label="Company ka naam"
            placeholder="New Client Pvt Ltd"
            :disabled="submitting"
          />

          <FormControl
            v-model="form.subject"
            label="Subject"
            placeholder="Ek line me problem"
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
            label="Problem detail me bataiye"
            placeholder="Kya hua, kab hua, kya karne par hua..."
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
            Ticket bhejiye
          </Button>
        </div>
      </div>

      <p class="mt-4 text-center text-p-sm text-ink-gray-5">
        Pehle se account hai?
        <RouterLink to="/login" class="underline">Login kijiye</RouterLink>
      </p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { supabase } from "@/lib/supabase";
import { Button, ErrorMessage, FormControl } from "frappe-ui";
import { reactive, ref } from "vue";
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

function validate(): string {
  if (!form.contact_name.trim()) return "Apna naam daaliye";
  if (!form.email.trim()) return "Email daaliye";
  // Bahut sakht regex jaan-boojh kar nahi rakha — asli check to email
  // bhejne par hi hota hai. Yahan sirf saaf galtiyan pakadni hain.
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)) return "Email sahi nahi lag raha";
  if (!form.subject.trim()) return "Subject daaliye";
  if (!form.description.trim()) return "Problem detail me bataiye";
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
    router.push({ name: "TicketSubmitted", params: { token: data } });
  } catch (e: any) {
    error.value = e?.message || "Ticket nahi bhej paye. Dobara koshish kijiye.";
  } finally {
    submitting.value = false;
  }
}
</script>
