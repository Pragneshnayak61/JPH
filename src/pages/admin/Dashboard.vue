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

    <!-- Filters. Ek hi row me, table ke upar — har column ka apna
         filter hota to milakar dekhna mushkil ho jaata. -->
    <div class="mt-5 flex flex-wrap items-end gap-3">
      <div class="w-40">
        <FormLabel label="Status" />
        <FormControl v-model="filters.status" type="select" :options="statusFilterOptions" />
      </div>
      <div class="w-40">
        <FormLabel label="Company" />
        <FormControl v-model="filters.company" type="select" :options="companyOptions" />
      </div>
      <div class="w-52">
        <FormLabel label="Agent" />
        <FormControl v-model="filters.agent" type="select" :options="agentFilterOptions" />
      </div>
      <div class="w-56">
        <FormLabel label="Search" />
        <FormControl v-model="filters.q" placeholder="Subject or company..." />
      </div>

      <div class="flex items-center gap-3 pb-1">
        <span class="text-p-sm text-ink-gray-6">
          {{ visibleTickets.length }} of {{ tickets.length }}
        </span>
        <button
          v-if="hasFilters"
          class="text-p-sm text-ink-gray-6 underline hover:text-ink-gray-8"
          @click="clearFilters"
        >
          Clear
        </button>
      </div>
    </div>

    <!-- Bulk bar. Tabhi dikhta hai jab kuch chuna ho — hamesha dikhane
         se ek khali patti pade rehti hai jo jagah bhi khaati hai aur
         batati kuch nahi. -->
    <div
      v-if="selected.size"
      class="mt-4 flex flex-wrap items-center gap-3 rounded-lg border border-outline-blue-2 bg-surface-blue-1 px-4 py-2.5"
    >
      <span class="text-p-base font-medium text-ink-gray-8">
        {{ selected.size }} selected
      </span>

      <div class="flex items-center gap-2">
        <span class="text-p-sm text-ink-gray-6">Assign to</span>
        <FormControl
          type="select"
          :model-value="bulkAgent"
          :options="agentOptions"
          :disabled="bulkBusy"
          @update:model-value="(v: string) => bulkAssign(v)"
        />
      </div>

      <div class="flex items-center gap-2">
        <span class="text-p-sm text-ink-gray-6">Status</span>
        <FormControl
          type="select"
          :model-value="''"
          :options="bulkStatusOptions"
          :disabled="bulkBusy"
          @update:model-value="(v: string) => bulkStatus(v)"
        />
      </div>

      <LoadingIndicator v-if="bulkBusy" class="h-4 w-4 text-ink-gray-5" />

      <button
        class="ml-auto text-p-sm text-ink-gray-6 underline hover:text-ink-gray-8"
        @click="selected.clear()"
      >
        Clear
      </button>
    </div>

    <!-- ticket list -->
    <div class="mt-6 overflow-x-auto rounded-lg border border-outline-gray-2">
      <table class="w-full min-w-[1020px] text-p-base">
        <thead class="bg-surface-gray-1 text-p-sm text-ink-gray-6">
          <tr>
            <th class="w-10 px-3 py-2">
              <input
                type="checkbox"
                class="rounded"
                :checked="allSelected"
                :indeterminate.prop="selected.size > 0 && !allSelected"
                @change="toggleAll"
              />
            </th>
            <th class="w-16 px-4 py-2 text-left font-medium">ID</th>
            <!-- Subject par koi width nahi: bachi hui saari jagah isi ko
                 milti hai. Baaki columns ko fix width di hai, warna wo
                 apne content se zyada jagah le lete the aur subject
                 bekaar me kat jaata tha. -->
            <th class="w-28 px-3 py-2 text-left font-medium">Company</th>
            <th class="px-3 py-2 text-left font-medium">Subject</th>
            <th class="w-36 px-3 py-2 text-left font-medium">From</th>
            <!-- Chhota rakha hai. Isme aksar "AG-01" hi hota hai, aur
                 specialization neeche doosri line me dene se column
                 zaroorat se dugna chauda ho jaata tha — wo jagah
                 subject ki thi. Ab specialization hover me. -->
            <th class="w-32 px-3 py-2 text-left font-medium">Assigned to</th>
            <th class="w-28 px-3 py-2 text-left font-medium">Status</th>
            <th class="w-28 px-3 py-2 text-left font-medium">Priority</th>
            <th class="w-28 px-3 py-2 text-left font-medium">Due</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="loading">
            <td colspan="9" class="px-4 py-10 text-center">
              <LoadingIndicator class="mx-auto h-5 w-5 text-ink-gray-5" />
            </td>
          </tr>
          <tr v-else-if="error">
            <td colspan="9" class="px-4 py-10 text-center text-ink-red-3">
              {{ error }}
            </td>
          </tr>
          <tr v-else-if="!sortedTickets.length">
            <td colspan="9" class="px-4 py-10 text-center text-ink-gray-5">
              <!-- Filter lagi ho to "No tickets yet" jhooth hai —
                   tickets hain, bas dikh nahi rahe. -->
              {{ hasFilters ? "No tickets match these filters." : "No tickets yet." }}
            </td>
          </tr>
          <tr
            v-for="t in sortedTickets"
            v-else
            :key="t.id"
            class="cursor-pointer border-t border-outline-gray-2 hover:bg-surface-gray-1"
            @click="router.push(`/admin/tickets/${t.id}`)"
          >
            <!-- @click.stop: bina iske checkbox dabate hi row ka click
                 bhi chalta hai aur ticket khul jaata hai. -->
            <td class="px-3 py-2.5" @click.stop>
              <input
                type="checkbox"
                class="rounded"
                :checked="selected.has(t.id)"
                @change="toggleOne(t.id)"
              />
            </td>
            <td class="px-4 py-2.5 font-mono text-p-sm text-ink-gray-5">
              {{ t.id }}
            </td>
            <td class="px-3 py-2.5">
              <span
                v-if="t.company_name"
                class="block truncate text-p-sm text-ink-gray-7"
                :title="t.company_name"
              >
                {{ t.company_name }}
              </span>
              <span v-else class="text-p-sm text-ink-gray-4">—</span>
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
              <!--
                Jis ticket ko kisi customer ne nahi bheja (staff ne khud
                banaya, ya import hua), uska raised_by_email banane wale
                ka apna hi email hota hai — kyunki wo column NOT NULL hai
                aur khali nahi chhoda ja sakta.

                Wo email dikhane ka koi matlab nahi: 77 rows me ek hi
                cheez chhap jaati hai. Aise ticket par "Internal" likhna
                zyada sach hai — usse ye bhi pata chalta hai ki ye bahar
                se nahi aaya.
              -->
              <span
                class="block truncate text-p-sm text-ink-gray-6"
                :title="fromLabel(t)"
              >
                {{ fromLabel(t) }}
              </span>
            </td>
            <td class="px-3 py-2.5">
              <div
                v-if="t.assigned_to && staff[t.assigned_to]"
                class="flex items-center gap-2"
                :title="assignedTitle(t)"
              >
                <Avatar :label="staff[t.assigned_to].label" size="sm" />
                <span class="truncate text-p-sm text-ink-gray-8">
                  {{ staff[t.assigned_to].label }}
                </span>
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
import { notify } from "@/lib/notify";
import { useAuthStore } from "@/stores/auth";
import {
  Avatar, Badge, Button, Dialog, ErrorMessage, FormControl, FormLabel,
  LoadingIndicator, toast,
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
  company_name: string | null;
  created_by: string | null;
  due_date: string | null;
  created_at: string;
};

