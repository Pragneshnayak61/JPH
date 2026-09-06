<template>
  <div class="px-6 py-6">
    <!-- ------------------------------------------------------ header -->
    <div class="mb-4 flex flex-wrap items-start justify-between gap-3">
      <div>
        <h1 class="text-lg font-semibold text-ink-gray-9">
          {{ isToday ? "Today's operations" : "Operations" }}
        </h1>
        <p class="mt-0.5 text-p-sm text-ink-gray-6">{{ longDate }}</p>
      </div>
      <div class="flex flex-wrap items-center gap-2">
        <FormControl v-model="date" type="date" :disabled="loading" class="w-40" />
        <Button v-if="!isToday" @click="date = todayStr">Today</Button>
        <Button @click="router.push('/admin/operations/reports')">
          <template #prefix><FeatherIcon name="file-text" class="h-4 w-4" /></template>
          Reports
        </Button>
        <Button v-if="auth.canManageOps" variant="solid" @click="router.push('/admin/operations/setup')">
          <template #prefix><FeatherIcon name="settings" class="h-4 w-4" /></template>
          Setup
        </Button>
      </div>
    </div>

    <!-- ----------------------------------------------------- summary -->
    <div v-if="!loading && rows.length" class="mb-4 grid gap-3 sm:grid-cols-3 lg:grid-cols-6">
      <div
        v-for="t in tiles"
        :key="t.label"
        class="rounded-lg border border-outline-gray-2 px-3 py-2.5"
      >
        <p class="text-p-sm text-ink-gray-6">{{ t.label }}</p>
        <p class="text-lg font-semibold" :class="t.tone">{{ t.value }}</p>
      </div>
    </div>

    <!-- ----------------------------------------------------- filters -->
    <div v-if="!loading && rows.length" class="mb-4 flex flex-wrap items-center gap-2">
      <FormControl v-model="fClient" type="select" :options="clientFilterOptions" class="w-44" />
      <FormControl v-model="fCategory" type="select" :options="categoryFilterOptions" class="w-40" />
      <FormControl v-model="fAssignee" type="select" :options="assigneeFilterOptions" class="w-44" />
      <FormControl v-model="fStatus" type="select" :options="statusFilterOptions" class="w-40" />
      <FormControl v-model="search" placeholder="Search checks…" class="w-52" />
      <button
        v-if="filtersOn"
        class="text-p-sm text-ink-gray-6 underline"
        @click="clearFilters"
      >
        Clear
      </button>
    </div>

    <!-- ------------------------------------------------------ states -->
    <!--
      ErrorMessage v-if/v-else-if ki chain se BAHAR hai. Beech me rakhne
      par Vue chain hi nahi jodta ("v-else-if has no adjacent v-if") aur
      build fail ho jaati hai.
    -->
    <ErrorMessage :message="error" class="mb-4" />

    <div v-if="loading" class="py-20 text-center">
      <LoadingIndicator class="mx-auto h-6 w-6 text-ink-gray-5" />
      <p class="mt-3 text-p-sm text-ink-gray-6">Loading the checklist…</p>
    </div>

    <div
      v-else-if="!rows.length"
      class="rounded-lg border border-outline-gray-2 py-16 text-center"
    >
      <FeatherIcon name="server" class="mx-auto h-8 w-8 text-ink-gray-4" />
      <p class="mt-3 text-p-base text-ink-gray-7">Nothing scheduled for this day</p>
      <p class="mx-auto mt-1 max-w-md text-p-sm text-ink-gray-5">
        Checks appear here once a client has a checklist. The library already
        has 36 standard checks &mdash; pick the ones each client needs.
      </p>
      <Button
        v-if="auth.canManageOps"
        variant="solid"
        class="mt-4"
        @click="router.push('/admin/operations/setup')"
      >
        Build a checklist
      </Button>
    </div>

    <div
      v-else-if="!filtered.length"
      class="rounded-lg border border-outline-gray-2 py-16 text-center"
    >
      <p class="text-p-base text-ink-gray-6">Nothing matches those filters</p>
      <button class="mt-2 text-p-sm text-ink-gray-6 underline" @click="clearFilters">
        Clear the filters
      </button>
    </div>

    <!-- ------------------------------------------------------- lists -->
    <div v-else class="space-y-5">
      <section
        v-for="g in grouped"
        :key="g.id"
        class="overflow-hidden rounded-lg border border-outline-gray-2"
      >
        <!-- client header -->
        <div class="flex items-center gap-3 border-b border-outline-gray-2 bg-surface-gray-1 px-4 py-2.5">
          <span class="font-medium text-ink-gray-8">{{ g.name }}</span>
          <span class="text-p-sm text-ink-gray-5">
            {{ g.done }}/{{ g.countable }} done
          </span>
          <div class="ml-auto flex items-center gap-2">
            <div class="h-1.5 w-28 overflow-hidden rounded-full bg-surface-gray-3">
              <div
                class="h-full rounded-full"
                :class="g.percent === 100 ? 'bg-surface-green-5' : 'bg-surface-gray-6'"
                :style="{ width: g.percent + '%' }"
              />
            </div>
            <span class="w-10 text-right text-p-sm text-ink-gray-6">{{ g.percent }}%</span>
          </div>
        </div>

        <!-- rows -->
        <ul class="divide-y divide-outline-gray-2">
          <li
            v-for="r in g.rows"
            :key="r.execution_id"
            class="flex items-center gap-3 px-4 py-2 hover:bg-surface-gray-1"
          >
            <input
              type="checkbox"
              class="rounded"
              :checked="selected.includes(r.execution_id)"
              @change="toggleSelect(r.execution_id)"
            />

            <!--
              Ek click = ho gaya. Yahi is page ka poora maqsad hai: subah
              tees jaanchein niptani hain, har ek ke liye form kholna
              bekaar hai. Baaki paanch status "More" se milte hain.
            -->
            <button
              class="shrink-0"
              :title="busyId === r.execution_id ? 'Saving…' : 'Mark completed'"
              :disabled="busyId === r.execution_id"
              @click="quickComplete(r)"
            >
              <FeatherIcon
                :name="statusIcon(r.status)"
                class="h-5 w-5"
                :class="statusTone(r.status)"
              />
            </button>

            <div class="min-w-0 flex-1">
              <div class="flex items-center gap-2">
                <button
                  class="truncate text-p-base text-ink-gray-8 hover:underline"
                  :title="r.instructions || r.task_name"
                  @click="openHistory(r)"
                >
                  {{ r.task_name }}
                </button>
                <Badge v-if="r.is_backlog" theme="orange" variant="subtle">
                  {{ shortDate(r.due_date) }}
                </Badge>
                <!-- Number dikhana kaafi nahi tha — dekhne wale ne
                     use haath se dhoondhna padta tha. -->
                <RouterLink
                  v-if="r.ticket_id"
                  :to="`/admin/tickets/${r.ticket_id}`"
                  @click.stop
                >
                  <Badge theme="blue" variant="subtle">#{{ r.ticket_id }}</Badge>
                </RouterLink>
              </div>
              <p class="truncate text-p-sm text-ink-gray-5">
                {{ [r.device_name, r.category_name, r.assigned_label].filter(Boolean).join(" · ") }}
                <span v-if="r.remarks"> &mdash; {{ r.remarks }}</span>
              </p>
            </div>

            <Button
              v-if="needsTicket(r)"
              class="shrink-0"
              @click="openTicket(r)"
            >
              Create ticket
            </Button>
            <button
              class="shrink-0 text-p-sm text-ink-gray-6 underline"
              @click="openDetail(r)"
            >
              More
            </button>
          </li>
        </ul>
      </section>
    </div>

    <!-- -------------------------------------------------- bulk bar -->
    <div
      v-if="selected.length"
      class="sticky bottom-4 mt-4 flex flex-wrap items-center gap-2 rounded-lg border border-outline-gray-2 bg-surface-base p-3 shadow-lg"
    >
      <span class="text-p-sm text-ink-gray-7">{{ selected.length }} selected</span>
      <div class="ml-auto flex flex-wrap gap-2">
        <Button :loading="bulkBusy" @click="bulk('completed')">Mark completed</Button>
        <Button :loading="bulkBusy" @click="bulk('skipped')">Mark skipped</Button>
        <Button @click="selected = []">Cancel</Button>
      </div>
    </div>

    <!-- ---------------------------------------------- detail dialog -->
    <Dialog v-model="showDetail" :options="{ title: detail?.task_name ?? '', size: 'lg' }">
      <template #body-content>
        <div v-if="detail" class="space-y-4">
          <p class="text-p-sm text-ink-gray-6">
            {{ [detail.client_name, detail.device_name, detail.category_name].filter(Boolean).join(" · ") }}
            &middot; {{ shortDate(detail.due_date) }}
          </p>

          <div
            v-if="detail.instructions"
            class="rounded-lg bg-surface-gray-1 p-3 text-p-sm whitespace-pre-wrap text-ink-gray-7"
          >
            {{ detail.instructions }}
          </div>

          <FormControl
            v-model="detailForm.status"
            type="select"
            label="Result"
            :options="statusOptions"
            :disabled="saving"
          />
          <FormControl
            v-model="detailForm.remarks"
            type="textarea"
            :rows="3"
            label="Remarks"
            placeholder="What did you find?"
            :disabled="saving"
          />

          <!-- evidence -->
          <div>
            <p class="mb-1 text-p-sm font-medium text-ink-gray-8">Evidence</p>
            <ul v-if="files.length" class="mb-2 space-y-1">
              <li
                v-for="f in files"
                :key="f.id"
                class="flex items-center gap-2 text-p-sm"
              >
                <FeatherIcon name="paperclip" class="h-3.5 w-3.5 text-ink-gray-5" />
                <button class="truncate text-ink-gray-7 underline" @click="openFile(f)">
                  {{ f.file_name }}
                </button>
                <span class="text-ink-gray-5">{{ sizeLabel(f.file_size) }}</span>
                <button
                  v-if="auth.canManageOps"
                  class="ml-auto text-ink-gray-5 underline"
                  @click="removeFile(f)"
                >
                  Remove
                </button>
              </li>
            </ul>
            <input
              ref="fileInput"
              type="file"
              class="hidden"
              @change="onPickFile"
            />
            <Button :loading="uploading" @click="fileInput?.click()">
              <template #prefix><FeatherIcon name="upload" class="h-4 w-4" /></template>
              Attach a file
            </Button>
            <p class="mt-1 text-p-sm text-ink-gray-5">
              Screenshot, backup report, log or PDF. Up to 20 MB. Only people
              with operations access can open these.
            </p>
          </div>

          <ErrorMessage :message="dialogError" />
        </div>
      </template>
      <template #actions>
        <div class="flex gap-2">
          <Button
            v-if="detail && needsTicket(detail)"
            class="flex-1"
            @click="openTicket(detail)"
          >
            Create ticket
          </Button>
          <Button variant="solid" class="flex-1" :loading="saving" @click="saveDetail">
            Save
          </Button>
        </div>
      </template>
    </Dialog>

    <!-- --------------------------------------------- history dialog -->
    <Dialog v-model="showHistory" :options="{ title: historyOf?.task_name ?? '', size: 'lg' }">
      <template #body-content>
        <p class="mb-3 text-p-sm text-ink-gray-6">
          {{ [historyOf?.client_name, historyOf?.device_name].filter(Boolean).join(" · ") }}
        </p>
        <div v-if="historyLoading" class="py-8 text-center">
          <LoadingIndicator class="mx-auto h-5 w-5 text-ink-gray-5" />
        </div>
        <p v-else-if="!history.length" class="py-8 text-center text-p-sm text-ink-gray-6">
          No earlier results yet
        </p>
        <ul v-else class="divide-y divide-outline-gray-2">
          <li v-for="h in history" :key="h.execution_id" class="flex items-start gap-3 py-2">
            <FeatherIcon
              :name="statusIcon(h.status)"
              class="mt-0.5 h-4 w-4 shrink-0"
              :class="statusTone(h.status)"
            />
            <div class="min-w-0 flex-1">
              <p class="text-p-sm text-ink-gray-8">
                {{ shortDate(h.due_date) }} &mdash; {{ statusLabel(h.status) }}
                <span v-if="h.remarks" class="text-ink-gray-6">&middot; {{ h.remarks }}</span>
              </p>
              <p class="text-p-sm text-ink-gray-5">
                {{ h.performed_label || "—" }}
                <span v-if="h.ticket_id"> &middot; ticket #{{ h.ticket_id }}</span>
                <span v-if="h.file_count"> &middot; {{ h.file_count }} file(s)</span>
              </p>
            </div>
          </li>
        </ul>
      </template>
    </Dialog>

    <!-- ---------------------------------------------- ticket dialog -->
    <Dialog v-model="showTicket" :options="{ title: 'Create a ticket' }">
      <template #body-content>
        <div v-if="ticketOf" class="space-y-3">
          <p class="text-p-sm text-ink-gray-6">
            A ticket will be raised with the client, device, check, date,
            result and your remarks already filled in.
          </p>
          <div class="rounded-lg bg-surface-gray-1 p-3 text-p-sm text-ink-gray-7">
            <p><strong>{{ ticketOf.client_name }}</strong> &middot; {{ ticketOf.device_name || "—" }}</p>
            <p>{{ ticketOf.task_name }} &mdash; {{ statusLabel(ticketOf.status) }}</p>
            <p v-if="ticketOf.remarks" class="mt-1">{{ ticketOf.remarks }}</p>
          </div>
          <FormControl
            v-model="ticketPriority"
            type="select"
            label="Priority"
            :options="priorityOptions"
            :disabled="saving"
          />
          <ErrorMessage :message="dialogError" />
        </div>
      </template>
      <template #actions>
        <Button variant="solid" class="w-full" :loading="saving" @click="createTicket">
          Create ticket
        </Button>
      </template>
    </Dialog>
  </div>
