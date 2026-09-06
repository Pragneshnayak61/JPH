<template>
  <div class="p-6">
    <div class="flex flex-wrap items-start justify-between gap-3">
      <div>
        <h1 class="text-xl font-semibold text-ink-gray-9">Analytics</h1>
        <p class="mt-1 text-p-base text-ink-gray-6">
          How the queue is doing and who is closing tickets
        </p>
      </div>

      <!--
        Ek hi filter row, sabse upar. Har chart ka apna filter nahi —
        warna do charts alag-alag samay dikhate aur unhe saath rakhne
        ka koi matlab hi nahi rehta.
      -->
      <div class="flex items-center gap-2">
      <Button variant="subtle" :loading="refreshing" @click="refresh">
        Refresh
      </Button>
      <div class="flex rounded-lg border border-outline-gray-2 p-0.5">
        <button
          v-for="r in RANGES"
          :key="r.label"
          class="rounded-md px-3 py-1 text-p-sm transition-colors"
          :class="
            range === r.days
              ? 'bg-surface-gray-3 font-medium text-ink-gray-9'
              : 'text-ink-gray-6 hover:text-ink-gray-8'
          "
          @click="setRange(r.days)"
        >
          {{ r.label }}
        </button>
      </div>
      </div>
    </div>

    <div v-if="loading" class="py-16 text-center">
      <LoadingIndicator class="mx-auto h-5 w-5 text-ink-gray-5" />
    </div>

    <div v-else-if="error" class="py-16 text-center">
      <p class="text-p-base text-ink-red-7">{{ error }}</p>
    </div>

    <!-- Refetch par poora page khali nahi karte. Skeleton flash me
         layout uchhalta hai; halka karke rakhna behtar hai. -->
    <template v-else>
      <div :class="refreshing ? 'opacity-50 transition-opacity' : ''">
      <!--
        Stat tiles. NumberChart apna card khud nahi banata, isliye border
        yahan. Ek number ki kahani ke liye chart banana bekaar hota hai.
      -->
      <div class="mt-5 grid grid-cols-2 gap-3 lg:grid-cols-4">
        <div
          v-for="t in tiles"
          :key="t.title"
          class="overflow-hidden rounded-lg border border-outline-gray-2"
        >
          <NumberChart :config="t" />
        </div>
      </div>

      <div class="mt-4 grid gap-4 lg:grid-cols-[1.4fr_1fr]">
        <!-- resolved per agent -->
        <div class="rounded-lg border border-outline-gray-2 p-4">
          <div class="h-[320px]">
            <AxisChart v-if="stats.length" :config="resolvedChart" />
            <p
              v-else
              class="flex h-full items-center justify-center text-p-base text-ink-gray-5"
            >
              No agents yet.
            </p>
          </div>
        </div>

        <!-- status breakdown -->
        <div class="rounded-lg border border-outline-gray-2 p-4">
          <div class="h-[320px]">
            <DonutChart v-if="totals?.total" :config="statusChart" />
            <p
              v-else
              class="flex h-full items-center justify-center text-p-base text-ink-gray-5"
            >
              No tickets yet.
            </p>
          </div>
        </div>
      </div>

      <!-- Table: har value chart ke bina bhi padhi ja sake -->
      <section class="mt-6">
        <h2 class="text-p-base font-medium text-ink-gray-8">By agent</h2>
        <div
          class="mt-2 overflow-x-auto rounded-lg border border-outline-gray-2"
        >
          <table class="w-full text-p-base">
            <thead class="bg-surface-gray-1 text-p-sm text-ink-gray-6">
              <tr>
                <th class="px-4 py-2 text-left font-medium">Agent</th>
                <th class="px-4 py-2 text-left font-medium">Specialization</th>
                <th class="px-4 py-2 text-right font-medium">Assigned</th>
                <th class="px-4 py-2 text-right font-medium">Still open</th>
                <th class="px-4 py-2 text-right font-medium">Resolved</th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="a in stats"
                :key="a.agent_id"
                class="border-t border-outline-gray-2"
              >
                <td class="px-4 py-2.5 text-ink-gray-8">{{ a.label }}</td>
                <td class="px-4 py-2.5 text-ink-gray-6">
                  {{ a.specialization || "—" }}
                </td>
                <td class="px-4 py-2.5 text-right tabular-nums text-ink-gray-7">
                  {{ a.assigned }}
                </td>
                <td class="px-4 py-2.5 text-right tabular-nums text-ink-gray-7">
                  {{ a.open_count }}
                </td>
                <td class="px-4 py-2.5 text-right tabular-nums text-ink-gray-8">
                  {{ a.resolved }}
                </td>
              </tr>
              <tr v-if="!stats.length">
                <td colspan="5" class="px-4 py-8 text-center text-ink-gray-5">
                  No agents yet.
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>
      </div>
    </template>
  </div>
</template>

