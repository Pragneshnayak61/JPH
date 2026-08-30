<template>
  <div class="p-6">
    <div class="flex items-start justify-between">
      <div>
        <h1 class="text-xl font-semibold text-ink-gray-9">Dashboard</h1>
        <p class="mt-1 text-p-base text-ink-gray-6">Every ticket lands here</p>
      </div>
      <Button variant="solid" @click="openNew">New ticket</Button>
    </div>

    <!-- stat tiles -->
    <div class="mt-5 grid grid-cols-2 gap-3 sm:grid-cols-4">
      <div
        v-for="s in stats"
        :key="s.label"
        class="rounded-lg border border-outline-gray-2 p-4"
      >
        <p class="text-p-sm text-ink-gray-6">{{ s.label }}</p>
        <p class="mt-1 text-2xl font-semibold text-ink-gray-9">{{ s.value }}</p>
      </div>
    </div>

    <!-- ticket list -->
    <div class="mt-6 overflow-hidden rounded-lg border border-outline-gray-2">
      <div
        class="grid grid-cols-12 gap-3 border-b border-outline-gray-2 bg-surface-gray-1 px-4 py-2 text-p-sm font-medium text-ink-gray-6"
      >
        <div class="col-span-1">#</div>
        <div class="col-span-5">Subject</div>
        <div class="col-span-2">From</div>
        <div class="col-span-2">Status</div>
        <div class="col-span-2">Priority</div>
      </div>

      <div v-if="loading" class="px-4 py-10 text-center text-ink-gray-5">
        <LoadingIndicator class="mx-auto h-5 w-5" />
      </div>

      <div v-else-if="error" class="px-4 py-10 text-center">
        <p class="text-p-base text-ink-red-3">{{ error }}</p>
      </div>

      <div
        v-else-if="!tickets.length"
        class="px-4 py-10 text-center text-p-base text-ink-gray-5"
      >
        No tickets yet.
      </div>

      <RouterLink
        v-for="t in tickets"
        v-else
        :key="t.id"
        :to="`/admin/tickets/${t.id}`"
        class="grid grid-cols-12 items-center gap-3 border-b border-outline-gray-2 px-4 py-2.5 text-p-base last:border-0 hover:bg-surface-gray-1"
      >
        <div class="col-span-1 font-mono text-p-sm text-ink-gray-5">
          {{ t.id }}
        </div>
        <div class="col-span-5 truncate text-ink-gray-8">{{ t.subject }}</div>
        <div class="col-span-2 truncate text-p-sm text-ink-gray-6">
          {{ t.contact_name || t.raised_by_email }}
        </div>
        <div class="col-span-2">
          <Badge :theme="statusTheme[t.status]" variant="subtle">
            {{ t.status }}
          </Badge>
        </div>
        <div class="col-span-2">
          <Badge :theme="priorityTheme[t.priority]" variant="subtle">
            {{ t.priority }}
          </Badge>
        </div>
      </RouterLink>
    </div>

    <!-- Agent/admin khud ticket bana sake — jaise phone par baat hui ho -->
    <Dialog v-model="showNew" :options="{ title: 'New ticket', size: 'md' }">
      <template #body-content>
        <div class="space-y-3">
          <FormControl
            v-model="form.contact_name"
            label="Customer name"
            placeholder="Ramesh Kumar"
            :disabled="creating"
          />
          <FormControl
            v-model="form.email"
            type="email"
            label="Customer email"
            placeholder="ramesh@company.com"
            :disabled="creating"
          />
          <FormControl
            v-model="form.company_name"
            label="Company"
            placeholder="New Client Pvt Ltd"
            :disabled="creating"
          />
          <FormControl
            v-model="form.subject"
            label="Subject"
            placeholder="One line about the problem"
            :disabled="creating"
          />
          <FormControl
            v-model="form.priority"
            type="select"
            label="Priority"
            :options="priorityOptions"
            :disabled="creating"
          />
          <FormControl
            v-model="form.description"
            type="textarea"
            :rows="5"
            label="What is the problem?"
            :disabled="creating"
          />
          <ErrorMessage :message="createError" />
        </div>
      </template>
      <template #actions>
        <Button
          variant="solid"
          class="w-full"
          :loading="creating"
          @click="createTicket"
        >
          Create ticket
        </Button>
      </template>
    </Dialog>
  </div>
