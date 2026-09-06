<template>
  <div class="mx-auto max-w-5xl px-6 py-6">
    <div class="mb-5 flex items-center justify-between gap-3">
      <div>
        <h1 class="text-lg font-semibold text-ink-gray-9">Operations setup</h1>
        <p class="mt-0.5 text-p-sm text-ink-gray-6">
          Decide what gets checked, for whom, and how often
        </p>
      </div>
      <Button @click="router.push('/admin/operations')">
        <template #prefix><FeatherIcon name="check-square" class="h-4 w-4" /></template>
        Today's checklist
      </Button>
    </div>

    <!-- tabs -->
    <div class="mb-5 flex gap-1 border-b border-outline-gray-2">
      <button
        v-for="t in tabs"
        :key="t.key"
        class="-mb-px border-b-2 px-3 py-2 text-p-sm"
        :class="
          tab === t.key
            ? 'border-ink-gray-9 font-medium text-ink-gray-9'
            : 'border-transparent text-ink-gray-6 hover:text-ink-gray-8'
        "
        @click="tab = t.key"
      >
        {{ t.label }}
      </button>
    </div>

    <div v-if="loading" class="py-16 text-center">
      <LoadingIndicator class="mx-auto h-6 w-6 text-ink-gray-5" />
    </div>

    <ErrorMessage :message="error" class="mb-4" />

    <template v-if="!loading">
      <!-- ------------------------------------------------- clients -->
      <section v-if="tab === 'clients'">
        <div class="mb-3 flex items-center justify-between">
          <p class="text-p-sm text-ink-gray-6">
            A client is an organisation you look after. Tickets already link
            to these by email domain.
          </p>
          <Button variant="solid" @click="openClient()">Add client</Button>
        </div>

        <div v-if="!clients.length" class="rounded-lg border border-outline-gray-2 py-12 text-center">
          <p class="text-p-base text-ink-gray-6">No clients yet</p>
          <p class="mt-1 text-p-sm text-ink-gray-5">
            Add your first client to start building its checklist.
          </p>
        </div>

        <div v-else class="overflow-hidden rounded-lg border border-outline-gray-2">
          <table class="w-full text-left">
            <thead class="bg-surface-gray-1 text-p-sm text-ink-gray-6">
              <tr>
                <th class="px-4 py-2.5 font-medium">Client</th>
                <th class="px-4 py-2.5 font-medium">Email domain</th>
                <th class="px-4 py-2.5 font-medium">Devices</th>
                <th class="px-4 py-2.5 font-medium">Checks</th>
                <th class="px-4 py-2.5"></th>
              </tr>
            </thead>
            <tbody class="divide-y divide-outline-gray-2">
              <tr v-for="c in clients" :key="c.id">
                <td class="px-4 py-2.5 font-medium text-ink-gray-8">{{ c.name }}</td>
                <td class="px-4 py-2.5 text-p-sm text-ink-gray-6">
                  {{ c.email_domain || "—" }}
                </td>
                <td class="px-4 py-2.5 text-p-sm text-ink-gray-6">
                  {{ devices.filter((d) => d.organization_id === c.id).length }}
                </td>
                <td class="px-4 py-2.5 text-p-sm text-ink-gray-6">
                  {{ tasks.filter((t) => t.organization_id === c.id && t.is_active).length }}
                </td>
                <td class="px-4 py-2.5 text-right">
                  <button class="text-p-sm text-ink-gray-6 underline" @click="openClient(c)">
                    Edit
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      <!-- ------------------------------------------------- devices -->
      <section v-else-if="tab === 'devices'">
        <div class="mb-3 flex flex-wrap items-center justify-between gap-2">
          <FormControl
            v-model="deviceClient"
            type="select"
            :options="clientOptions"
            class="w-56"
          />
          <Button variant="solid" :disabled="!clients.length" @click="openDevice()">
            Add device
          </Button>
        </div>

        <p class="mb-3 text-p-sm text-ink-gray-6">
          Servers, firewalls, NVRs — whatever this client actually has. No two
          clients need the same list.
        </p>

        <div v-if="!shownDevices.length" class="rounded-lg border border-outline-gray-2 py-12 text-center">
          <p class="text-p-base text-ink-gray-6">
            {{ clients.length ? "No devices for this client" : "Add a client first" }}
          </p>
        </div>

        <div v-else class="overflow-hidden rounded-lg border border-outline-gray-2">
          <table class="w-full text-left">
            <thead class="bg-surface-gray-1 text-p-sm text-ink-gray-6">
              <tr>
                <th class="px-4 py-2.5 font-medium">Device</th>
                <th class="px-4 py-2.5 font-medium">Type</th>
                <th class="px-4 py-2.5 font-medium">Hostname / IP</th>
                <th class="px-4 py-2.5 font-medium">Location</th>
                <th class="px-4 py-2.5"></th>
              </tr>
            </thead>
            <tbody class="divide-y divide-outline-gray-2">
              <tr v-for="d in shownDevices" :key="d.id">
                <td class="px-4 py-2.5">
                  <span class="font-medium text-ink-gray-8">{{ d.name }}</span>
                  <Badge v-if="!d.is_active" theme="gray" variant="subtle" class="ml-2">
                    Inactive
                  </Badge>
                </td>
                <td class="px-4 py-2.5 text-p-sm text-ink-gray-6">
                  {{ deviceKindLabel(d.kind) }}
                </td>
                <td class="px-4 py-2.5 text-p-sm text-ink-gray-6">
                  {{ [d.hostname, d.ip_address].filter(Boolean).join(" · ") || "—" }}
                </td>
                <td class="px-4 py-2.5 text-p-sm text-ink-gray-6">{{ d.location || "—" }}</td>
                <td class="px-4 py-2.5 text-right">
                  <button class="text-p-sm text-ink-gray-6 underline" @click="openDevice(d)">
                    Edit
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      <!-- ------------------------------------------------- library -->
      <section v-else-if="tab === 'library'">
        <div class="mb-3 flex items-center justify-between">
          <p class="text-p-sm text-ink-gray-6">
            Reusable checks. Nothing here runs on its own — you pick from this
            list when building a client's checklist.
          </p>
          <Button variant="solid" @click="openCatalog()">Add check</Button>
        </div>

        <div
          v-for="cat in categories"
          :key="cat.id"
          class="mb-4 overflow-hidden rounded-lg border border-outline-gray-2"
        >
          <div class="flex items-center justify-between bg-surface-gray-1 px-4 py-2">
            <span class="text-p-sm font-medium text-ink-gray-8">{{ cat.name }}</span>
            <span class="text-p-sm text-ink-gray-5">
              {{ catalog.filter((c) => c.category_id === cat.id).length }}
            </span>
          </div>
          <ul class="divide-y divide-outline-gray-2">
            <li
              v-for="item in catalog.filter((c) => c.category_id === cat.id)"
              :key="item.id"
              class="flex items-start justify-between gap-3 px-4 py-2.5"
            >
              <div class="min-w-0">
                <p class="text-p-sm font-medium text-ink-gray-8">{{ item.name }}</p>
                <p v-if="item.description" class="text-p-sm text-ink-gray-5">
                  {{ item.description }}
                </p>
              </div>
              <button class="shrink-0 text-p-sm text-ink-gray-6 underline" @click="openCatalog(item)">
                Edit
              </button>
            </li>
          </ul>
        </div>
      </section>

      <!-- ----------------------------------------------- checklists -->
      <section v-else>
        <div class="mb-3 flex flex-wrap items-center justify-between gap-2">
          <FormControl
            v-model="taskClient"
            type="select"
            :options="clientOptions"
            class="w-56"
          />
          <div class="flex gap-2">
            <Button :disabled="!taskClient" @click="openPicker">Add from library</Button>
            <Button variant="solid" :disabled="!taskClient" @click="openTask()">
              Add check
            </Button>
          </div>
        </div>

        <p class="mb-3 text-p-sm text-ink-gray-6">
          This is the list that runs every day. Each client has its own — Client
          A can have AD and VMware while Client B has CCTV and a firewall.
        </p>

        <div v-if="!shownTasks.length" class="rounded-lg border border-outline-gray-2 py-12 text-center">
          <p class="text-p-base text-ink-gray-6">
            {{ clients.length ? "No checks for this client yet" : "Add a client first" }}
          </p>
          <p v-if="clients.length" class="mt-1 text-p-sm text-ink-gray-5">
            "Add from library" is the quick way — pick several at once.
          </p>
        </div>

        <div v-else class="overflow-hidden rounded-lg border border-outline-gray-2">
          <table class="w-full text-left">
            <thead class="bg-surface-gray-1 text-p-sm text-ink-gray-6">
              <tr>
                <th class="px-4 py-2.5 font-medium">Check</th>
                <th class="px-4 py-2.5 font-medium">Device</th>
                <th class="px-4 py-2.5 font-medium">How often</th>
                <th class="px-4 py-2.5 font-medium">Assigned</th>
                <th class="px-4 py-2.5"></th>
              </tr>
            </thead>
            <tbody class="divide-y divide-outline-gray-2">
              <tr v-for="t in shownTasks" :key="t.id" :class="t.is_active ? '' : 'opacity-60'">
                <td class="px-4 py-2.5">
                  <span class="font-medium text-ink-gray-8">{{ t.name }}</span>
                  <span class="ml-2 text-p-sm text-ink-gray-5">
                    {{ categoryName(t.category_id) }}
                  </span>
                  <Badge v-if="!t.is_active" theme="gray" variant="subtle" class="ml-2">
                    Paused
                  </Badge>
                </td>
                <td class="px-4 py-2.5 text-p-sm text-ink-gray-6">
                  {{ deviceName(t.device_id) }}
                </td>
                <td class="px-4 py-2.5 text-p-sm text-ink-gray-6">{{ frequencyLabel(t) }}</td>
                <td class="px-4 py-2.5 text-p-sm text-ink-gray-6">
                  {{ staffLabel(t.assigned_to) }}
                </td>
                <td class="px-4 py-2.5 text-right">
                  <button class="text-p-sm text-ink-gray-6 underline" @click="openTask(t)">
                    Edit
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>
    </template>

    <!-- ------------------------------------------------ client dialog -->
    <Dialog v-model="showClient" :options="{ title: clientForm.id ? 'Edit client' : 'Add client' }">
      <template #body-content>
        <div class="space-y-3">
          <FormControl v-model="clientForm.name" label="Client name" :disabled="saving" />
          <div>
            <FormControl
              v-model="clientForm.email_domain"
              label="Email domain (optional)"
              placeholder="clientA.com"
              :disabled="saving"
            />
            <p class="mt-1 text-p-sm text-ink-gray-5">
              Tickets sent from this domain attach to this client automatically.
            </p>
          </div>
          <ErrorMessage :message="dialogError" />
        </div>
      </template>
      <template #actions>
        <Button variant="solid" class="w-full" :loading="saving" @click="saveClient">
          Save
        </Button>
      </template>
    </Dialog>

    <!-- ------------------------------------------------ device dialog -->
    <Dialog v-model="showDevice" :options="{ title: deviceForm.id ? 'Edit device' : 'Add device' }">
      <template #body-content>
        <div class="space-y-3">
          <FormControl
            v-model="deviceForm.organization_id"
            type="select"
            label="Client"
            :options="clientOptions"
            :disabled="saving"
          />
          <FormControl v-model="deviceForm.name" label="Name" placeholder="DC01" :disabled="saving" />
          <FormControl
            v-model="deviceForm.kind"
            type="select"
            label="Type"
            :options="deviceKindOptions"
            :disabled="saving"
          />
          <FormControl v-model="deviceForm.hostname" label="Hostname (optional)" :disabled="saving" />
          <FormControl v-model="deviceForm.ip_address" label="IP address (optional)" :disabled="saving" />
          <FormControl v-model="deviceForm.location" label="Location (optional)" :disabled="saving" />
          <FormControl v-model="deviceForm.notes" type="textarea" :rows="2" label="Notes (optional)" :disabled="saving" />
          <label v-if="deviceForm.id" class="flex items-center gap-2 text-p-sm text-ink-gray-6">
            <input v-model="deviceForm.is_active" type="checkbox" class="rounded" />
            Active
          </label>
          <ErrorMessage :message="dialogError" />
        </div>
      </template>
      <template #actions>
        <Button variant="solid" class="w-full" :loading="saving" @click="saveDevice">Save</Button>
      </template>
    </Dialog>

    <!-- ----------------------------------------------- catalog dialog -->
    <Dialog v-model="showCatalog" :options="{ title: catalogForm.id ? 'Edit check' : 'Add check to library' }">
      <template #body-content>
        <div class="space-y-3">
          <FormControl
            v-model="catalogForm.category_id"
            type="select"
            label="Category"
            :options="categoryOptions"
            :disabled="saving"
          />
          <FormControl v-model="catalogForm.name" label="Check name" :disabled="saving" />
          <FormControl v-model="catalogForm.description" label="Description (optional)" :disabled="saving" />
          <FormControl
            v-model="catalogForm.default_instructions"
            type="textarea"
            :rows="3"
            label="Instructions (optional)"
            :disabled="saving"
          />
          <ErrorMessage :message="dialogError" />
        </div>
      </template>
      <template #actions>
        <Button variant="solid" class="w-full" :loading="saving" @click="saveCatalog">Save</Button>
      </template>
    </Dialog>

    <!-- -------------------------------------------------- task dialog -->
    <Dialog v-model="showTask" :options="{ title: taskForm.id ? 'Edit check' : 'Add check', size: 'lg' }">
      <template #body-content>
        <div class="space-y-3">
          <FormControl v-model="taskForm.name" label="Check name" :disabled="saving" />
          <FormControl
            v-model="taskForm.category_id"
            type="select"
            label="Category"
            :options="categoryOptions"
            :disabled="saving"
          />
          <FormControl
            v-model="taskForm.device_id"
            type="select"
            label="Device (optional)"
            :options="deviceOptionsForTask"
            :disabled="saving"
          />
          <div class="grid grid-cols-2 gap-3">
            <FormControl
              v-model="taskForm.frequency"
              type="select"
              label="How often"
              :options="frequencyOptions"
              :disabled="saving"
            />
            <FormControl
              v-if="taskForm.frequency === 'weekly'"
              v-model="taskForm.run_weekday"
              type="select"
              label="Day"
              :options="weekdayOptions"
              :disabled="saving"
            />
            <FormControl
              v-else-if="taskForm.frequency !== 'daily'"
              v-model="taskForm.run_day"
              type="select"
              label="Day of month"
              :options="monthDayOptions"
              :disabled="saving"
            />
          </div>
          <div class="grid grid-cols-2 gap-3">
            <FormControl
              v-model="taskForm.priority"
              type="select"
              label="Priority"
              :options="priorityOptions"
              :disabled="saving"
            />
            <FormControl
              v-model="taskForm.assigned_to"
              type="select"
              label="Assigned to"
              :options="staffOptions"
              :disabled="saving"
            />
          </div>
          <FormControl
            v-model="taskForm.instructions"
            type="textarea"
            :rows="3"
            label="Instructions (optional)"
            :disabled="saving"
          />
          <label class="flex items-center gap-2 text-p-sm text-ink-gray-6">
            <input v-model="taskForm.auto_ticket_on_fail" type="checkbox" class="rounded" />
            Raise a ticket automatically when this fails
          </label>
          <p class="text-p-sm text-ink-gray-5">
            Leave that off to start with. A check that flaps will otherwise
            create a ticket every day and bury the real ones.
          </p>
          <label v-if="taskForm.id" class="flex items-center gap-2 text-p-sm text-ink-gray-6">
            <input v-model="taskForm.is_active" type="checkbox" class="rounded" />
            Active — new occurrences are created
          </label>
          <p v-if="taskForm.id" class="text-p-sm text-ink-gray-5">
            Unticking this stops new occurrences. Past results are kept.
          </p>
          <ErrorMessage :message="dialogError" />
        </div>
      </template>
      <template #actions>
        <Button variant="solid" class="w-full" :loading="saving" @click="saveTask">Save</Button>
      </template>
    </Dialog>

    <!-- ------------------------------------------------ library picker -->
    <Dialog v-model="showPicker" :options="{ title: 'Add checks from the library', size: '2xl' }">
      <template #body-content>
        <p class="mb-3 text-p-sm text-ink-gray-6">
          Tick everything this client needs. You can set the device and
          frequency on each one afterwards.
        </p>

        <div class="max-h-96 space-y-4 overflow-auto pr-1">
          <div v-for="cat in categories" :key="cat.id">
            <p class="mb-1 text-p-sm font-medium text-ink-gray-8">{{ cat.name }}</p>
            <label
              v-for="item in catalog.filter((c) => c.category_id === cat.id)"
              :key="item.id"
              class="flex items-start gap-2 rounded px-1 py-1 hover:bg-surface-gray-1"
              :class="alreadyAdded(item.id) ? 'opacity-50' : ''"
            >
              <input
                type="checkbox"
                class="mt-0.5 rounded"
                :value="item.id"
                :disabled="alreadyAdded(item.id)"
                :checked="picked.includes(item.id)"
                @change="togglePick(item.id)"
              />
              <span class="text-p-sm text-ink-gray-7">
                {{ item.name }}
                <span v-if="alreadyAdded(item.id)" class="text-ink-gray-5">— already added</span>
              </span>
            </label>
          </div>
        </div>

        <div class="mt-4 grid grid-cols-2 gap-3 border-t border-outline-gray-2 pt-3">
          <FormControl
            v-model="pickerDefaults.frequency"
            type="select"
            label="How often"
            :options="frequencyOptions"
            :disabled="saving"
          />
          <FormControl
            v-model="pickerDefaults.device_id"
            type="select"
            label="Device (optional)"
            :options="deviceOptionsForTask"
            :disabled="saving"
          />
        </div>
        <ErrorMessage :message="dialogError" class="mt-2" />
      </template>
      <template #actions>
        <Button
          variant="solid"
          class="w-full"
          :loading="saving"
          :disabled="!picked.length"
          @click="savePicked"
        >
          Add {{ picked.length || "" }} check{{ picked.length === 1 ? "" : "s" }}
        </Button>
      </template>
    </Dialog>
  </div>
