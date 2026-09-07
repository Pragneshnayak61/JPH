<template>
  <div class="px-6 py-6">
    <div class="mb-4 flex flex-wrap items-start justify-between gap-3">
      <div>
        <h1 class="text-lg font-semibold text-ink-gray-9">Operations report</h1>
        <p class="mt-0.5 text-p-sm text-ink-gray-6">
          What was checked, by whom, and what came of it
        </p>
      </div>
      <Button @click="router.push('/admin/operations')">
        <template #prefix><FeatherIcon name="check-square" class="h-4 w-4" /></template>
        Back to checklist
      </Button>
    </div>

    <!-- ----------------------------------------------------- filters -->
    <div class="mb-5 flex flex-wrap items-end gap-2">
      <div class="flex gap-1">
        <Button
          v-for="p in presets"
          :key="p.label"
          :variant="activePreset === p.label ? 'subtle' : 'ghost'"
          @click="applyPreset(p)"
        >
          {{ p.label }}
        </Button>
      </div>
      <FormControl v-model="from" type="date" label="From" class="w-40" />
      <FormControl v-model="to" type="date" label="To" class="w-40" />
      <FormControl
        v-model="client"
        type="select"
        label="Client"
        :options="clientOptions"
        class="w-48"
      />
      <Button :loading="loading" @click="load">Run</Button>
      <Button :disabled="!rows.length" @click="exportCsv">
        <template #prefix><FeatherIcon name="download" class="h-4 w-4" /></template>
        Export CSV
      </Button>
    </div>

    <ErrorMessage :message="error" class="mb-4" />

    <div v-if="loading" class="py-20 text-center">
      <LoadingIndicator class="mx-auto h-6 w-6 text-ink-gray-5" />
    </div>

    <div
      v-else-if="!rows.length"
      class="rounded-lg border border-outline-gray-2 py-16 text-center"
    >
      <FeatherIcon name="file-text" class="mx-auto h-8 w-8 text-ink-gray-4" />
      <p class="mt-3 text-p-base text-ink-gray-7">Nothing in that period</p>
      <p class="mt-1 text-p-sm text-ink-gray-5">
        Try a wider date range, or check that the client has a checklist.
      </p>
    </div>

    <template v-else>
      <!-- tiles -->
      <div class="mb-5 grid gap-3 sm:grid-cols-3 lg:grid-cols-6">
        <div
          v-for="t in tiles"
          :key="t.label"
          class="rounded-lg border border-outline-gray-2 px-3 py-2.5"
        >
          <p class="text-p-sm text-ink-gray-6">{{ t.label }}</p>
          <p class="text-lg font-semibold" :class="t.tone">{{ t.value }}</p>
        </div>
      </div>

      <div class="mb-5 grid gap-4 lg:grid-cols-2">
        <!-- per client -->
        <div class="rounded-lg border border-outline-gray-2 p-4">
          <h2 class="mb-3 text-p-base font-medium text-ink-gray-8">By client</h2>
          <div v-for="c in byClient" :key="c.name" class="mb-3 last:mb-0">
            <div class="mb-1 flex items-center justify-between text-p-sm">
              <span class="text-ink-gray-8">{{ c.name }}</span>
              <span class="text-ink-gray-6">
                {{ c.completed }}/{{ c.countable }} &middot; {{ c.percent }}%
              </span>
            </div>
            <div class="h-1.5 overflow-hidden rounded-full bg-surface-gray-3">
              <div
                class="h-full rounded-full"
                :class="c.percent === 100 ? 'bg-surface-green-5' : 'bg-surface-gray-6'"
                :style="{ width: c.percent + '%' }"
              />
            </div>
          </div>
        </div>

        <!-- status split -->
        <div class="rounded-lg border border-outline-gray-2 p-4">
          <!-- Heading chart ke apne config me hai (DonutChart use
               maangta hai), isliye yahan dobara nahi likhi. -->
          <DonutChart v-if="statusChart.data.length" :config="statusChart" />
          <p v-else class="text-p-sm text-ink-gray-6">Nothing to show</p>
        </div>
      </div>

      <!--
        Jo baar-baar bigadti hai.

        Sabse upar isliye ki poori report me kaam ki baat yahi hai. Sab
        theek chal raha ho to ye hissa aata hi nahi — khali table dikha
        kar dhyan maangna galat hoga.
      -->
      <div
        v-if="troubled.length"
        class="mb-5 overflow-hidden rounded-lg border border-outline-gray-2"
      >
        <div class="bg-surface-gray-1 px-4 py-2">
          <span class="text-p-sm font-medium text-ink-gray-8">
            Checks that keep going wrong
          </span>
          <span class="ml-2 text-p-sm text-ink-gray-5">
            worth looking at the machine, not the checklist
          </span>
        </div>
        <div class="overflow-x-auto">
          <table class="w-full text-left">
            <thead class="text-p-sm text-ink-gray-6">
              <tr>
                <th class="px-4 py-2 font-medium">Check</th>
                <th class="px-4 py-2 font-medium">Client</th>
                <th class="px-4 py-2 font-medium">Runs</th>
                <th class="px-4 py-2 font-medium">Failed</th>
                <th class="px-4 py-2 font-medium">Attention</th>
                <th class="px-4 py-2 font-medium">Last trouble</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-outline-gray-2">
              <tr v-for="t in troubled" :key="t.key">
                <td class="px-4 py-2 text-p-sm text-ink-gray-8">
                  {{ t.task }}
                  <span v-if="t.device" class="text-ink-gray-5">· {{ t.device }}</span>
                </td>
                <td class="px-4 py-2 text-p-sm text-ink-gray-6">{{ t.client }}</td>
                <td class="px-4 py-2 text-p-sm text-ink-gray-6">{{ t.runs }}</td>
                <td
                  class="px-4 py-2 text-p-sm"
                  :class="t.failed ? 'text-ink-red-7' : 'text-ink-gray-5'"
                >
                  {{ t.failed }}
                </td>
                <td
                  class="px-4 py-2 text-p-sm"
                  :class="t.attention ? 'text-ink-amber-9' : 'text-ink-gray-5'"
                >
                  {{ t.attention }}
                </td>
                <td class="px-4 py-2 text-p-sm text-ink-gray-6">
                  {{ t.last ? shortDate(t.last) : "—" }}
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!--
        Din-ba-din. Ek din ki range me sirf ek patti banti, isliye tab
        chhod dete hain.
      -->
      <div v-if="byDay.length > 1" class="mb-5 rounded-lg border border-outline-gray-2 p-4">
        <div class="mb-3 flex items-baseline justify-between">
          <h2 class="text-p-base font-medium text-ink-gray-8">Day by day</h2>
          <span class="text-p-sm text-ink-gray-5">completed, out of what was due</span>
        </div>
        <div class="flex h-24 items-end gap-px overflow-x-auto">
          <div
            v-for="d in byDay"
            :key="d.date"
            class="flex min-w-[6px] flex-1 flex-col justify-end self-stretch"
            :title="`${shortDate(d.date)} — ${d.done}/${d.countable} (${d.percent}%)`"
          >
            <div
              class="rounded-sm"
              :class="
                d.percent === 100
                  ? 'bg-surface-green-5'
                  : d.percent >= 80
                    ? 'bg-surface-gray-6'
                    : 'bg-surface-red-5'
              "
              :style="{ height: Math.max(d.percent, 3) + '%' }"
            />
          </div>
        </div>
        <div class="mt-2 flex justify-between text-p-sm text-ink-gray-5">
          <span>{{ shortDate(byDay[0].date) }}</span>
          <span>{{ shortDate(byDay[byDay.length - 1].date) }}</span>
        </div>
      </div>

      <!-- per category -->
      <div class="mb-5 overflow-hidden rounded-lg border border-outline-gray-2">
        <div class="bg-surface-gray-1 px-4 py-2 text-p-sm font-medium text-ink-gray-8">
          By category
        </div>
        <table class="w-full text-left">
          <thead class="text-p-sm text-ink-gray-6">
            <tr>
              <th class="px-4 py-2 font-medium">Category</th>
              <th class="px-4 py-2 font-medium">Checks</th>
              <th class="px-4 py-2 font-medium">Completed</th>
              <th class="px-4 py-2 font-medium">Failed</th>
              <th class="px-4 py-2 font-medium">Attention</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-outline-gray-2">
            <tr v-for="c in byCategory" :key="c.name">
              <td class="px-4 py-2 text-p-sm text-ink-gray-8">{{ c.name }}</td>
              <td class="px-4 py-2 text-p-sm text-ink-gray-6">{{ c.total }}</td>
              <td class="px-4 py-2 text-p-sm text-ink-green-8">{{ c.completed }}</td>
              <td class="px-4 py-2 text-p-sm" :class="c.failed ? 'text-ink-red-7' : 'text-ink-gray-5'">
                {{ c.failed }}
              </td>
              <td class="px-4 py-2 text-p-sm" :class="c.attention ? 'text-ink-amber-9' : 'text-ink-gray-5'">
                {{ c.attention }}
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!--
        Kisne kitna kiya. Naam nahi, agent code — pehchaan is app me
        sabse chhupi rehti hai.
      -->
      <div
        v-if="byPerson.length"
        class="mb-5 overflow-hidden rounded-lg border border-outline-gray-2"
      >
        <div class="bg-surface-gray-1 px-4 py-2">
          <span class="text-p-sm font-medium text-ink-gray-8">By person</span>
          <span class="ml-2 text-p-sm text-ink-gray-5">
            only checks somebody has already acted on
          </span>
        </div>
        <table class="w-full text-left">
          <thead class="text-p-sm text-ink-gray-6">
            <tr>
              <th class="px-4 py-2 font-medium">Who</th>
              <th class="px-4 py-2 font-medium">Acted on</th>
              <th class="px-4 py-2 font-medium">Completed</th>
              <th class="px-4 py-2 font-medium">Failed</th>
              <th class="px-4 py-2 font-medium">Attention</th>
              <th class="px-4 py-2 font-medium">Skipped</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-outline-gray-2">
            <tr v-for="p in byPerson" :key="p.name">
              <td class="px-4 py-2 text-p-sm text-ink-gray-8">{{ p.name }}</td>
              <td class="px-4 py-2 text-p-sm text-ink-gray-6">{{ p.total }}</td>
              <td class="px-4 py-2 text-p-sm text-ink-green-8">{{ p.done }}</td>
              <td class="px-4 py-2 text-p-sm" :class="p.failed ? 'text-ink-red-7' : 'text-ink-gray-5'">
                {{ p.failed }}
              </td>
              <td class="px-4 py-2 text-p-sm" :class="p.attention ? 'text-ink-amber-9' : 'text-ink-gray-5'">
                {{ p.attention }}
              </td>
              <td class="px-4 py-2 text-p-sm text-ink-gray-5">{{ p.skipped }}</td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- full table -->
      <div class="overflow-hidden rounded-lg border border-outline-gray-2">
        <div class="flex items-center justify-between bg-surface-gray-1 px-4 py-2">
          <span class="text-p-sm font-medium text-ink-gray-8">Every check</span>
          <span class="text-p-sm text-ink-gray-5">{{ rows.length }} rows</span>
        </div>
        <!-- Chaudi table apne andar scroll hoti hai; page kabhi side me
             nahi khisakta. -->
        <div class="max-h-[32rem] overflow-auto">
          <table class="w-full min-w-[56rem] text-left">
            <thead class="sticky top-0 bg-surface-base text-p-sm text-ink-gray-6 shadow-sm">
              <tr>
                <th class="px-4 py-2 font-medium">Date</th>
                <th class="px-4 py-2 font-medium">Client</th>
                <th class="px-4 py-2 font-medium">Device</th>
                <th class="px-4 py-2 font-medium">Check</th>
                <th class="px-4 py-2 font-medium">Result</th>
                <th class="px-4 py-2 font-medium">By</th>
                <th class="px-4 py-2 font-medium">Remarks</th>
                <th class="px-4 py-2 font-medium">Ticket</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-outline-gray-2">
              <tr v-for="(r, i) in rows" :key="i">
                <td class="whitespace-nowrap px-4 py-2 text-p-sm text-ink-gray-6">
                  {{ shortDate(r.due_date) }}
                </td>
                <td class="px-4 py-2 text-p-sm text-ink-gray-8">{{ r.client_name }}</td>
                <td class="px-4 py-2 text-p-sm text-ink-gray-6">{{ r.device_name || "—" }}</td>
                <td class="px-4 py-2 text-p-sm text-ink-gray-8">
                  {{ r.task_name }}
                  <span class="text-ink-gray-5">· {{ r.category_name || "—" }}</span>
                </td>
                <td class="whitespace-nowrap px-4 py-2 text-p-sm" :class="statusTone(r.status)">
                  {{ statusLabel(r.status) }}
                </td>
                <td class="px-4 py-2 text-p-sm text-ink-gray-6">{{ r.performed_label || "—" }}</td>
                <td class="max-w-xs truncate px-4 py-2 text-p-sm text-ink-gray-6" :title="r.remarks ?? ''">
                  {{ r.remarks || "—" }}
                </td>
                <td class="px-4 py-2 text-p-sm">
                  <RouterLink
                    v-if="r.ticket_id"
                    :to="`/admin/tickets/${r.ticket_id}`"
                    class="text-ink-gray-7 underline"
                  >
                    #{{ r.ticket_id }}
                  </RouterLink>
                  <span v-else class="text-ink-gray-5">—</span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </template>
  </div>
