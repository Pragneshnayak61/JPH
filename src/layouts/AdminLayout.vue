<template>
  <div class="flex h-full">
    <!-- sidebar -->
    <aside
      class="flex w-56 shrink-0 flex-col border-r border-outline-gray-2 bg-surface-gray-1"
    >
      <div class="flex items-center gap-2 px-4 py-3">
        <div
          class="flex h-7 w-7 items-center justify-center rounded bg-surface-gray-7 text-sm font-semibold text-white"
        >
          J
        </div>
        <span class="text-base font-medium text-ink-gray-8">JPH Helpdesk</span>
      </div>

      <nav class="flex-1 space-y-0.5 px-2 py-2">
        <RouterLink
          v-for="item in nav"
          :key="item.to"
          :to="item.to"
          class="flex items-center gap-2 rounded px-2 py-1.5 text-p-base text-ink-gray-7 hover:bg-surface-gray-2"
          active-class="bg-surface-gray-3 text-ink-gray-9"
        >
          <FeatherIcon :name="item.icon" class="h-4 w-4" />
          {{ item.label }}
        </RouterLink>
      </nav>

      <div class="border-t border-outline-gray-2 p-2">
        <div class="flex items-center gap-2 px-2 py-1.5">
          <Avatar :label="userEmail" size="sm" />
          <span class="truncate text-p-sm text-ink-gray-7">{{ userEmail }}</span>
        </div>
        <button
          class="mt-1 flex w-full items-center gap-2 rounded px-2 py-1.5 text-p-sm text-ink-gray-6 hover:bg-surface-gray-2"
          @click="signOut"
        >
          <FeatherIcon name="log-out" class="h-4 w-4" />
          Logout
        </button>
      </div>
    </aside>

    <!-- content -->
    <main class="min-w-0 flex-1 overflow-auto bg-surface-base">
      <RouterView />
    </main>
  </div>
</template>

<script setup lang="ts">
import { useAuthStore } from "@/stores/auth";
import { Avatar, FeatherIcon } from "frappe-ui";
import { computed } from "vue";
import { useRouter } from "vue-router";

const router = useRouter();
const auth = useAuthStore();
const userEmail = computed(() => auth.profile?.email ?? "");

const nav = [
  { to: "/admin", label: "Dashboard", icon: "home" },
  { to: "/admin/agents", label: "Agents", icon: "users" },
];

async function signOut() {
  await auth.signOut();
  router.push({ name: "Login" });
}
</script>