</template>

<script setup lang="ts">
/**
 * Operations ka setup — client, device, library aur har client ki
 * apni checklist.
 *
 * YE PAGE PEHLE AATA HAI
 *
 * Rozana wali checklist tab tak khali rehti hai jab tak yahan se kisi
 * client ki list na ban jaye. Library ki 36 jaanchein 28_ops_seed.sql se
 * pehle se maujood hain, par wo sirf ek list hai — kisi client par lagti
 * nahi. "Add from library" wahi kaam karta hai.
 *
 * SEEDHA TABLE PAR KAAM, RPC NAHI
 *
 * Yahan sab kuch aam CRUD hai aur RLS use rok leti hai
 * (27_ops_schema.sql). RPC sirf wahan likhi hai jahan bharosa ka sawal
 * hai — performed_by, logon ke naam, ticket banana. Setup me un me se
 * koi baat nahi, isliye ek bekaar parat nahi jodi.
 */
import { supabase } from "@/lib/supabase";
import {
  Badge, Button, Dialog, ErrorMessage, FeatherIcon, FormControl,
  LoadingIndicator, toast,
} from "frappe-ui";
import { computed, onMounted, reactive, ref } from "vue";
import { useRouter } from "vue-router";

const router = useRouter();

type Client = { id: string; name: string; email_domain: string | null };
type Category = { id: string; name: string; sort_order: number };
type CatalogItem = {
  id: string; category_id: string; name: string;
  description: string | null; default_instructions: string | null;
};
type Device = {
  id: string; organization_id: string; name: string; kind: string;
  hostname: string | null; ip_address: string | null;
  location: string | null; notes: string | null; is_active: boolean;
};
type ClientTask = {
  id: string; organization_id: string; catalog_id: string | null;
  device_id: string | null; category_id: string;
  name: string; description: string | null; instructions: string | null;
  frequency: string; run_weekday: number; run_day: number;
  priority: string; assigned_to: string | null;
  auto_ticket_on_fail: boolean; is_active: boolean;
};
type Staff = { id: string; label: string; specialization: string | null };

