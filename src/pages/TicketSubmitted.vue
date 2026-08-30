<template>
  <div class="flex min-h-full items-center justify-center bg-surface-gray-1 p-4">
    <div
      class="w-full max-w-md rounded-xl border border-outline-gray-2 bg-surface-base p-8 text-center shadow-sm"
    >
      <div
        class="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-surface-green-2"
      >
        <FeatherIcon name="check" class="h-6 w-6 text-ink-green-3" />
      </div>

      <h1 class="text-lg font-semibold text-ink-gray-9">Ticket bhej diya gaya</h1>
      <p class="mt-2 text-p-base text-ink-gray-6">
        Hamari team aapke email par jawab degi.
      </p>

      <div class="mt-5 rounded-lg bg-surface-gray-2 p-3">
        <p class="text-p-sm text-ink-gray-6">Aapka ticket number</p>
        <p class="mt-1 font-mono text-base font-medium text-ink-gray-9">
          {{ token }}
        </p>
      </div>

      <p class="mt-4 text-p-sm text-ink-gray-5">
        Ise sambhal kar rakhiye &mdash; ticket ki halat dekhne ke kaam aayega.
      </p>

      <Button variant="subtle" class="mt-5 w-full" @click="router.push('/')">
        Ek aur ticket bhejiye
      </Button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { Button, FeatherIcon } from "frappe-ui";
import { useRouter } from "vue-router";

defineProps<{ token: string }>();
const router = useRouter();
</script>
