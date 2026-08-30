<template>
  <footer class="mt-10 border-t border-outline-gray-2 pt-5 text-center">
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