</template>

<script setup lang="ts">
/**
 * Operations ki report — daily, weekly, monthly, client-wise.
 *
 * EK HI FUNCTION SE TEENO
 *
 * "Daily" ka matlab ek din ka range hai, "monthly" ka tees din ka. Andar
 * ek hi RPC hai (ops_report), sirf tareekhein badalti hain. Teen alag
 * report likhne par ek din teeno alag hisaab lagane lagti hain.
 *
 * CSV YAHIN BANTA HAI
 *
 * App me pehle koi export tha hi nahi. Server par banane ka matlab hota
 * ek aur Edge Function, sirf comma lagane ke liye — jabki data pehle se
 * browser me hai. Isliye yahin bana kar de dete hain.
 */
import { supabase } from "@/lib/supabase";
import {
  Button, DonutChart, ErrorMessage, FeatherIcon, FormControl,
  LoadingIndicator,
} from "frappe-ui";
import { computed, onMounted, ref } from "vue";
import { useRouter } from "vue-router";

const router = useRouter();

type ReportRow = {
  due_date: string;
  organization_id: string;
  client_name: string;
  device_name: string | null;
  category_name: string | null;
  task_name: string;
  status: string;
  remarks: string | null;
  performed_label: string | null;
  performed_at: string | null;
  ticket_id: number | null;
  ticket_status: string | null;
};

