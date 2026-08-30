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
        <p class="mt-1 text-p-sm text-ink-gray-6">Agent aur admin ke liye</p>
      </div>

      <div
        class="space-y-4 rounded-xl border border-outline-gray-2 bg-surface-base p-6 shadow-sm"
      >
        <FormControl
          v-model="email"
          type="email"
          label="Email"
          placeholder="aap@company.com"
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
        Ticket bhejna hai?
        <RouterLink to="/" class="underline">Yahan jaaiye</RouterLink>
        &mdash; login ki zaroorat nahi
      </p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { supabase } from "@/lib/supabase";
import { Button, ErrorMessage, FormControl } from "frappe-ui";
import { ref } from "vue";
import { useRouter } from "vue-router";

const router = useRouter();
const email = ref("");
const password = ref("");
const loading = ref(false);
const error = ref("");

async function signIn() {
  if (!email.value || !password.value) {
    error.value = "Email aur password dono daaliye";
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
    router.push("/admin");
  } catch (e: any) {
    error.value = e?.message || "Login nahi ho paya";
  } finally {
    loading.value = false;
  }
}
</script>