const tabs = [
  { key: "clients", label: "Clients" },
  { key: "devices", label: "Devices" },
  { key: "library", label: "Task library" },
  { key: "checklists", label: "Client checklists" },
] as const;
const tab = ref<(typeof tabs)[number]["key"]>("clients");

const loading = ref(true);
const saving = ref(false);
const error = ref("");
const dialogError = ref("");

const clients = ref<Client[]>([]);
const categories = ref<Category[]>([]);
const catalog = ref<CatalogItem[]>([]);
const devices = ref<Device[]>([]);
const tasks = ref<ClientTask[]>([]);
const staff = ref<Staff[]>([]);

const deviceClient = ref("");
const taskClient = ref("");

// -------------------------------------------------------------- options
const clientOptions = computed(() =>
  clients.value.map((c) => ({ label: c.name, value: c.id }))
);
const categoryOptions = computed(() =>
  categories.value.map((c) => ({ label: c.name, value: c.id }))
);
const staffOptions = computed(() => [
  { label: "Nobody in particular", value: "" },
  ...staff.value.map((s) => ({
    label: s.specialization ? `${s.label} · ${s.specialization}` : s.label,
    value: s.id,
  })),
]);
const deviceOptionsForTask = computed(() => [
  { label: "No specific device", value: "" },
  ...devices.value
    .filter((d) => d.organization_id === taskClient.value && d.is_active)
    .map((d) => ({ label: d.name, value: d.id })),
]);
const deviceKindOptions = [
  { label: "Server", value: "server" },
  { label: "Network device", value: "network" },
  { label: "Firewall", value: "firewall" },
  { label: "Backup system", value: "backup" },
  { label: "CCTV / NVR", value: "cctv" },
  { label: "Storage", value: "storage" },
  { label: "Application", value: "application" },
  { label: "Other", value: "other" },
];
const frequencyOptions = [
  { label: "Every day", value: "daily" },
  { label: "Weekly", value: "weekly" },
  { label: "Monthly", value: "monthly" },
  { label: "Quarterly", value: "quarterly" },
];
const weekdayOptions = [
  { label: "Monday", value: 1 }, { label: "Tuesday", value: 2 },
  { label: "Wednesday", value: 3 }, { label: "Thursday", value: 4 },
  { label: "Friday", value: 5 }, { label: "Saturday", value: 6 },
  { label: "Sunday", value: 0 },
];
// 28 tak hi. Uske aage ka din February me aata hi nahi, aur us mahine ki
// jaanch chup-chaap gayab ho jaati. Yahi rok database par bhi lagi hai.
const monthDayOptions = Array.from({ length: 28 }, (_, i) => ({
  label: String(i + 1),
  value: i + 1,
}));
const priorityOptions = [
  { label: "Low", value: "low" }, { label: "Medium", value: "medium" },
  { label: "High", value: "high" }, { label: "Urgent", value: "urgent" },
];

