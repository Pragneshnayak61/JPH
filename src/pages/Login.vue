<template>
  <div class="flex min-h-full items-center justify-center bg-surface-gray-1 p-4">
    <div class="w-full max-w-sm">
      <div class="mb-6 text-center">
        <div
          class="mx-auto mb-3 flex h-10 w-10 items-center justify-center rounded-lg bg-surface-gray-7 text-lg font-semibold text-white"
        >
          J
        </div>
        <h1 class="text-lg font-semibold text-ink-gray-9">JPH Helpdesk</h1>
        <p class="mt-1 text-p-sm text-ink-gray-6">For agents and admins</p>
      </div>

      <div
        class="space-y-4 rounded-xl border border-outline-gray-2 bg-surface-base p-6 shadow-sm"
      >
        <FormControl
          v-model="email"
          type="email"
          label="Email"
          placeholder="you@company.com"
          :disabled="loading"
          @keyup.enter="signIn"
        />
        <FormControl
          v-model="password"
          type="password"
          label="Password"
          :disabled="loading"
          @keyup.enter="signIn"
        />

        <ErrorMessage :message="error" />

        <Button
          variant="solid"
          size="md"
          class="w-full"
          :loading="loading"
          @click="signIn"
        >
          Login
        </Button>
      </div>

      <p class="mt-4 text-center text-p-sm text-ink-gray-5">
        Need to raise a ticket?
        <RouterLink to="/" class="underline">Go here</RouterLink>
        &mdash; no sign-in required
      </p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { supabase } from "@/lib/supabase";
import { Button, ErrorMessage, FormControl } from "frappe-ui";
import { useAuthStore } from "@/stores/auth";
import { ref } from "vue";
import { useRoute, useRouter } from "vue-router";

const router = useRouter();
const route = useRoute();
const auth = useAuthStore();
const email = ref("");
const password = ref("");
const loading = ref(false);
const error = ref("");

async function signIn() {
  if (!email.value || !password.value) {
    error.value = "Please enter both email and password";
    return;
  }
  loading.value = true;
  error.value = "";
  try {
    const { error: err } = await supabase.auth.signInWithPassword({
      email: email.value.trim().toLowerCase(),
      password: password.value,
    });
    if (err) throw err;

    // Store refresh karna zaroori hai — warna guard purana (logged-out)
    // state dekhega aur wapas login par bhej dega.
    await auth.init();

    // Yahan saaf batana ZAROORI hai. Pehle ye check nahi tha: login ho
    // jaata tha, guard /admin par `isStaff` false dekhta tha aur chup-chaap
    // guest page par bhej deta tha — user ko lagta tha login hi fail hua.
    if (!auth.profile) {
      error.value =
        "Signed in, but your profile could not be loaded. Please contact the administrator.";
      await auth.signOut();
      return;
    }
    if (!auth.isStaff) {
      error.value =
        "This account is not an agent or admin. Ask an administrator to give you access.";
      await auth.signOut();
      return;
    }

    // Guard ne jis page se bheja tha, wahin wapas le jao.
    const next = typeof route.query.next === "string" ? route.query.next : "/admin";
    router.replace(next);
  } catch (e: any) {
    error.value = e?.message || "Could not sign in";
  } finally {
    loading.value = false;
  }
}
</script>
