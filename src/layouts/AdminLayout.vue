<template>
  <div class="flex h-full">
    <!-- sidebar -->
    <aside
      class="flex w-56 shrink-0 flex-col border-r border-outline-gray-2 bg-surface-gray-1"
    >
      <div class="flex items-center gap-2 px-4 py-3">
        <div
          class="flex h-7 w-7 shrink-0 items-center justify-center overflow-hidden rounded text-sm font-semibold text-white"
          :style="{ background: s.logo_url ? '#fff' : s.accent_color }"
        >
          <img v-if="s.logo_url" :src="s.logo_url" alt="" class="h-full w-full object-contain" />
          <span v-else>{{ s.company_name.charAt(0).toUpperCase() }}</span>
        </div>
        <span class="truncate text-base font-medium text-ink-gray-8">
          {{ s.company_name }}
        </span>
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
        <RouterLink
          to="/admin/profile"
          class="flex items-center gap-2 rounded px-2 py-1.5 hover:bg-surface-gray-2"
          active-class="bg-surface-gray-3"
        >
          <Avatar :label="userEmail" size="sm" />
          <div class="min-w-0 leading-tight">
            <p class="truncate text-p-sm text-ink-gray-7">{{ userEmail }}</p>
            <p class="text-p-sm text-ink-gray-5">
              {{ auth.profile?.agent_code || "My profile" }}
            </p>
          </div>
        </RouterLink>
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
import { useSettingsStore } from "@/stores/settings";
import { Avatar, FeatherIcon } from "frappe-ui";
import { computed, onMounted } from "vue";
import { useRouter } from "vue-router";

const router = useRouter();
const auth = useAuthStore();
const settingsStore = useSettingsStore();
const s = computed(() => settingsStore.settings);
const userEmail = computed(() => auth.profile?.email ?? "");

onMounted(() => settingsStore.load());

// People sirf admin ko. Guard bhi rokta hai, par link dikhana hi galat
// hai — user click karke bounce ho, isse bura kuch nahi.
const nav = computed(() => [
  { to: "/admin", label: "Dashboard", icon: "home" },
  { to: "/admin/analytics", label: "Analytics", icon: "bar-chart-2" },
  ...(auth.isAdmin
    ? [{ to: "/admin/agents", label: "People", icon: "users" }]
    : []),
  ...(auth.can("can_change_settings")
    ? [{ to: "/admin/settings", label: "Settings", icon: "settings" }]
    : []),
]);

async function signOut() {
  await auth.signOut();
  router.push({ name: "Login" });
}
</script>
