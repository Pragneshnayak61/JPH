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

      <h1 class="text-lg font-semibold text-ink-gray-9">Ticket submitted</h1>
      <p class="mt-2 text-p-base text-ink-gray-6">
        Our team will reply to your email.
      </p>

      <div class="mt-5 rounded-lg bg-surface-gray-2 p-3">
        <p class="text-p-sm text-ink-gray-6">Your ticket reference</p>
        <p class="mt-1 font-mono text-base font-medium text-ink-gray-9">
          {{ token }}
        </p>
      </div>

      <p class="mt-4 text-p-sm text-ink-gray-5">
        Bookmark the link below &mdash; it is the only way back to this
        ticket, and we cannot send it to you again.
      </p>

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
  </div>
</template>

<script setup lang="ts">
import { Button, FeatherIcon } from "frappe-ui";
import { useRouter } from "vue-router";

defineProps<{ token: string }>();
const router = useRouter();
</script>