const rows = ref<ReportRow[]>([]);
const clients = ref<{ id: string; name: string }[]>([]);
const loading = ref(false);
const error = ref("");

function iso(d: Date) {
  return d.toISOString().slice(0, 10);
}
function daysAgo(n: number) {
  const d = new Date();
  d.setDate(d.getDate() - n);
  return iso(d);
}

const presets = [
  { label: "Today", from: () => iso(new Date()), to: () => iso(new Date()) },
  { label: "7 days", from: () => daysAgo(6), to: () => iso(new Date()) },
  { label: "30 days", from: () => daysAgo(29), to: () => iso(new Date()) },
  {
    label: "This month",
    from: () => {
      const d = new Date();
      return iso(new Date(d.getFullYear(), d.getMonth(), 1));
    },
    to: () => iso(new Date()),
  },
];

const from = ref(daysAgo(6));
const to = ref(iso(new Date()));
const client = ref("");
const activePreset = ref("7 days");

function applyPreset(p: (typeof presets)[number]) {
  from.value = p.from();
  to.value = p.to();
  activePreset.value = p.label;
  load();
}

const clientOptions = computed(() => [
  { label: "All clients", value: "" },
  ...clients.value.map((c) => ({ label: c.name, value: c.id })),
]);

async function load() {
  loading.value = true;
  error.value = "";
  try {
    const { data, error: e } = await supabase.rpc("ops_report", {
      p_from: from.value,
      p_to: to.value,
      p_org: client.value || null,
    });
    if (e) throw e;
    rows.value = (data as ReportRow[]) ?? [];
  } catch (e: any) {
    error.value = e?.message || "Could not build the report";
    rows.value = [];
  } finally {
    loading.value = false;
  }
}

