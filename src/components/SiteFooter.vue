<template>
  <footer class="mt-10 border-t border-outline-gray-2 pt-5 text-center">
    <p class="text-p-sm text-ink-gray-5">
      &copy; {{ year }} {{ name }}. All rights reserved.
    </p>
    <p class="mt-1 text-p-sm text-ink-gray-4">
      <RouterLink to="/" class="hover:text-ink-gray-6">Support</RouterLink>
      <span class="px-1.5">&middot;</span>
      <RouterLink to="/my-tickets" class="hover:text-ink-gray-6">
        Your tickets
      </RouterLink>
    </p>
  </footer>
</template>

<script setup lang="ts">
import { useSettingsStore } from "@/stores/settings";
import { computed, onMounted } from "vue";

const store = useSettingsStore();

// Saal hardcode nahi kiya — har 1 January ko purana dikhne lagta.
const year = new Date().getFullYear();

// legal_name alag isliye ki company ka poora kanooni naam ("JPH
// Technologies Pvt Ltd") aksar us naam se lamba hota hai jo header me
// dikhta hai ("JPH Support"). Na ho to company_name hi chalega.
const name = computed(
  () => store.settings.legal_name?.trim() || store.settings.company_name
);

onMounted(() => store.load());
</script>