</template>

<script setup lang="ts">
import { supabase } from "@/lib/supabase";
import { useAuthStore } from "@/stores/auth";
import {
  Badge, Button, Dialog, ErrorMessage, FormControl, LoadingIndicator,
} from "frappe-ui";
import { computed, onMounted, reactive, ref } from "vue";
import { useRouter } from "vue-router";

type Ticket = {
  id: number;
  subject: string;
  status: string;
  priority: string;
  contact_name: string | null;
  raised_by_email: string;
  created_at: string;
};

const tickets = ref<Ticket[]>([]);
const loading = ref(true);
const error = ref("");

const statusTheme: Record<string, string> = {
  open: "orange",
  replied: "blue",
  resolved: "green",
  closed: "gray",
};

const priorityTheme: Record<string, string> = {
  urgent: "red",
  high: "orange",
  medium: "blue",
  low: "gray",
};

const stats = computed(() => {
  const by = (s: string) => tickets.value.filter((t) => t.status === s).length;
  return [
    { label: "Total", value: tickets.value.length },
    { label: "Open", value: by("open") },
    { label: "Replied", value: by("replied") },
    { label: "Resolved", value: by("resolved") },
  ];
});

// ---------------------------------------------------------------- new ticket
const auth = useAuthStore();
const router = useRouter();
const showNew = ref(false);
const creating = ref(false);
const createError = ref("");
const priorityOptions = [
  { label: "Low", value: "low" },
  { label: "Medium", value: "medium" },
  { label: "High", value: "high" },
  { label: "Urgent", value: "urgent" },
];
const form = reactive({
  contact_name: "", email: "", company_name: "",
  subject: "", priority: "medium", description: "",
});

function openNew() {
  createError.value = "";
  Object.assign(form, {
    contact_name: "", email: "", company_name: "",
    subject: "", priority: "medium", description: "",
  });
  showNew.value = true;
}

async function createTicket() {
  createError.value = "";
  if (!form.email.trim()) return (createError.value = "Customer email is required");
  if (!form.subject.trim()) return (createError.value = "Subject is required");
  if (!form.description.trim()) return (createError.value = "Please describe the problem");

  creating.value = true;
  try {
    // Yahan seedha insert kar rahe hain, guest wala RPC nahi — staff ke
    // paas tickets par insert ki permission hai (tickets_staff_insert),
    // aur created_by set karna hai taaki pata rahe kisne banaya.
    const { data, error: e } = await supabase
      .from("tickets")
      .insert({
        subject: form.subject.trim(),
        description: form.description.trim(),
        priority: form.priority,
        raised_by_email: form.email.trim().toLowerCase(),
        contact_name: form.contact_name.trim() || null,
        company_name: form.company_name.trim() || null,
        created_by: auth.profile?.id ?? null,
      })
      .select("id")
      .single();
    if (e) throw e;

    showNew.value = false;
    router.push(`/admin/tickets/${data.id}`);
  } catch (e: any) {
    createError.value = e?.message || "Could not create the ticket";
  } finally {
    creating.value = false;
  }
}

onMounted(async () => {
  try {
    const { data, error: err } = await supabase
      .from("tickets")
      .select("id, subject, status, priority, contact_name, raised_by_email, created_at")
      .order("created_at", { ascending: false });
    if (err) throw err;
    tickets.value = data ?? [];
  } catch (e: any) {
    error.value = e?.message || "Could not load tickets";
  } finally {
    loading.value = false;
  }
});
</script>
