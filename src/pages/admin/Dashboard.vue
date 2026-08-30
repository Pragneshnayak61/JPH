<template>
  <div class="p-6">
    <h1 class="text-xl font-semibold text-ink-gray-9">Dashboard</h1>
    <p class="mt-1 text-p-base text-ink-gray-6">
      Saare tickets yahin dikhte hain
    </p>

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
        <div class="col-span-2">Se aaya</div>
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
        Abhi koi ticket nahi hai.
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
  </div>
</template>

<script setup lang="ts">
import { supabase } from "@/lib/supabase";
import { Badge, LoadingIndicator } from "frappe-ui";
import { computed, onMounted, ref } from "vue";

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
    { label: "Kul tickets", value: tickets.value.length },
    { label: "Open", value: by("open") },
    { label: "Replied", value: by("replied") },
    { label: "Resolved", value: by("resolved") },
  ];
});

onMounted(async () => {
  try {
    const { data, error: err } = await supabase
      .from("tickets")
      .select("id, subject, status, priority, contact_name, raised_by_email, created_at")
      .order("created_at", { ascending: false });
    if (err) throw err;
    tickets.value = data ?? [];
  } catch (e: any) {
    error.value = e?.message || "Tickets load nahi ho paye";
  } finally {
    loading.value = false;
  }
});
</script>