</template>

<script setup lang="ts">
/**
 * Subah wali checklist.
 *
 * IS PAGE KA EK HI MAQSAD HAI: TEZI.
 *
 * Tees jaanchein rozana honi hain. Har ek ke liye form kholna, dropdown
 * chunna aur save dabana — teen din me koi ye nahi karega. Isliye:
 *
 *   - status ka gola dabaya = ho gaya. Bas.
 *   - baaki paanch status "More" me hain, jahan remarks aur saboot bhi hain
 *   - checkbox se ek saath kai
 *
 * FILTER BROWSER ME LAGTE HAIN, SERVER PAR NAHI
 *
 * Ek din ki rows 30-50 hoti hain. Har filter par server jaana matlab har
 * click par intezaar. Poora din ek baar utar kar yahin chhaanta hai —
 * turant. (ops_today me filter ke parameters maujood hain, report jaisi
 * badi cheez ke liye; yahan zaroorat nahi.)
 *
 * ROWS YAHAN SE NAHI BANTIN
 *
 * Page khulte hi ops_generate_due() bulaya jaata hai. Wo asli kaam cron
 * karta hai (30_ops_generation.sql), ye sirf safety net hai — cron kisi
 * raat na chale to bhi subah checklist bhari mile. Duplicate ka darr
 * nahi: database par UNIQUE (client_task_id, due_date) laga hai.
 */
