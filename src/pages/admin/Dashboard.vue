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
    <div class="mt-6 overflow-x-auto rounded-lg border border-outline-gray-2">
      <table class="w-full min-w-[820px] text-p-base">
        <thead class="bg-surface-gray-1 text-p-sm text-ink-gray-6">
          <tr>
            <th class="w-16 px-4 py-2 text-left font-medium">ID</th>
            <!-- Subject par koi width nahi: bachi hui saari jagah isi ko
                 milti hai. Baaki columns ko fix width di hai, warna wo
                 apne content se zyada jagah le lete the aur subject
                 bekaar me kat jaata tha. -->
            <th class="px-3 py-2 text-left font-medium">Subject</th>
            <th class="w-44 px-3 py-2 text-left font-medium">From</th>
            <th class="w-48 px-3 py-2 text-left font-medium">Assigned to</th>
            <th class="w-28 px-3 py-2 text-left font-medium">Status</th>
            <th class="w-28 px-3 py-2 text-left font-medium">Priority</th>
            <th class="w-28 px-3 py-2 text-left font-medium">Due</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="loading">
            <td colspan="7" class="px-4 py-10 text-center">
              <LoadingIndicator class="mx-auto h-5 w-5 text-ink-gray-5" />
            </td>
          </tr>
          <tr v-else-if="error">
            <td colspan="7" class="px-4 py-10 text-center text-ink-red-3">
              {{ error }}
            </td>
          </tr>
          <tr v-else-if="!tickets.length">
            <td colspan="7" class="px-4 py-10 text-center text-ink-gray-5">
              No tickets yet.
            </td>
          </tr>
          <tr
            v-for="t in tickets"
            v-else
            :key="t.id"
            class="cursor-pointer border-t border-outline-gray-2 hover:bg-surface-gray-1"
            @click="router.push(`/admin/tickets/${t.id}`)"
          >
            <td class="px-4 py-2.5 font-mono text-p-sm text-ink-gray-5">
              {{ t.id }}
            </td>
            <td class="max-w-0 px-3 py-2.5">
              <!-- title se hover par poora subject dikhta hai. Custom
                   tooltip ke bajaye ye isliye ki table me har row par
                   tooltip lagane se scroll bhi bhaari ho jaata hai. -->
              <span
                class="block truncate font-medium text-ink-gray-8"
                :title="t.subject"
              >
                {{ t.subject }}
              </span>
            </td>
            <td class="max-w-0 px-3 py-2.5">
              <span
                class="block truncate text-p-sm text-ink-gray-6"
                :title="t.contact_name || t.raised_by_email"
              >
                {{ t.contact_name || t.raised_by_email }}
              </span>
            </td>
            <td class="px-3 py-2.5">
              <div
                v-if="t.assigned_to && staff[t.assigned_to]"
                class="flex items-center gap-2"
              >
                <Avatar :label="staff[t.assigned_to].label" size="sm" />
                <div class="min-w-0 leading-tight">
                  <p class="truncate text-p-sm text-ink-gray-8">
                    {{ staff[t.assigned_to].label }}
                  </p>
                  <p
                    v-if="staff[t.assigned_to].specialization"
                    class="truncate text-p-sm text-ink-gray-5"
                  >
                    {{ staff[t.assigned_to].specialization }}
                  </p>
                </div>
              </div>
              <!-- Unassigned ko halka nahi, dikhne wala rakha hai — yahi
                   wo ticket hai jise koi utha hi nahi raha. -->
              <Badge v-else theme="orange" variant="subtle">Unassigned</Badge>
            </td>
            <td class="px-3 py-2.5">
              <Badge :theme="statusTheme[t.status]" variant="subtle">
                {{ t.status }}
              </Badge>
            </td>
            <td class="px-3 py-2.5">
              <Badge :theme="priorityTheme[t.priority]" variant="subtle">
                {{ t.priority }}
              </Badge>
            </td>
            <td class="px-3 py-2.5">
              <span
                v-if="t.due_date"
                class="text-p-sm"
                :class="isOverdue(t) ? 'font-medium text-ink-red-3' : 'text-ink-gray-6'"
              >
                {{ formatDue(t.due_date) }}
              </span>
              <span v-else class="text-p-sm text-ink-gray-4">—</span>
            </td>
          </tr>
        </tbody>
      </table>
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

          <div>
            <FormControl
              v-model="form.due_date"
              type="date"
              label="Due date"
              :disabled="creating"
            />
            <p class="mt-1 text-p-sm text-ink-gray-5">
              Leave blank and one is set from the priority.
            </p>
          </div>
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
  Avatar, Badge, Button, Dialog, ErrorMessage, FormControl, LoadingIndicator,
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
  assigned_to: string | null;
  due_date: string | null;
  created_at: string;
};

const tickets = ref<Ticket[]>([]);
const loading = ref(true);
const error = ref("");
const staff = ref<Record<string, { label: string; specialization: string | null }>>({});

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

function formatDue(d: string) {
  return new Date(d).toLocaleDateString(undefined, {
    day: "numeric", month: "short",
  });
}

// Band ticket kabhi overdue nahi hota — kaam ho gaya, deri ab maayne
// nahi rakhti. Warna resolved tickets bhi laal dikhte rehte.
function isOverdue(t: Ticket) {
  if (!t.due_date || ["resolved", "closed"].includes(t.status)) return false;
  return new Date(t.due_date) < new Date(new Date().toDateString());
}

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
  subject: "", priority: "medium", description: "", due_date: "",
});

function openNew() {
  createError.value = "";
  Object.assign(form, {
    contact_name: "", email: "", company_name: "",
    subject: "", priority: "medium", description: "", due_date: "",
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
        // khali chhoda to DB ka trigger priority se bhar dega
        due_date: form.due_date || null,
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
      .select(
        "id, subject, status, priority, contact_name, raised_by_email, assigned_to, due_date, created_at"
      )
      .order("created_at", { ascending: false });
    if (err) throw err;
    tickets.value = data ?? [];

    // Naam seedha profiles se nahi le sakte — RLS agent ko doosri
    // profiles padhne hi nahi deti. staff_directory admin ko asli naam
    // aur agent ko sirf ID deta hai.
    const { data: dir } = await supabase.rpc("staff_directory");
    // label aur specialization alag rakhte hain — ek hi string bana dete
    // to UI me do line me nahi dikha paate.
    staff.value = Object.fromEntries(
      (dir ?? []).map((d: any) => [
        d.id,
        { label: d.label as string, specialization: d.specialization as string | null },
      ])
    );
  } catch (e: any) {
    error.value = e?.message || "Could not load tickets";
  } finally {
    loading.value = false;
  }
});
</script>