// -------------------------------------------------------------- labels
const shownDevices = computed(() =>
  devices.value.filter((d) => d.organization_id === deviceClient.value)
);
const shownTasks = computed(() =>
  tasks.value.filter((t) => t.organization_id === taskClient.value)
);

function categoryName(id: string) {
  return categories.value.find((c) => c.id === id)?.name ?? "—";
}
function deviceName(id: string | null) {
  if (!id) return "—";
  return devices.value.find((d) => d.id === id)?.name ?? "—";
}
function staffLabel(id: string | null) {
  if (!id) return "—";
  return staff.value.find((s) => s.id === id)?.label ?? "—";
}
function deviceKindLabel(k: string) {
  return deviceKindOptions.find((o) => o.value === k)?.label ?? k;
}
function frequencyLabel(t: ClientTask) {
  if (t.frequency === "daily") return "Every day";
  if (t.frequency === "weekly") {
    return `Every ${weekdayOptions.find((w) => w.value === t.run_weekday)?.label ?? "Monday"}`;
  }
  const day = t.run_day;
  const suffix = day === 1 ? "st" : day === 2 ? "nd" : day === 3 ? "rd" : "th";
  if (t.frequency === "monthly") return `${day}${suffix} of the month`;
  return `${day}${suffix}, every 3 months`;
}