import {
  deleteEvidence, evidenceUrl, listEvidence, uploadEvidence,
  type EvidenceFile,
} from "@/lib/opsEvidence";
import { supabase } from "@/lib/supabase";
import { useAuthStore } from "@/stores/auth";
import {
  Badge, Button, Dialog, ErrorMessage, FeatherIcon, FormControl,
  LoadingIndicator, toast,
} from "frappe-ui";
import { computed, onMounted, reactive, ref, watch } from "vue";
import { useRouter } from "vue-router";

const router = useRouter();
const auth = useAuthStore();

type Row = {
  execution_id: number;
  client_task_id: string;
  organization_id: string;
  client_name: string;
  device_id: string | null;
  device_name: string | null;
  category_id: string | null;
  category_name: string | null;
  task_name: string;
  instructions: string | null;
  frequency: string;
  priority: string;
  assigned_to: string | null;
  assigned_label: string | null;
  due_date: string;
  is_backlog: boolean;
  status: string;
  remarks: string | null;
  performed_by: string | null;
  performed_label: string | null;
  performed_at: string | null;
  ticket_id: number | null;
  ticket_status: string | null;
  file_count: number;
};

type HistoryRow = {
  execution_id: number;
  due_date: string;
  status: string;
  remarks: string | null;
  performed_label: string | null;
  performed_at: string | null;
  ticket_id: number | null;
  file_count: number;
};

