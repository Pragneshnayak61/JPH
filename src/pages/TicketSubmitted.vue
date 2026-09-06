<template>
  <div class="flex min-h-full items-center justify-center bg-surface-gray-1 p-4">
    <!-- Footer card ke BAHAR chahiye. Andar rakhne par wo safed card ka
         hissa lagta hai, jabki wo poore page ka footer hai. -->
    <div class="w-full max-w-md">
      <div
        class="rounded-xl border border-outline-gray-2 bg-surface-base p-8 text-center shadow-sm"
      >
      <div
        class="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-surface-green-2"
      >
        <FeatherIcon name="check" class="h-6 w-6 text-ink-green-8" />
      </div>

      <h1 class="text-lg font-semibold text-ink-gray-9">{{ s.thanks_title }}</h1>
      <p class="mt-2 text-p-base text-ink-gray-6">{{ s.thanks_message }}</p>

      <div class="mt-5 rounded-lg bg-surface-gray-2 p-3">
        <p class="text-p-sm text-ink-gray-6">Your ticket reference</p>
        <p class="mt-1 font-mono text-base font-medium text-ink-gray-9">
          {{ token }}
        </p>
      </div>

      <p class="mt-4 text-p-sm text-ink-gray-5">
        We saved this ticket in your browser, so you will find it on the
        home page next time. To open it from another device, copy the link
        below and keep it somewhere safe.
      </p>

      <button
        class="mt-3 w-full rounded-lg border border-outline-gray-2 px-3 py-2 text-left text-p-sm text-ink-gray-7 hover:bg-surface-gray-1"
        @click="copyLink"
      >
        <span class="block truncate font-mono">{{ ticketUrl }}</span>
        <span class="mt-1 block text-p-sm text-ink-gray-5">
          {{ copied ? "Copied" : "Click to copy" }}
        </span>
      </button>

      <Button
        variant="solid"
        class="mt-4 w-full"
        @click="router.push({ name: 'GuestTicketView', params: { token } })"
      >
        View my ticket
      </Button>
        <Button variant="subtle" class="mt-2 w-full" @click="router.push('/')">
          Submit another ticket
        </Button>
      </div>

      <SiteFooter />
    </div>
  </div>
</template>

<script setup lang="ts">
import SiteFooter from "@/components/SiteFooter.vue";
import { Button, FeatherIcon } from "frappe-ui";
import { useSettingsStore } from "@/stores/settings";
import { computed, onMounted, ref } from "vue";
import { useRouter } from "vue-router";

const props = defineProps<{ token: string }>();
const router = useRouter();

const ticketUrl = computed(
  () => `${window.location.origin}/ticket/${props.token}`
);
const copied = ref(false);

const settingsStore = useSettingsStore();
const s = computed(() => settingsStore.settings);
onMounted(() => settingsStore.load());

async function copyLink() {
  try {
    await navigator.clipboard.writeText(ticketUrl.value);
    copied.value = true;
    setTimeout(() => (copied.value = false), 2000);
  } catch {
    // clipboard http par ya permission na hone par fail hota hai.
    // Link screen par dikh hi raha hai, user haath se copy kar lega.
  }
}
</script>