// ---------------------------------------------------------------- load
async function load() {
  loading.value = true;
  error.value = "";
  try {
    const [o, c, cat, d, t, st] = await Promise.all([
      supabase.from("organizations").select("id, name, email_domain").order("name"),
      supabase.from("ops_categories").select("id, name, sort_order").order("sort_order"),
      supabase
        .from("ops_task_catalog")
        .select("id, category_id, name, description, default_instructions")
        .eq("is_active", true)
        .order("sort_order"),
      supabase.from("ops_devices").select("*").order("name"),
      supabase.from("ops_client_tasks").select("*").order("name"),
      supabase.rpc("staff_directory"),
    ]);

    clients.value = (o.data as Client[]) ?? [];
    categories.value = (c.data as Category[]) ?? [];
    catalog.value = (cat.data as CatalogItem[]) ?? [];
    devices.value = (d.data as Device[]) ?? [];
    tasks.value = (t.data as ClientTask[]) ?? [];
    staff.value = (st.data as Staff[]) ?? [];

    if (!deviceClient.value) deviceClient.value = clients.value[0]?.id ?? "";
    if (!taskClient.value) taskClient.value = clients.value[0]?.id ?? "";
  } catch (e: any) {
    error.value = e?.message || "Could not load the setup data";
  } finally {
    loading.value = false;
  }
}
onMounted(load);