const tickets = ref<Ticket[]>([]);
const loading = ref(true);
const error = ref("");
const staff = ref<
  Record<string, { label: string; email: string | null; specialization: string | null }>
>({});

/**
 * Kaam wale tickets upar, nipte hue neeche.
 *
 * Ye SQL me nahi ho sakta tha — PostgREST me "CASE status WHEN ..." wali
 * ordering nahi likh sakte. 77 rows par client par sort karna sasta hai.
 *
 * Andar deadline ke hisaab se: jiski date sabse pehle nikal rahi hai wo
 * upar. Bina due date wale sabse neeche — un par koi deadline hai hi nahi.
 */
const STATUS_ORDER: Record<string, number> = {
  open: 0, replied: 1, resolved: 2, closed: 3,
};

const filters = reactive({ status: "", company: "", agent: "", q: "" });

const hasFilters = computed(
  () => !!(filters.status || filters.company || filters.agent || filters.q.trim())
);
function clearFilters() {
  Object.assign(filters, { status: "", company: "", agent: "", q: "" });
}

const statusFilterOptions = [
  { label: "All", value: "" },
  { label: "Open", value: "open" },
  { label: "Replied", value: "replied" },
  { label: "Resolved", value: "resolved" },
  { label: "Closed", value: "closed" },
];