const todayStr = new Date().toISOString().slice(0, 10);
const date = ref(todayStr);
const isToday = computed(() => date.value === todayStr);

const rows = ref<Row[]>([]);
const loading = ref(true);
const error = ref("");
const busyId = ref<number | null>(null);

// ---------------------------------------------------------------- load
async function load() {
  loading.value = true;
  error.value = "";
  selected.value = [];
  try {
    // Aane wale din ke liye rows nahi banate — wo abhi hui hi nahi.
    if (date.value <= todayStr) {
      await supabase.rpc("ops_generate_due", { p_upto: date.value });
    }
    const { data, error: e } = await supabase.rpc("ops_today", {
      p_date: date.value,
    });
    if (e) throw e;
    rows.value = (data as Row[]) ?? [];
  } catch (e: any) {
    error.value = e?.message || "Could not load the checklist";
  } finally {
    loading.value = false;
  }
}
onMounted(load);
watch(date, load);

// ------------------------------------------------------------- filters
const fClient = ref("");
const fCategory = ref("");
const fAssignee = ref("");
const fStatus = ref("");
const search = ref("");

const filtersOn = computed(
  () => fClient.value || fCategory.value || fAssignee.value || fStatus.value || search.value
);
function clearFilters() {
  fClient.value = "";
  fCategory.value = "";
  fAssignee.value = "";
  fStatus.value = "";
  search.value = "";
}