// -------------------------------------------------------------- client
const showClient = ref(false);
const clientForm = reactive({ id: "", name: "", email_domain: "" });

function openClient(c?: Client) {
  dialogError.value = "";
  Object.assign(clientForm, {
    id: c?.id ?? "",
    name: c?.name ?? "",
    email_domain: c?.email_domain ?? "",
  });
  showClient.value = true;
}

async function saveClient() {
  dialogError.value = "";
  if (!clientForm.name.trim()) return (dialogError.value = "Please enter a name");

  saving.value = true;
  try {
    const row = {
      name: clientForm.name.trim(),
      // Khali domain ko NULL bhejna zaroori hai. Column par unique laga
      // hai — do clients ki khali string aapas me takra jaatin.
      email_domain: clientForm.email_domain.trim().toLowerCase() || null,
    };
    const { error: e } = clientForm.id
      ? await supabase.from("organizations").update(row).eq("id", clientForm.id)
      : await supabase.from("organizations").insert(row);
    if (e) throw e;

    showClient.value = false;
    toast.success("Client saved");
    await load();
  } catch (e: any) {
    dialogError.value = friendly(e?.message);
  } finally {
    saving.value = false;
  }
}

// -------------------------------------------------------------- device
const showDevice = ref(false);
const deviceForm = reactive({
  id: "", organization_id: "", name: "", kind: "server",
  hostname: "", ip_address: "", location: "", notes: "", is_active: true,
});

