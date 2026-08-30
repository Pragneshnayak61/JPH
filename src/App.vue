<template>
  <!-- FrappeUIProvider toast ka container ([data-sonner-toaster]) lagata
       hai. Iske bina toast() chup-chaap kuch nahi karta — koi error bhi
       nahi deta, bas message kabhi dikhta hi nahi. -->
  <FrappeUIProvider>
    <div class="h-full">
    <!-- Show a clear message instead of a blank screen when Supabase is not wired up yet -->
    <div
      v-if="!isSupabaseConfigured"
      class="fixed inset-x-0 top-0 z-50 bg-surface-amber-2 px-4 py-2 text-center text-sm text-ink-amber-3"
    >
      Supabase is not connected &mdash; set
      <code class="font-mono">VITE_SUPABASE_URL</code> and
      <code class="font-mono">VITE_SUPABASE_ANON_KEY</code> in your <code class="font-mono">.env</code> file.
    </div>

      <RouterView />
    </div>
  </FrappeUIProvider>
</template>

<script setup lang="ts">
import { isSupabaseConfigured } from "@/lib/supabase";
import { FrappeUIProvider } from "frappe-ui";
</script>
