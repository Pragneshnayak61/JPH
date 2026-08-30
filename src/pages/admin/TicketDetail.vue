<template>
  <div class="p-6">
    <h1 class="text-xl font-semibold text-ink-gray-9">Ticket #{{ id }}</h1>
    <p class="mt-2 text-p-base text-ink-gray-6">
      This page is not built yet &mdash; coming in the next step.
    </p>
  </div>
</template>

<script setup lang="ts">
defineProps<{ id: string }>();
</script>