function openDevice(d?: Device) {
  dialogError.value = "";
  Object.assign(deviceForm, {
    id: d?.id ?? "",
    organization_id: d?.organization_id ?? deviceClient.value,
    name: d?.name ?? "",
    kind: d?.kind ?? "server",
    hostname: d?.hostname ?? "",
    ip_address: d?.ip_address ?? "",
    location: d?.location ?? "",
    notes: d?.notes ?? "",
    is_active: d?.is_active ?? true,
  });
  showDevice.value = true;
}

async function saveDevice() {
  dialogError.value = "";
  if (!deviceForm.organization_id) return (dialogError.value = "Please choose a client");
  if (!deviceForm.name.trim()) return (dialogError.value = "Please enter a name");

  saving.value = true;
  try {
    const row = {
      organization_id: deviceForm.organization_id,
      name: deviceForm.name.trim(),
      kind: deviceForm.kind,
      hostname: deviceForm.hostname.trim() || null,
      ip_address: deviceForm.ip_address.trim() || null,
      location: deviceForm.location.trim() || null,
      notes: deviceForm.notes.trim() || null,
      is_active: deviceForm.is_active,
    };
    const { error: e } = deviceForm.id
      ? await supabase.from("ops_devices").update(row).eq("id", deviceForm.id)
      : await supabase.from("ops_devices").insert(row);
    if (e) throw e;

    showDevice.value = false;
    toast.success("Device saved");
    await load();
  } catch (e: any) {
    dialogError.value = friendly(e?.message);
  } finally {
    saving.value = false;
  }
}

// ------------------------------------------------------------- catalog
const showCatalog = ref(false);
const catalogForm = reactive({
  id: "", category_id: "", name: "", description: "", default_instructions: "",
});

function openCatalog(item?: CatalogItem) {
  dialogError.value = "";
  Object.assign(catalogForm, {
    id: item?.id ?? "",
    category_id: item?.category_id ?? categories.value[0]?.id ?? "",
    name: item?.name ?? "",
    description: item?.description ?? "",
    default_instructions: item?.default_instructions ?? "",
  });
  showCatalog.value = true;
}

async function saveCatalog() {
  dialogError.value = "";
  if (!catalogForm.category_id) return (dialogError.value = "Please choose a category");
  if (!catalogForm.name.trim()) return (dialogError.value = "Please enter a name");

  saving.value = true;
  try {
    const row = {
      category_id: catalogForm.category_id,
      name: catalogForm.name.trim(),
      description: catalogForm.description.trim() || null,
      default_instructions: catalogForm.default_instructions.trim() || null,
    };
    const { error: e } = catalogForm.id
      ? await supabase.from("ops_task_catalog").update(row).eq("id", catalogForm.id)
      : await supabase.from("ops_task_catalog").insert(row);
    if (e) throw e;

    showCatalog.value = false;
    toast.success("Saved to the library");
    await load();
  } catch (e: any) {
    dialogError.value = friendly(e?.message);
  } finally {
    saving.value = false;
  }
}

// ---------------------------------------------------------- client task
const showTask = ref(false);
const taskForm = reactive({
  id: "", name: "", category_id: "", device_id: "",
  frequency: "daily", run_weekday: 1, run_day: 1,
  priority: "medium", assigned_to: "", instructions: "",
  auto_ticket_on_fail: false, is_active: true,
});