onMounted(async () => {
  const { data } = await supabase.from("organizations").select("id, name").order("name");
  clients.value = (data as { id: string; name: string }[]) ?? [];
  await load();
});

// ------------------------------------------------------------ rollups
const tiles = computed(() => {
  const c = (s: string) => rows.value.filter((r) => r.status === s).length;
  return [
    { label: "Checks", value: rows.value.length, tone: "text-ink-gray-9" },
    { label: "Completed", value: c("completed"), tone: "text-ink-green-8" },
    { label: "Failed", value: c("failed"), tone: "text-ink-red-7" },
    { label: "Attention", value: c("attention"), tone: "text-ink-amber-9" },
    { label: "Skipped", value: c("skipped"), tone: "text-ink-gray-9" },
    {
      label: "Tickets raised",
      value: rows.value.filter((r) => r.ticket_id).length,
      tone: "text-ink-gray-9",
    },
  ];
});

const byClient = computed(() => {
  const map = new Map<string, { name: string; total: number; completed: number; countable: number }>();
  for (const r of rows.value) {
    const k = r.client_name;
    if (!map.has(k)) map.set(k, { name: k, total: 0, completed: 0, countable: 0 });
    const g = map.get(k)!;
    g.total += 1;
    // Wahi niyam jo checklist aur ops_summary me hai: jaan-boojh kar
    // chhodi hui jaanch adhoori nahi hai, isliye ginti se bahar.
    if (r.status !== "skipped") g.countable += 1;
    if (r.status === "completed") g.completed += 1;
  }
  return [...map.values()]
    .map((g) => ({
      ...g,
      percent: g.countable === 0 ? 100 : Math.round((100 * g.completed) / g.countable),
    }))
    .sort((a, b) => a.name.localeCompare(b.name));
});

