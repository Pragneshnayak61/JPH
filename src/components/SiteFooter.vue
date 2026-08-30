<template>
  <footer
    class="border-t border-outline-gray-2 text-center"
    :class="compact ? 'mt-6 px-6 py-4' : 'mt-10 pt-5'"
  >
    <p class="text-p-sm text-ink-gray-5">
      &copy; {{ name }}. All rights reserved.
    </p>
    <p v-if="email" class="mt-1 text-p-sm text-ink-gray-5">
      <a :href="`mailto:${email}`" class="hover:text-ink-gray-7">{{ email }}</a>
    </p>
  </footer>
</template>

<script setup lang="ts">
import { useSettingsStore } from "@/stores/settings";
import { computed, onMounted } from "vue";

// Admin pages par chhota rakhte hain — wahan footer kaam ki cheez nahi,
// bas maujood hona chahiye. Guest pages par wo page ka hissa hai.
withDefaults(defineProps<{ compact?: boolean }>(), { compact: false });

const store = useSettingsStore();

// legal_name alag isliye ki company ka poora kanooni naam ("JPH
// Technologies Pvt Ltd") aksar us naam se lamba hota hai jo header me
// dikhta hai ("JPH Support"). Na ho to company_name hi chalega.
const name = computed(
  () => store.settings.legal_name?.trim() || store.settings.company_name
);

// Khali hone par poori line hi chhup jaati hai — khali jagah ya adha
// footer dikhane se behtar hai kuch na dikhana.
const email = computed(() => store.settings.contact_email?.trim() || "");

onMounted(() => store.load());
</script>