function uniqueBy<T>(list: T[], key: (x: T) => string | null) {
  const seen = new Map<string, T>();
  for (const item of list) {
    const k = key(item);
    if (k && !seen.has(k)) seen.set(k, item);
  }
  return [...seen.values()];
}

const clientFilterOptions = computed(() => [
  { label: "All clients", value: "" },
  ...uniqueBy(rows.value, (r) => r.organization_id).map((r) => ({
    label: r.client_name,
    value: r.organization_id,
  })),
]);
const categoryFilterOptions = computed(() => [
  { label: "All categories", value: "" },
  ...uniqueBy(rows.value, (r) => r.category_id).map((r) => ({
    label: r.category_name ?? "—",
    value: r.category_id ?? "",
  })),
]);
const assigneeFilterOptions = computed(() => [
  { label: "Anyone", value: "" },
  ...uniqueBy(rows.value, (r) => r.assigned_to).map((r) => ({
    label: r.assigned_label ?? "—",
    value: r.assigned_to ?? "",
  })),
]);
const statusFilterOptions = [
  { label: "Any status", value: "" },
  { label: "Pending", value: "pending" },
  { label: "In progress", value: "in_progress" },
  { label: "Completed", value: "completed" },
  { label: "Failed", value: "failed" },
  { label: "Needs attention", value: "attention" },
  { label: "Skipped", value: "skipped" },
];
const statusOptions = statusFilterOptions.slice(1);
const priorityOptions = [
  { label: "Low", value: "low" }, { label: "Medium", value: "medium" },
  { label: "High", value: "high" }, { label: "Urgent", value: "urgent" },
];

const filtered = computed(() => {
  const q = search.value.trim().toLowerCase();
  return rows.value.filter((r) => {
    if (fClient.value && r.organization_id !== fClient.value) return false;
    if (fCategory.value && r.category_id !== fCategory.value) return false;
    if (fAssignee.value && r.assigned_to !== fAssignee.value) return false;
    if (fStatus.value && r.status !== fStatus.value) return false;
    if (q) {
      const hay = [r.task_name, r.device_name, r.category_name, r.remarks]
        .filter(Boolean).join(" ").toLowerCase();
      if (!hay.includes(q)) return false;
    }
    return true;
  });
});

