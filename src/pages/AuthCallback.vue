<template>
  <div class="flex min-h-full items-center justify-center bg-surface-gray-1 p-4">
    <div class="w-full max-w-sm">
      <div
        class="rounded-xl border border-outline-gray-2 bg-surface-base p-6 text-center shadow-sm"
      >
        <template v-if="state === 'working'">
          <LoadingIndicator class="mx-auto h-5 w-5 text-ink-gray-5" />
          <p class="mt-3 text-p-base text-ink-gray-6">Confirming&hellip;</p>
        </template>

        <template v-else-if="state === 'done'">
          <div
            class="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-surface-green-2"
          >
            <FeatherIcon name="check" class="h-6 w-6 text-ink-green-3" />
          </div>
          <h1 class="text-lg font-semibold text-ink-gray-9">Email confirmed</h1>
          <p class="mt-2 text-p-base text-ink-gray-6">
            You now sign in with
            <strong class="text-ink-gray-9">{{ email }}</strong
            >.
          </p>
          <p class="mt-2 text-p-sm text-ink-gray-5">
            Your old address will not work any more. Your tickets moved with
            you.
          </p>
          <Button variant="solid" class="mt-5 w-full" @click="goOn">
            Continue
          </Button>
        </template>

        <template v-else>
          <div
            class="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-surface-red-2"
          >
            <FeatherIcon name="alert-circle" class="h-6 w-6 text-ink-red-3" />
          </div>
          <h1 class="text-lg font-semibold text-ink-gray-9">
            This link did not work
          </h1>
          <p class="mt-2 text-p-base text-ink-gray-6">{{ message }}</p>
          <p class="mt-2 text-p-sm text-ink-gray-5">
            Sign in with your current email and start the change again from My
            profile.
          </p>
          <Button variant="solid" class="mt-5 w-full" @click="goOn">
            Go to login
          </Button>
        </template>
      </div>

      <SiteFooter />
    </div>
  </div>
</template>

<script setup lang="ts">
/**
 * Supabase ke confirmation link yahan aakar khatam hote hain.
 *
 * Link pehle Supabase ke /auth/v1/verify par jaata hai; wo token check
 * karke yahan bhej deta hai. Bina is page ke wo redirect Supabase ki
 * "Site URL" par girta hai — jo default me localhost hoti hai, aur user
 * ko ek khaali safed page milta hai. Bahar se lagta hai link toota hua
 * hai, jabki email badal chuka hota hai.
 */
import SiteFooter from "@/components/SiteFooter.vue";
import { supabase } from "@/lib/supabase";
import { useAuthStore } from "@/stores/auth";
import { Button, FeatherIcon, LoadingIndicator } from "frappe-ui";
import { onMounted, ref } from "vue";
import { useRouter } from "vue-router";

const router = useRouter();
const auth = useAuthStore();

const state = ref<"working" | "done" | "failed">("working");
const message = ref("");
const email = ref("");

function goOn() {
  router.replace(state.value === "done" && auth.isStaff ? "/admin" : "/login");
}

onMounted(async () => {
  const query = new URLSearchParams(window.location.search);
  // Implicit flow me token URL ke hash me aate hain, query me nahi.
  const hash = new URLSearchParams(window.location.hash.replace(/^#/, ""));

  const failed =
    hash.get("error_description") ||
    query.get("error_description") ||
    hash.get("error") ||
    query.get("error");

  if (failed) {
    state.value = "failed";
    // Supabase apne message me + bhejta hai spaces ki jagah.
    message.value = failed.replace(/\+/g, " ");
    return;
  }

  try {
    // Supabase do flow me se koi bhi bhej sakta hai, aur ye project ke
    // settings par depend karta hai. Dono ko sambhal lete hain — ek na
    // chale to doosra chal jaata hai.
    const code = query.get("code");
    const accessToken = hash.get("access_token");
    const refreshToken = hash.get("refresh_token");

    if (code) {
      const { error } = await supabase.auth.exchangeCodeForSession(code);
      if (error) throw error;
    } else if (accessToken && refreshToken) {
      const { error } = await supabase.auth.setSession({
        access_token: accessToken,
        refresh_token: refreshToken,
      });
      if (error) throw error;
    }

    // Token URL me pade rehna theek nahi — history me reh jaate hain aur
    // back button se dobara chal jaate hain.
    window.history.replaceState({}, "", window.location.pathname);

    // init() session padhta hai AUR profiles.email ko login email se
    // mila deta hai. Yahi wo jagah hai jahan purana farq paida hota tha.
    await auth.init();

    const { data } = await supabase.auth.getSession();
    if (!data.session) {
      state.value = "failed";
      message.value =
        "The link has already been used, or it expired. Links stay valid for a short time only.";
      return;
    }

    email.value = data.session.user.email ?? "";
    state.value = "done";
  } catch (e: any) {
    state.value = "failed";
    message.value = e?.message || "Could not confirm this link.";
  }
});
</script>
