<template>
  <div class="min-h-full bg-surface-gray-1 py-10">
    <div class="mx-auto w-full max-w-2xl px-4">
      <button
        class="mb-4 flex items-center gap-1 text-p-sm text-ink-gray-6 hover:text-ink-gray-8"
        @click="router.push('/')"
      >
        <FeatherIcon name="arrow-left" class="h-3.5 w-3.5" />
        Back
      </button>

      <h1 class="text-lg font-semibold text-ink-gray-9">Your tickets</h1>
      <p class="mt-1 text-p-base text-ink-gray-6">
        Tickets you sent from this device
      </p>

      <div
        v-if="!tickets.length"
        class="mt-5 rounded-xl border border-outline-gray-2 bg-surface-base p-8 text-center"
      >
        <p class="text-p-base text-ink-gray-6">
          Nothing saved on this device yet.
        </p>
        <Button variant="solid" class="mt-4" @click="router.push('/')">
          Raise a ticket
        </Button>
      </div>

      <template v-else>
        <div
          class="mt-5 divide-y divide-outline-gray-2 overflow-hidden rounded-xl border border-outline-gray-2 bg-surface-base"
        >
          <RouterLink
            v-for="t in tickets"
            :key="t.token"
            :to="{ name: 'GuestTicketView', params: { token: t.token } }"
            class="flex items-center justify-between gap-3 px-4 py-3 hover:bg-surface-gray-1"
          >
            <div class="min-w-0">
              <p class="truncate text-p-base text-ink-gray-8">
                {{ t.subject }}
              </p>
              <p class="mt-0.5 text-p-sm text-ink-gray-5">
                Sent {{ formatDate(t.saved_at) }}
              </p>
            </div>
            <FeatherIcon
              name="chevron-right"
              class="h-4 w-4 shrink-0 text-ink-gray-5"
            />
          </RouterLink>
        </div>

        <div class="mt-4 flex items-center justify-between">
          <p class="text-p-sm text-ink-gray-5">
            Saved on this device only.
          </p>
          <button
            class="text-p-sm text-ink-gray-6 underline hover:text-ink-gray-8"
            @click="forgetAll"
          >
            Forget these
          </button>
        </div>
      </template>

      <SiteFooter />
    </div>
  </div>
</template>

<script setup lang="ts">
import SiteFooter from "@/components/SiteFooter.vue";
import { forgetTickets, getMyTickets } from "@/lib/myTickets";
import { Button, FeatherIcon } from "frappe-ui";
import { onMounted, ref } from "vue";
import { useRouter } from "vue-router";

const router = useRouter();
const tickets = ref(getMyTickets());

function formatDate(s: string) {
  return new Date(s).toLocaleDateString(undefined, {
    day: "numeric", month: "short", year: "numeric",
  });
}

function forgetAll() {
  forgetTickets();
  tickets.value = [];
}

onMounted(() => (tickets.value = getMyTickets()));
</script>