const grouped = computed(() => {
  const map = new Map<string, { id: string; name: string; rows: Row[] }>();
  for (const r of filtered.value) {
    if (!map.has(r.organization_id)) {
      map.set(r.organization_id, {
        id: r.organization_id,
        name: r.client_name,
        rows: [],
      });
    }
    map.get(r.organization_id)!.rows.push(r);
  }
  return [...map.values()].map((g) => {
    // "skipped" ko hisaab se bahar rakhte hain — jo jaanch jaan-boojh kar
    // chhodi gayi wo adhoori nahi hai. Warna maintenance wale din har
    // client 60% dikhta aur ginti bekaar ho jaati. Yahi niyam
    // ops_summary() me bhi hai.
    const countable = g.rows.filter((r) => r.status !== "skipped").length;
    const done = g.rows.filter((r) => r.status === "completed").length;
    return {
      ...g,
      countable,
      done,
      percent: countable === 0 ? 100 : Math.round((100 * done) / countable),
    };
  });
});

const tiles = computed(() => {
  const c = (s: string) => rows.value.filter((r) => r.status === s).length;
  return [
    { label: "Total", value: rows.value.length, tone: "text-ink-gray-9" },
    { label: "Completed", value: c("completed"), tone: "text-ink-green-8" },
    { label: "Pending", value: c("pending") + c("in_progress"), tone: "text-ink-gray-9" },
    { label: "Failed", value: c("failed"), tone: "text-ink-red-7" },
    { label: "Attention", value: c("attention"), tone: "text-ink-amber-9" },
    {
      label: "Open tickets",
      value: rows.value.filter(
        (r) => r.ticket_id && ["open", "replied"].includes(r.ticket_status ?? "")
      ).length,
      tone: "text-ink-gray-9",
    },
  ];
});

// -------------------------------------------------------------- status
function statusIcon(s: string) {
  return {
    pending: "circle",
    in_progress: "clock",
    completed: "check-circle",
    failed: "x-circle",
    attention: "alert-triangle",
    skipped: "minus-circle",
  }[s] ?? "circle";
}
function statusTone(s: string) {
  return {
    pending: "text-ink-gray-4",
    in_progress: "text-ink-gray-7",
    completed: "text-ink-green-8",
    failed: "text-ink-red-7",
    attention: "text-ink-amber-9",
    skipped: "text-ink-gray-4",
  }[s] ?? "text-ink-gray-4";
}
function statusLabel(s: string) {
  return statusFilterOptions.find((o) => o.value === s)?.label ?? s;
}
function needsTicket(r: Row) {
  return !r.ticket_id && (r.status === "failed" || r.status === "attention");
}

// ------------------------------------------------------- quick actions
async function quickComplete(r: Row) {
  // Dobara dabane par wapas pending. Galat click sabse aam galti hai, aur
  // uska ilaaj wahi button hona chahiye — kahin aur dhoondhna nahi padna
  // chahiye.
  const next = r.status === "completed" ? "pending" : "completed";
  busyId.value = r.execution_id;
  try {
    const { error: e } = await supabase.rpc("ops_complete", {
      p_execution_id: r.execution_id,
      p_status: next,
    });
    if (e) throw e;
    r.status = next;
    r.performed_label = next === "pending" ? null : (auth.profile?.agent_code ?? "Agent");
  } catch (e: any) {
    toast.error(e?.message || "Could not save that");
  } finally {
    busyId.value = null;
  }
}

const selected = ref<number[]>([]);
const bulkBusy = ref(false);

function toggleSelect(id: number) {
  const i = selected.value.indexOf(id);
  if (i === -1) selected.value.push(id);
  else selected.value.splice(i, 1);
}

async function bulk(status: string) {
  bulkBusy.value = true;
  try {
    const { error: e } = await supabase.rpc("ops_bulk_complete", {
      p_ids: selected.value,
      p_status: status,
    });
    if (e) throw e;
    toast.success(`${selected.value.length} updated`);
    selected.value = [];
    await load();
  } catch (e: any) {
    toast.error(e?.message || "Could not update those");
  } finally {
    bulkBusy.value = false;
  }
}

// -------------------------------------------------------------- detail
const showDetail = ref(false);
const detail = ref<Row | null>(null);
const detailForm = reactive({ status: "completed", remarks: "" });
const saving = ref(false);
const dialogError = ref("");
const files = ref<EvidenceFile[]>([]);
const uploading = ref(false);
const fileInput = ref<HTMLInputElement | null>(null);