const byCategory = computed(() => {
  const map = new Map<string, { name: string; total: number; completed: number; failed: number; attention: number }>();
  for (const r of rows.value) {
    const k = r.category_name ?? "—";
    if (!map.has(k)) map.set(k, { name: k, total: 0, completed: 0, failed: 0, attention: 0 });
    const g = map.get(k)!;
    g.total += 1;
    if (r.status === "completed") g.completed += 1;
    if (r.status === "failed") g.failed += 1;
    if (r.status === "attention") g.attention += 1;
  }
  return [...map.values()].sort((a, b) => b.total - a.total);
});

/**
 * Jo jaanch baar-baar bigadti hai.
 *
 * Baaki har hisaab ye batata hai ki KAAM HUA YA NAHI. Ye ek hi cheez
 * batati hai ki KYA KHARAB HAI — aur asli faayda usi me hai.
 *
 * Ek din backup fail ho jaye to wo us din ka masla hai. Wahi backup
 * mahine me chhe baar fail ho to wo checklist ka masla nahi raha, wo
 * server ka masla hai — aur ye baat aaj tak kahin nahi dikhti thi,
 * kyunki har din ki row alag-alag padi rehti hai.
 *
 * Client ke saath jodh kar ginte hain, sirf task ke naam se nahi. "Disk
 * space" teeno client par lagti hai; teeno ko ek me mila dene se pata
 * hi na chalta ki kis client ki disk bhar rahi hai.
 */
const troubled = computed(() => {
  type T = {
    key: string; task: string; client: string; device: string | null;
    runs: number; failed: number; attention: number; last: string;
  };
  const map = new Map<string, T>();
  for (const r of rows.value) {
    const key = `${r.client_name}|${r.task_name}|${r.device_name ?? ""}`;
    if (!map.has(key)) {
      map.set(key, {
        key, task: r.task_name, client: r.client_name,
        device: r.device_name, runs: 0, failed: 0, attention: 0, last: "",
      });
    }
    const g = map.get(key)!;
    g.runs += 1;
    if (r.status === "failed") g.failed += 1;
    if (r.status === "attention") g.attention += 1;
    if (r.status === "failed" || r.status === "attention") {
      if (r.due_date > g.last) g.last = r.due_date;
    }
  }
  return [...map.values()]
    .filter((g) => g.failed + g.attention > 0)
    // Fail ka wazan attention se zyada — dono ko barabar ginne par ek
    // baar ka asli fail, teen baar ke "dekhte rehna" ke neeche dab
    // jaata hai.
    .sort((a, b) => b.failed * 2 + b.attention - (a.failed * 2 + a.attention))
    .slice(0, 10);
});

/**
 * Kisne kitna kiya.
 *
 * Naam yahan nahi aata — ops_person_label() agent code deta hai, kyunki
 * is app me pehchaan sabse chhupi rehti hai (24_identity.sql). Aur ye
 * theek bhi hai: hisaab ke liye ye jaanna kaafi hai ki kaam BANT kaise
 * raha hai, ye nahi ki kaun hai.
 *
 * Jo rows abhi tak kisi ne chhui hi nahi (pending) unka koi maalik nahi
 * hota, isliye wo yahan se bahar hain — warna "koi nahi" sabse bada
 * naam ban jaata aur baaki sab uske neeche dab jaate.
 */