function openTask(t?: ClientTask) {
  dialogError.value = "";
  Object.assign(taskForm, {
    id: t?.id ?? "",
    name: t?.name ?? "",
    category_id: t?.category_id ?? categories.value[0]?.id ?? "",
    device_id: t?.device_id ?? "",
    frequency: t?.frequency ?? "daily",
    run_weekday: t?.run_weekday ?? 1,
    run_day: t?.run_day ?? 1,
    priority: t?.priority ?? "medium",
    assigned_to: t?.assigned_to ?? "",
    instructions: t?.instructions ?? "",
    auto_ticket_on_fail: t?.auto_ticket_on_fail ?? false,
    is_active: t?.is_active ?? true,
  });
  showTask.value = true;
}

async function saveTask() {
  dialogError.value = "";
  if (!taskForm.name.trim()) return (dialogError.value = "Please enter a name");
  if (!taskForm.category_id) return (dialogError.value = "Please choose a category");

  saving.value = true;
  try {
    const row = {
      organization_id: taskClient.value,
      category_id: taskForm.category_id,
      device_id: taskForm.device_id || null,
      name: taskForm.name.trim(),
      instructions: taskForm.instructions.trim() || null,
      frequency: taskForm.frequency,
      run_weekday: Number(taskForm.run_weekday),
      run_day: Number(taskForm.run_day),
      priority: taskForm.priority,
      assigned_to: taskForm.assigned_to || null,
      auto_ticket_on_fail: taskForm.auto_ticket_on_fail,
      is_active: taskForm.is_active,
    };
    const { error: e } = taskForm.id
      ? await supabase.from("ops_client_tasks").update(row).eq("id", taskForm.id)
      : await supabase.from("ops_client_tasks").insert(row);
    if (e) throw e;

    showTask.value = false;
    toast.success("Check saved");
    await load();
  } catch (e: any) {
    dialogError.value = friendly(e?.message);
  } finally {
    saving.value = false;
  }
}

// ------------------------------------------------------ library picker
const showPicker = ref(false);
const picked = ref<string[]>([]);
const pickerDefaults = reactive({ frequency: "daily", device_id: "" });

function openPicker() {
  dialogError.value = "";
  picked.value = [];
  pickerDefaults.frequency = "daily";
  pickerDefaults.device_id = "";
  showPicker.value = true;
}

/** Ek hi jaanch do baar na jud jaye. */
function alreadyAdded(catalogId: string) {
  return tasks.value.some(
    (t) => t.organization_id === taskClient.value && t.catalog_id === catalogId
  );
}

function togglePick(id: string) {
  const i = picked.value.indexOf(id);
  if (i === -1) picked.value.push(id);
  else picked.value.splice(i, 1);
}

async function savePicked() {
  dialogError.value = "";
  saving.value = true;
  try {
    const rows = picked.value
      .map((id) => catalog.value.find((c) => c.id === id))
      .filter(Boolean)
      .map((c) => ({
        organization_id: taskClient.value,
        catalog_id: c!.id,
        category_id: c!.category_id,
        device_id: pickerDefaults.device_id || null,
        // Naam copy ho kar aata hai, join nahi hota. Isse ek client ke
        // liye naam badalna doosre par asar nahi karta.
        name: c!.name,
        description: c!.description,
        instructions: c!.default_instructions,
        frequency: pickerDefaults.frequency,
      }));

    const { error: e } = await supabase.from("ops_client_tasks").insert(rows);
    if (e) throw e;

    showPicker.value = false;
    toast.success(`${rows.length} check${rows.length === 1 ? "" : "s"} added`);
    await load();
  } catch (e: any) {
    dialogError.value = friendly(e?.message);
  } finally {
    saving.value = false;
  }
}

/**
 * Postgres ke unique-constraint wale message aam aadmi ke kaam ke nahi
 * hote ("duplicate key value violates unique constraint ..."). Jo do
 * takrav sach me hote hain, unhe seedha keh dete hain.
 */
function friendly(msg?: string) {
  if (!msg) return "Could not save";
  if (msg.includes("organizations_name_key")) return "A client with that name already exists";
  if (msg.includes("organizations_email_domain_key")) return "Another client already uses that email domain";
  if (msg.includes("ops_devices_organization_id_name_key")) return "This client already has a device with that name";
  if (msg.includes("ops_task_catalog_category_id_name_key")) return "That check is already in the library under this category";
  return msg;
}
</script>