<script setup lang="ts">
import { supabase } from "@/lib/supabase";
import {
  AxisChart, Button, DonutChart, LoadingIndicator, NumberChart,
} from "frappe-ui";
import { computed, onMounted, ref } from "vue";

type AgentStat = {
  agent_id: string; label: string; specialization: string | null;
  assigned: number; open_count: number; resolved: number;
};
type Totals = {
  total: number; open: number; replied: number; resolved: number;
  closed: number; unassigned: number;
};

const RANGES = [
  { label: "All time", days: null as number | null },
  { label: "7 days", days: 7 },
  { label: "30 days", days: 30 },
  { label: "90 days", days: 90 },
];

const stats = ref<AgentStat[]>([]);
const totals = ref<Totals | null>(null);
// Default "All time".
//
// Pehle 30 din tha, aur wo galat nikla: purane import kiye hue tickets
// (May-June ke) filter se bahar reh jaate the, to chart khali dikhta
// tha aur lagta tha ki kuch update hi nahi ho raha. Helpdesk me
// "abhi tak kul kitna hua" pehla sawaal hota hai, "pichhle 30 din me"
// nahi — wo chun kar dekhne wali cheez hai.
const range = ref<number | null>(null);
const loading = ref(true);
const refreshing = ref(false);
const error = ref("");

/**
 * Status ke rang. Ye frappe-ui ke apne palette se hain, par 400-step
 * nahi — wo itne halke hain ki colour-blind reader ke liye green aur
 * gray me farq hi nahi bachta (validator me ΔE 4.0 aaya tha).
 *
 * "Closed" ke liye gray ki jagah violet hai: gray ka chroma 0 hota hai,
 * yani wo rang ginta hi nahi aur baaki se takraata hai. Is set ko
 * validator par chalaya hai — saare checks pass.
 */
const STATUS_COLORS = {
  open: "#df9310",     // amber
  replied: "#0c8ef8",  // blue
  resolved: "#258c5c", // green
  closed: "#6e57d1",   // violet
};

// Bar chart ek hi series hai, isliye ek hi rang. Har bar ka alag rang
// dena galat hota — bar ki lambai wo kaam pehle se kar rahi hai.
const BAR_COLOR = "#077ddf";

const tiles = computed(() => {
  const t = totals.value;
  if (!t) return [];
  return [
    { title: "Total tickets", value: t.total },
    { title: "Open", value: t.open + t.replied },
    { title: "Resolved", value: t.resolved + t.closed },
    { title: "Unassigned", value: t.unassigned },
  ];
});

const resolvedChart = computed(() => ({
  title: "Tickets resolved",
  subtitle: "Counted when a ticket is first marked resolved or closed",
  // series.name hi data ka key hai — AxisChart usi se value uthata hai.
  data: stats.value.map((a) => ({
    agent: a.specialization ? `${a.label} · ${a.specialization}` : a.label,
    Resolved: a.resolved,
  })),
  xAxis: { key: "agent", type: "category" as const },
  yAxis: { title: "Tickets" },
  // Labels agent ke naam hain — vertical bars ke neeche wo tirche karne
  // padte. Horizontal me seedhe padhe jaate hain.
  swapXY: true,
  series: [{ name: "Resolved", type: "bar" as const, color: BAR_COLOR }],
}));

const statusChart = computed(() => {
  const t = totals.value!;
  return {
    title: "By status",
    data: [
      { status: "Open", count: t.open },
      { status: "Replied", count: t.replied },
      { status: "Resolved", count: t.resolved },
      { status: "Closed", count: t.closed },
    ].filter((r) => r.count > 0),
    categoryColumn: "status",
    valueColumn: "count",
    colors: [
      STATUS_COLORS.open, STATUS_COLORS.replied,
      STATUS_COLORS.resolved, STATUS_COLORS.closed,
    ],
  };
});

async function load() {
  error.value = "";
  try {
    const args = { p_days: range.value };
    const [{ data: s, error: e1 }, { data: t, error: e2 }] = await Promise.all([
      supabase.rpc("agent_stats", args),
      supabase.rpc("ticket_totals", args),
    ]);
    if (e1) throw e1;
    if (e2) throw e2;
    stats.value = (s as AgentStat[]) ?? [];
    totals.value = t as Totals;
  } catch (e: any) {
    error.value = e?.message || "Could not load analytics";
  } finally {
    loading.value = false;
    refreshing.value = false;
  }
}

/**
 * Page sirf khulte waqt data laata hai. Ticket resolve karke wapas
 * aane par purana hi dikhta rehta tha, aur lagta tha ki kuch update
 * hi nahi ho raha.
 */
async function refresh() {
  refreshing.value = true;
  await load();
}

async function setRange(days: number | null) {
  if (range.value === days) return;
  range.value = days;
  refreshing.value = true;
  await load();
}

onMounted(load);
</script>
