<template>
  <div class="p-6">
    <h1 class="text-xl font-semibold text-ink-gray-9">Analytics</h1>
    <p class="mt-1 text-p-base text-ink-gray-6">
      How the queue is doing and who is closing tickets
    </p>

    <div v-if="loading" class="py-16 text-center">
      <LoadingIndicator class="mx-auto h-5 w-5 text-ink-gray-5" />
    </div>

    <div v-else-if="error" class="py-16 text-center">
      <p class="text-p-base text-ink-red-3">{{ error }}</p>
    </div>

    <template v-else>
      <!-- stat tiles. Ek number ki kahani ke liye chart banana bekaar hai. -->
      <div class="mt-5 grid grid-cols-2 gap-3 lg:grid-cols-5">
        <div
          v-for="t in tiles"
          :key="t.label"
          class="rounded-lg border border-outline-gray-2 p-4"
        >
          <div class="flex items-center gap-1.5">
            <span
              v-if="t.dot"
              class="h-1.5 w-1.5 rounded-full"
              :class="t.dot"
            ></span>
            <p class="text-p-sm text-ink-gray-6">{{ t.label }}</p>
          </div>
          <p class="mt-1 text-2xl font-semibold text-ink-gray-9">
            {{ t.value }}
          </p>
        </div>
      </div>

      <!-- chart -->
      <section class="mt-6 rounded-lg border border-outline-gray-2 p-4">
        <h2 class="text-p-base font-medium text-ink-gray-8">
          Tickets resolved
        </h2>
        <p class="mt-0.5 text-p-sm text-ink-gray-5">
          Counted when a ticket is first marked resolved or closed
        </p>

        <p
          v-if="!stats.length"
          class="py-10 text-center text-p-base text-ink-gray-5"
        >
          No agents yet.
        </p>

        <!--
          Horizontal bars: labels naam hain, jo vertical bars ke neeche
          tirche karne padte. Ek hi rang har bar par — ye pehchaan hai,
          magnitude nahi; bar ki lambai wahi kaam pehle se kar rahi hai.
        -->
        <div v-else class="mt-4 space-y-2.5">
          <div
            v-for="a in stats"
            :key="a.agent_id"
            class="grid grid-cols-[minmax(80px,140px)_1fr_auto] items-center gap-3"
          >
            <span class="truncate text-p-sm text-ink-gray-7">
              {{ a.label }}
            </span>
            <div class="h-5 rounded bg-surface-gray-2">
              <div
                class="h-5 rounded bg-surface-blue-5 transition-[width] duration-300"
                :style="{ width: barWidth(a.resolved) }"
              ></div>
            </div>
            <span class="w-8 text-right text-p-sm tabular-nums text-ink-gray-7">
              {{ a.resolved }}
            </span>
          </div>
        </div>
      </section>

      <!-- table: har value yahan bhi milti hai, sirf chart par nirbhar nahi -->
      <section class="mt-6">
        <h2 class="text-p-base font-medium text-ink-gray-8">By agent</h2>
        <div
          class="mt-2 overflow-x-auto rounded-lg border border-outline-gray-2"
        >
          <table class="w-full text-p-base">
            <thead class="bg-surface-gray-1 text-p-sm text-ink-gray-6">
              <tr>
                <th class="px-4 py-2 text-left font-medium">Agent</th>
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
                <td colspan="4" class="px-4 py-8 text-center text-ink-gray-5">
                  No agents yet.
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>
    </template>
  </div>
</template>

<script setup lang="ts">
import { supabase } from "@/lib/supabase";
import { LoadingIndicator } from "frappe-ui";
import { computed, onMounted, ref } from "vue";

type AgentStat = {
  agent_id: string; label: string;
  assigned: number; open_count: number; resolved: number;
};
type Totals = {
  total: number; open: number; replied: number; resolved: number;
  closed: number; unassigned: number; last_7_days: number;
};

const stats = ref<AgentStat[]>([]);
const totals = ref<Totals | null>(null);
const loading = ref(true);
const error = ref("");

const tiles = computed(() => {
  const t = totals.value;
  if (!t) return [];
  return [
    { label: "Total tickets", value: t.total, dot: "" },
    { label: "Open", value: t.open + t.replied, dot: "bg-surface-amber-5" },
    { label: "Resolved", value: t.resolved + t.closed, dot: "bg-surface-green-5" },
    { label: "Unassigned", value: t.unassigned, dot: "bg-surface-red-5" },
    { label: "Last 7 days", value: t.last_7_days, dot: "" },
  ];
});

// Sabse lambi bar 100% — chhote numbers bhi tab dikhte hain.
// max 0 hone par 0/0 = NaN aa jaata, isliye guard.
const maxResolved = computed(() =>
  Math.max(1, ...stats.value.map((a) => a.resolved))
);
function barWidth(n: number) {
  if (!n) return "0%";
  // 3% minimum, warna 1 ticket wali bar dikhti hi nahi.
  return `${Math.max(3, (n / maxResolved.value) * 100)}%`;
}

onMounted(async () => {
  try {
    const [{ data: s, error: e1 }, { data: t, error: e2 }] = await Promise.all([
      supabase.rpc("agent_stats"),
      supabase.rpc("ticket_totals"),
    ]);
    if (e1) throw e1;
    if (e2) throw e2;
    stats.value = (s as AgentStat[]) ?? [];
    totals.value = t as Totals;
  } catch (e: any) {
    error.value = e?.message || "Could not load analytics";
  } finally {
    loading.value = false;
  }
});
</script>