const byPerson = computed(() => {
  const map = new Map<
    string,
    { name: string; done: number; failed: number; attention: number; skipped: number; total: number }
  >();
  for (const r of rows.value) {
    if (!r.performed_label) continue;
    const k = r.performed_label;
    if (!map.has(k)) {
      map.set(k, { name: k, done: 0, failed: 0, attention: 0, skipped: 0, total: 0 });
    }
    const g = map.get(k)!;
    g.total += 1;
    if (r.status === "completed") g.done += 1;
    if (r.status === "failed") g.failed += 1;
    if (r.status === "attention") g.attention += 1;
    if (r.status === "skipped") g.skipped += 1;
  }
  return [...map.values()].sort((a, b) => b.total - a.total);
});

/**
 * Din-ba-din.
 *
 * Ek mahine ka ek hi aankda ("94% poora") ye chhupa deta hai ki kis din
 * kya hua. 94% teen tarah se aa sakta hai: roz thoda chhootna, ya ek
 * din poora tootna. Dono ka ilaaj alag hai.
 *
 * Chart library nahi laga rahe — ye seedhi si patti hai, aur uske liye
 * ek aur bhaari chunk uthana bekaar hoga.
 */
const byDay = computed(() => {
  const map = new Map<string, { date: string; countable: number; done: number }>();
  for (const r of rows.value) {
    if (!map.has(r.due_date)) {
      map.set(r.due_date, { date: r.due_date, countable: 0, done: 0 });
    }
    const g = map.get(r.due_date)!;
    // Wahi niyam jo byClient me hai: chhodi hui jaanch adhoori nahi.
    if (r.status !== "skipped") g.countable += 1;
    if (r.status === "completed") g.done += 1;
  }
  return [...map.values()]
    .sort((a, b) => a.date.localeCompare(b.date))
    .map((g) => ({
      ...g,
      percent: g.countable === 0 ? 100 : Math.round((100 * g.done) / g.countable),
    }));
});

const statusChart = computed(() => {
  const c = (s: string) => rows.value.filter((r) => r.status === s).length;
  return {
    title: "By result",
    data: [
      { status: "Completed", count: c("completed") },
      { status: "Failed", count: c("failed") },
      { status: "Attention", count: c("attention") },
      { status: "Pending", count: c("pending") + c("in_progress") },
      { status: "Skipped", count: c("skipped") },
    ].filter((r) => r.count > 0),
    categoryColumn: "status",
    valueColumn: "count",
    colors: ["#258c5c", "#e03636", "#d68000", "#8a9391", "#b3bab8"],
  };
});

// ---------------------------------------------------------------- csv
function exportCsv() {
  const head = [
    "Date", "Client", "Device", "Category", "Check",
    "Result", "Performed by", "Performed at", "Remarks", "Ticket",
  ];
  const body = rows.value.map((r) => [
    r.due_date,
    r.client_name,
    r.device_name ?? "",
    r.category_name ?? "",
    r.task_name,
    statusLabel(r.status),
    r.performed_label ?? "",
    r.performed_at ?? "",
    r.remarks ?? "",
    r.ticket_id ? `#${r.ticket_id}` : "",
  ]);

  const csv = [head, ...body].map((row) => row.map(cell).join(",")).join("\r\n");

  // BOM lagana zaroori hai. Iske bina Excel UTF-8 nahi pehchanta aur
  // naam waghera tootey hue akshar me dikhte hain.
  const blob = new Blob(["﻿" + csv], { type: "text/csv;charset=utf-8" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = `operations-${from.value}-to-${to.value}.csv`;
  a.click();
  URL.revokeObjectURL(url);
}

function cell(v: string) {
  const s = String(v ?? "");
  // Comma, quote ya newline wale khaane ko quote karna hi padta hai,
  // warna ek remark poori row ke khaane khisak deta hai.
  if (/[",\r\n]/.test(s)) return `"${s.replace(/"/g, '""')}"`;
  return s;
}

// ------------------------------------------------------------- format
const STATUS_LABELS: Record<string, string> = {
  pending: "Pending",
  in_progress: "In progress",
  completed: "Completed",
  failed: "Failed",
  attention: "Needs attention",
  skipped: "Skipped",
};
function statusLabel(s: string) {
  return STATUS_LABELS[s] ?? s;
}
function statusTone(s: string) {
  if (s === "completed") return "text-ink-green-8";
  if (s === "failed") return "text-ink-red-7";
  if (s === "attention") return "text-ink-amber-9";
  return "text-ink-gray-6";
}
function shortDate(d: string) {
  return new Date(d + "T00:00:00").toLocaleDateString(undefined, {
    day: "2-digit", month: "short", year: "2-digit",
  });
}
</script>
