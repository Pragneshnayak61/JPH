<template>
  <div class="h-full">
    <!-- Supabase abhi set nahi hua to blank screen ke bajaye saaf message -->
    <div
      v-if="!isSupabaseConfigured"
      class="fixed inset-x-0 top-0 z-50 bg-surface-amber-2 px-4 py-2 text-center text-sm text-ink-amber-3"
    >
      Supabase abhi connect nahi hua &mdash;
      <code class="font-mono">.env</code> file me
      <code class="font-mono">VITE_SUPABASE_URL</code> aur
      <code class="font-mono">VITE_SUPABASE_ANON_KEY</code> daaliye.
    </div>

    <RouterView />
  </div>
</template>

<script setup lang="ts">
import { isSupabaseConfigured } from "@/lib/supabase";
</script>