// Company ki list tickets se hi banti hai — alag table nahi hai, aur
// haath se likhne par nayi company jodte hi list purani ho jaati.
const companyOptions = computed(() => {
  const names = [...new Set(
    tickets.value.map((t) => t.company_name).filter(Boolean) as string[]
  )].sort();
  return [{ label: "All", value: "" },
          ...names.map((n) => ({ label: n, value: n }))];
});

const agentFilterOptions = computed(() => [
  { label: "All", value: "" },
  { label: "Unassigned", value: "__none__" },
  ...Object.entries(staff.value).map(([id, d]) => ({
    label: d.specialization ? `${d.label} · ${d.specialization}` : d.label,
    value: id,
  })),
]);

const visibleTickets = computed(() =>
  tickets.value.filter((t) => {
    if (filters.status && t.status !== filters.status) return false;
    if (filters.company && t.company_name !== filters.company) return false;
    if (filters.agent === "__none__" && t.assigned_to) return false;
    if (filters.agent && filters.agent !== "__none__"
        && t.assigned_to !== filters.agent) return false;
    const q = filters.q.trim().toLowerCase();
    if (q && !`${t.subject} ${t.company_name ?? ""}`.toLowerCase().includes(q))
      return false;
    return true;
  })
);

const sortedTickets = computed(() =>
  [...visibleTickets.value].sort((a, b) => {
    const s = (STATUS_ORDER[a.status] ?? 9) - (STATUS_ORDER[b.status] ?? 9);
    if (s !== 0) return s;

    // Nipte hue tickets me deadline ka matlab nahi — unme naya pehle.
    if (a.status === "resolved" || a.status === "closed") {
      return b.created_at.localeCompare(a.created_at);
    }

    // due_date null ko "bahut door" maan lete hain, taaki wo neeche jaye
    // aur upar wo aayein jinki tareekh sach me paas hai.
    const ad = a.due_date ?? "9999-12-31";
    const bd = b.due_date ?? "9999-12-31";
    if (ad !== bd) return ad.localeCompare(bd);
    return b.created_at.localeCompare(a.created_at);
  })
);

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

// ---------------------------------------------------------------- bulk
// Set isliye ki .has() O(1) hai. 77 rows par har checkbox render me
// array.includes() chalana bekaar ka kaam hai.
const selected = reactive(new Set<number>());
const bulkAgent = ref("");
const bulkBusy = ref(false);

const agentOptions = computed(() => [
  { label: "Choose agent...", value: "" },
  { label: "Unassign", value: "__none__" },
  ...Object.entries(staff.value).map(([id, d]) => ({
    label: d.specialization ? `${d.label} · ${d.specialization}` : d.label,
    value: id,
  })),
]);

const bulkStatusOptions = [
  { label: "Change status...", value: "" },
  { label: "Open", value: "open" },
  { label: "Replied", value: "replied" },
  { label: "Resolved", value: "resolved" },
  { label: "Closed", value: "closed" },
];

// Tulna DIKHNE WALE rows se, saare tickets se nahi. Filter lagi ho to
// toggleAll sirf dikhne wale chunta hai — agar yahan poori list se
// tulna karte, to checkbox kabhi tick hi na hota aur dobara click
// karne par clear hone ke bajaye aur jud jaate.
const allSelected = computed(
  () =>
    sortedTickets.value.length > 0 &&
    sortedTickets.value.every((t) => selected.has(t.id))
);