async function openDetail(r: Row) {
  dialogError.value = "";
  detail.value = r;
  detailForm.status = r.status === "pending" ? "completed" : r.status;
  detailForm.remarks = r.remarks ?? "";
  files.value = [];
  showDetail.value = true;
  files.value = await listEvidence(r.execution_id);
}

async function saveDetail() {
  if (!detail.value) return;
  dialogError.value = "";
  saving.value = true;
  try {
    const { error: e } = await supabase.rpc("ops_complete", {
      p_execution_id: detail.value.execution_id,
      p_status: detailForm.status,
      p_remarks: detailForm.remarks,
    });
    if (e) throw e;
    showDetail.value = false;
    toast.success("Saved");
    await load();
  } catch (e: any) {
    dialogError.value = e?.message || "Could not save";
  } finally {
    saving.value = false;
  }
}

async function onPickFile(ev: Event) {
  const input = ev.target as HTMLInputElement;
  const file = input.files?.[0];
  input.value = "";
  if (!file || !detail.value) return;

  dialogError.value = "";
  uploading.value = true;
  try {
    const f = await uploadEvidence(detail.value.execution_id, file);
    files.value.push(f);
  } catch (e: any) {
    dialogError.value = e?.message || "Could not attach that file";
  } finally {
    uploading.value = false;
  }
}

async function openFile(f: EvidenceFile) {
  // Bucket private hai, isliye seedha URL kaam nahi karta — har baar
  // thodi der ka signed URL banana padta hai.
  const url = await evidenceUrl(f.file_path);
  if (url) window.open(url, "_blank", "noopener");
  else dialogError.value = "Could not open that file";
}

async function removeFile(f: EvidenceFile) {
  try {
    await deleteEvidence(f);
    files.value = files.value.filter((x) => x.id !== f.id);
  } catch (e: any) {
    dialogError.value = e?.message || "Could not remove that file";
  }
}

// ------------------------------------------------------------- history
const showHistory = ref(false);
const historyOf = ref<Row | null>(null);
const history = ref<HistoryRow[]>([]);
const historyLoading = ref(false);

async function openHistory(r: Row) {
  historyOf.value = r;
  history.value = [];
  historyLoading.value = true;
  showHistory.value = true;
  try {
    const { data } = await supabase.rpc("ops_task_history", {
      p_client_task_id: r.client_task_id,
    });
    history.value = (data as HistoryRow[]) ?? [];
  } finally {
    historyLoading.value = false;
  }
}

// -------------------------------------------------------------- ticket
const showTicket = ref(false);
const ticketOf = ref<Row | null>(null);
const ticketPriority = ref("medium");

function openTicket(r: Row) {
  dialogError.value = "";
  ticketOf.value = r;
  ticketPriority.value = r.priority;
  showTicket.value = true;
}

async function createTicket() {
  if (!ticketOf.value) return;
  dialogError.value = "";
  saving.value = true;
  try {
    const { data, error: e } = await supabase.rpc("ops_create_ticket", {
      p_execution_id: ticketOf.value.execution_id,
      p_priority: ticketPriority.value,
    });
    if (e) throw e;
    showTicket.value = false;
    showDetail.value = false;
    toast.success(`Ticket #${data} created`);
    router.push(`/admin/tickets/${data}`);
  } catch (e: any) {
    dialogError.value = e?.message || "Could not create the ticket";
  } finally {
    saving.value = false;
  }
}

// -------------------------------------------------------------- format
const longDate = computed(() =>
  new Date(date.value + "T00:00:00").toLocaleDateString(undefined, {
    weekday: "long", day: "numeric", month: "long", year: "numeric",
  })
);
function shortDate(d: string) {
  return new Date(d + "T00:00:00").toLocaleDateString(undefined, {
    day: "2-digit", month: "short",
  });
}
function sizeLabel(bytes: number | null) {
  if (!bytes) return "";
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${Math.round(bytes / 1024)} KB`;
  return `${(bytes / 1024 / 1024).toFixed(1)} MB`;
}
</script>