function toggleAll() {
  if (allSelected.value) selected.clear();
  else sortedTickets.value.forEach((t) => selected.add(t.id));
}

function toggleOne(id: number) {
  if (selected.has(id)) selected.delete(id);
  else selected.add(id);
}

async function applyToSelected(changes: Record<string, unknown>, done: string) {
  bulkBusy.value = true;
  try {
    const ids = [...selected];
    const { error } = await supabase
      .from("tickets")
      .update(changes)
      .in("id", ids);
    if (error) throw error;
    toast.success(`${ids.length} ${ids.length === 1 ? "ticket" : "tickets"} ${done}`);
    selected.clear();
    await load();
  } catch (e: any) {
    toast.error(e?.message || "Could not update the tickets");
  } finally {
    bulkBusy.value = false;
    bulkAgent.value = "";
  }
}

async function bulkAssign(v: string) {
  if (!v) return;
  const ids = [...selected];

  // "Unassign" ke liye khali string nahi bhej sakte — assigned_to uuid
  // column hai aur "" uske liye invalid hai.
  await applyToSelected(
    { assigned_to: v === "__none__" ? null : v },
    v === "__none__" ? "unassigned" : "assigned"
  );

  // Sab tickets ki EK mail, har ticket ki alag nahi. 77 assign karne par
  // 77 mail bhejna Gmail ki din bhar ki limit hi kha jaata, aur agent ke
  // inbox ka bhi bura haal karta.
  if (v !== "__none__" && ids.length) {
    notify("ticket_assigned", { agent_id: v, ticket_ids: ids });
  }
}

function bulkStatus(v: string) {
  if (!v) return;
  applyToSelected({ status: v }, "updated");
}

/**
 * "From" me kya dikhana hai.
 *
 * Teen soorat hain:
 *   1. Customer ne bheja  -> usne jo naam likha
 *   2. Staff ne banaya    -> banane wale ki pehchaan
 *   3. Na naam, na creator -> jo email ticket par pada hai
 *
 * Doosri soorat me pehchaan ka wahi niyam lagta hai jo poore app me hai:
 * admin ko email, baaki sabko sirf ID. Email server se hi tabhi aata
 * hai jab dekhne wala admin ho (staff_directory me), isliye yahan
 * chhupane ki zaroorat nahi — jo hai hi nahi wo dikhega kaise.
 */
function fromLabel(t: Ticket) {
  if (t.contact_name) return t.contact_name;
  const s = t.created_by ? staff.value[t.created_by] : null;
  if (s) return s.email || s.label;
  return t.raised_by_email;
}

/**
 * Assigned column ka hover text — naam ke saath specialization.
 *
 * Column me sirf ID dikhti hai (jagah bachane ko). Specialization wahi
 * cheez hai jisse pata chalta hai ki ticket sahi bande ke paas hai ya
 * nahi, isliye use gayab nahi kar sakte — hover me daal diya.
 */
function assignedTitle(t: Ticket) {
  const s = t.assigned_to ? staff.value[t.assigned_to] : null;
  if (!s) return "";
  return s.specialization ? `${s.label} · ${s.specialization}` : s.label;
}

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

/**
 * Tickets aur staff directory laata hai.
 *
 * Pehle ye seedha onMounted ke andar likha tha, aur maine bulk wale
 * code me `load()` bula diya — jo tha hi nahi. Isliye bulk assign par
 * "load is not defined" aa jaata tha: update DATABASE ME HO CHUKA
 * hota tha, bas list refresh nahi hoti thi aur error dikh jaata tha.
 */
async function load() {
  try {
    const { data, error: err } = await supabase
      .from("tickets")
      .select(
        "id, subject, status, priority, contact_name, raised_by_email, assigned_to, company_name, created_by, due_date, created_at"
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
        {
          label: d.label as string,
          email: (d.email ?? null) as string | null,
          specialization: d.specialization as string | null,
        },
      ])
    );
  } catch (e: any) {
    error.value = e?.message || "Could not load tickets";
  } finally {
    loading.value = false;
  }
}

onMounted(load);
</script>
