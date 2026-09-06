<template>
  <div class="flex min-h-full items-center justify-center bg-surface-gray-1 p-4">
    <div class="w-full max-w-sm">
      <div class="mb-6 text-center">
        <div
          class="mx-auto mb-3 flex h-10 w-10 items-center justify-center overflow-hidden rounded-lg text-lg font-semibold text-white"
          :style="{ background: s.logo_url ? '#fff' : s.accent_color }"
        >
          <img v-if="s.logo_url" :src="s.logo_url" alt="" class="h-full w-full object-contain" />
          <span v-else>{{ s.company_name.charAt(0).toUpperCase() }}</span>
        </div>
        <h1 class="text-lg font-semibold text-ink-gray-9">Reset your password</h1>
        <p class="mt-1 text-p-sm text-ink-gray-6">
          <template v-if="step === 'email'">We will email you a code</template>
          <template v-else-if="step === 'code'">Enter the code we emailed</template>
          <template v-else>Choose a new password</template>
        </p>
      </div>

      <div class="space-y-4 rounded-xl border border-outline-gray-2 bg-surface-base p-6 shadow-sm">
        <!-- ------------------------------------------------ 1. email -->
        <template v-if="step === 'email'">
          <FormControl
            v-model="email"
            type="email"
            label="Your email"
            placeholder="you@company.com"
            :disabled="busy"
            @keyup.enter="sendCode"
          />
          <p class="text-p-sm text-ink-gray-5">
            Use the address you sign in with. The 6-digit code arrives in a
            minute or two.
          </p>

          <div
            v-if="notFound"
            class="flex gap-2 rounded-lg border border-outline-red-2 bg-surface-red-2 p-3"
          >
            <FeatherIcon
              name="alert-circle"
              class="mt-0.5 h-4 w-4 shrink-0 text-ink-red-3"
            />
            <div class="text-p-sm">
              <p class="font-medium text-ink-red-4">
                No account uses this email
              </p>
              <p class="mt-0.5 text-ink-gray-7">
                Nothing was sent. Check the spelling, or ask an administrator
                to create an account for you.
              </p>
            </div>
          </div>

          <ErrorMessage :message="error" />

          <Button variant="solid" size="md" class="w-full" :loading="busy" @click="sendCode">
            Send code
          </Button>
        </template>

        <!-- ------------------------------------------------- 2. code -->
        <template v-else-if="step === 'code'">
          <p class="text-p-sm text-ink-gray-6">
            Code sent to <strong class="text-ink-gray-9">{{ email }}</strong>
          </p>

          <FormControl
            v-model="code"
            type="text"
            label="6-digit code"
            placeholder="123456"
            maxlength="6"
            inputmode="numeric"
            autocomplete="one-time-code"
            :disabled="busy"
            @keyup.enter="checkCode"
          />
          <p class="text-p-sm text-ink-gray-5">
            The code expires in about an hour. Check the spam folder if it has
            not arrived.
          </p>

          <ErrorMessage :message="error" />

          <Button variant="solid" size="md" class="w-full" :loading="busy" @click="checkCode">
            Continue
          </Button>

          <div class="flex items-center justify-between text-p-sm">
            <button class="text-ink-gray-6 underline" :disabled="busy" @click="backToEmail">
              Wrong email?
            </button>
            <button
              class="text-ink-gray-6 underline disabled:no-underline disabled:opacity-60"
              :disabled="busy || cooldown > 0"
              @click="sendCode"
            >
              {{ cooldown > 0 ? `Resend in ${cooldown}s` : "Resend code" }}
            </button>
          </div>
        </template>

        <!-- --------------------------------------------- 3. password -->
        <template v-else>
          <FormControl
            v-model="password"
            type="password"
            label="New password"
            :disabled="busy"
          />
          <FormControl
            v-model="confirm"
            type="password"
            label="Repeat new password"
            :disabled="busy"
            @keyup.enter="savePassword"
          />
          <p class="text-p-sm text-ink-gray-5">
            At least 8 characters. Other devices keep working until they sign
            out.
          </p>

          <ErrorMessage :message="error" />

          <Button variant="solid" size="md" class="w-full" :loading="busy" @click="savePassword">
            Save password
          </Button>

          <button class="w-full text-p-sm text-ink-gray-6 underline" :disabled="busy" @click="startOver">
            Start over
          </button>
        </template>
      </div>

      <p class="mt-4 text-center text-p-sm text-ink-gray-5">
        <RouterLink to="/login" class="underline">Back to login</RouterLink>
      </p>

      <SiteFooter />
    </div>
  </div>
</template>

<script setup lang="ts">
/**
 * Password bhool jaane par khud se badalne ka raasta.
 *
 * KYUN ZAROORAT PADI
 *
 * MyProfile me password badalne ka option pehle se hai, par wo tabhi
 * khulta hai jab aap ANDAR ho. Password bhool jaane par andar jaane ka
 * koi zariya hi nahi bachta tha — admin ko database se haath lagana
 * padta tha. Ye page wahi khaali jagah bharta hai.
 *
 * YE KAAM KAISE KARTA HAI
 *
 * Poora kaam Supabase Auth khud karta hai. Hum na koi OTP table banate
 * hain, na apna code generate karte hain, na service_role kahin laate
 * hain:
 *
 *   1. resetPasswordForEmail()  -> Supabase us pate par code bhejta hai
 *   2. verifyOtp(type recovery) -> code sahi hua to session mil jaata hai
 *   3. updateUser({ password }) -> usi session se naya password lag jaata hai
 *
 * Apna OTP likhne ka matlab hota: token ka table, expiry, ginti ki rok,
 * aur password badalne ke liye service_role — jo is folder me kabhi nahi
 * aani chahiye. Supabase ke paas ye sab pehle se hai.
 *
 * EMAIL TEMPLATE (ek baar ka setup)
 *
 * Supabase -> Authentication -> Emails -> "Reset Password" template me
 * {{ .Token }} hona chahiye, warna email me sirf link jaata hai aur code
 * kabhi nahi dikhta.
 *
 * Link wala raasta bhi chalta rehta hai: neeche onMounted us link ko bhi
 * pakadta hai aur seedha teesre step par le jaata hai. Isliye template
 * badalne se pehle bhi ye page bekaar nahi hai.
 *
 * GALAT EMAIL PAR SAAF MANA
 *
 * Code bhejne se pehle account_exists() se poochha jaata hai ki is pate
 * ka account hai bhi ya nahi (25_account_exists.sql). Nahi hai to code
 * bhejte hi nahi aur seedha bata dete hain.
 *
 * Supabase khud ye farq jaan-boojh kar nahi batata — usse koi ajnabi
 * ek-ek pata daal kar ye ginn sakta hai ki yahan kaun-kaun hai. Yahan wo
 * chhoot maang kar li gayi hai, aur andar ke helpdesk par wajib hai:
 * account admin banata hai, sign-up khula nahi hai. Wajah aur usse jo
 * milta-nahi-milta, dono 25_account_exists.sql ke sar par likhe hain.
 */
import SiteFooter from "@/components/SiteFooter.vue";
import { supabase } from "@/lib/supabase";
import { useAuthStore } from "@/stores/auth";
import { useSettingsStore } from "@/stores/settings";
import { Button, ErrorMessage, FeatherIcon, FormControl } from "frappe-ui";
import { computed, onMounted, onUnmounted, ref } from "vue";
import { useRoute, useRouter } from "vue-router";

const router = useRouter();
const route = useRoute();
const auth = useAuthStore();
const settingsStore = useSettingsStore();
const s = computed(() => settingsStore.settings);

const step = ref<"email" | "code" | "password">("email");
const email = ref("");
const code = ref("");
const password = ref("");
const confirm = ref("");
const busy = ref(false);
const error = ref("");
// Jis pate par "account nahi hai" nikla tha. Ise yaad rakhna zaroori hai:
// laal dabba tabhi tak dikhna chahiye jab tak WAHI pata likha ho. User ne
// spelling theek ki nahi ki wo apne aap hat jaata hai.
const notFoundEmail = ref("");
const notFound = computed(
  () =>
    notFoundEmail.value !== "" &&
    email.value.trim().toLowerCase() === notFoundEmail.value
);

// Resend par thodi rok. Supabase ki apni rate limit is se kahin sakht hai
// (custom SMTP ke bina ghante me 2 email); baar-baar dabane par user wo
// limit khatm kar deta hai aur phir asli code bhi nahi aata.
const cooldown = ref(0);
let timer: ReturnType<typeof setInterval> | null = null;

function startCooldown() {
  cooldown.value = 60;
  if (timer) clearInterval(timer);
  timer = setInterval(() => {
    cooldown.value -= 1;
    if (cooldown.value <= 0 && timer) {
      clearInterval(timer);
      timer = null;
    }
  }, 1000);
}

onUnmounted(() => {
  if (timer) clearInterval(timer);
});

onMounted(() => {
  settingsStore.load();

  // Login page se aaye to wahan likha hua email saath le aate hain.
  const fromLogin = route.query.email;
  if (typeof fromLogin === "string") email.value = fromLogin;

  // Agar user ne email ka LINK dabaya hai (code ke bajaye), to Supabase
  // usse yahan wapas bhejta hai — token URL me. Us soorat me pehle do
  // step ho hi chuke hain, seedha naya password maangna hai.
  void handleRecoveryLink();
});

async function handleRecoveryLink() {
  const query = new URLSearchParams(window.location.search);
  // Implicit flow me token hash me aate hain, query me nahi.
  const hash = new URLSearchParams(window.location.hash.replace(/^#/, ""));

  const failed =
    hash.get("error_description") ||
    query.get("error_description") ||
    hash.get("error") ||
    query.get("error");

  if (failed) {
    // Supabase apne message me spaces ki jagah + bhejta hai.
    error.value = failed.replace(/\+/g, " ");
    clearUrl();
    return;
  }

  const authCode = query.get("code");
  const accessToken = hash.get("access_token");
  const refreshToken = hash.get("refresh_token");

  if (!authCode && !(accessToken && refreshToken)) return;

  busy.value = true;
  try {
    if (authCode) {
      const { error: e } = await supabase.auth.exchangeCodeForSession(authCode);
      if (e) throw e;
    } else if (accessToken && refreshToken) {
      const { error: e } = await supabase.auth.setSession({
        access_token: accessToken,
        refresh_token: refreshToken,
      });
      if (e) throw e;
    }
    const { data } = await supabase.auth.getSession();
    if (!data.session) throw new Error("This link has expired.");
    email.value = data.session.user.email ?? email.value;
    step.value = "password";
  } catch (e: any) {
    error.value =
      e?.message || "This link has already been used, or it expired.";
  } finally {
    // Token URL me pade rehna theek nahi — history me reh jaate hain aur
    // back button se dobara chal jaate hain.
    clearUrl();
    busy.value = false;
  }
}

function clearUrl() {
  window.history.replaceState({}, "", window.location.pathname);
}

async function sendCode() {
  const to = email.value.trim().toLowerCase();
  if (!to) {
    error.value = "Please enter your email";
    return;
  }

  busy.value = true;
  error.value = "";
  notFoundEmail.value = "";
  try {
    // Pehle poochho, phir bhejo.
    //
    // Lookup KHUD fail ho jaaye (25 wali script na chali ho, ya network
    // beech me tootey) to raasta rokte nahi — code bhej dete hain. Ek
    // chhoti si check ke fail hone par poora password reset band kar
    // dena us bande ko bahar khada chhod dega jiska account sach me
    // hai. Us soorat me sirf "account nahi hai" wala message nahi aata.
    const { data: exists, error: lookupFailed } = await supabase.rpc(
      "account_exists",
      { p_email: to }
    );
    if (!lookupFailed && exists === false) {
      email.value = to;
      notFoundEmail.value = to;
      return;
    }

    const { error: e } = await supabase.auth.resetPasswordForEmail(to, {
      // Sirf un logon ke liye jo code ke bajaye link dabate hain. Wo link
      // isi page par girta hai aur upar wala handleRecoveryLink() use
      // seedha teesre step par le jaata hai.
      redirectTo: `${window.location.origin}/forgot-password`,
    });
    if (e) throw e;

    email.value = to;
    code.value = "";
    step.value = "code";
    startCooldown();
  } catch (e: any) {
    error.value = e?.message || "Could not send the code. Please try again.";
  } finally {
    busy.value = false;
  }
}

async function checkCode() {
  const token = code.value.replace(/\s/g, "");
  if (token.length < 6) {
    error.value = "Please enter the 6-digit code";
    return;
  }

  busy.value = true;
  error.value = "";
  try {
    const { error: e } = await supabase.auth.verifyOtp({
      email: email.value,
      token,
      type: "recovery",
    });
    if (e) throw e;

    step.value = "password";
  } catch {
    // Supabase ka apna message ("Token has expired or is invalid") do
    // alag wajahon ko ek hi shakl me kehta hai. Saaf-saaf dono keh dete
    // hain, taaki user ko pata ho ki dobara bhejna kab kaam aayega.
    error.value = "That code is not right, or it has expired. Try resending it.";
  } finally {
    busy.value = false;
  }
}

async function savePassword() {
  if (password.value.length < 8) {
    error.value = "The new password must be at least 8 characters";
    return;
  }
  if (password.value !== confirm.value) {
    error.value = "The two passwords do not match";
    return;
  }

  busy.value = true;
  error.value = "";
  try {
    const { error: e } = await supabase.auth.updateUser({
      password: password.value,
    });
    if (e) throw e;

    // Code sahi hone par session pehle hi mil chuka hai, isliye ab user
    // andar ja sakta hai. Par wahi shart lagegi jo Login.vue par lagti
    // hai — customer ke liye agent desk nahi hai.
    await auth.init();
    if (auth.isStaff) {
      router.replace("/admin");
      return;
    }

    await auth.signOut();
    router.replace({ name: "Login", query: { reset: "1" } });
  } catch (e: any) {
    error.value = e?.message || "Could not save the new password";
  } finally {
    busy.value = false;
  }
}

function backToEmail() {
  code.value = "";
  error.value = "";
  notFoundEmail.value = "";
  step.value = "email";
}

async function startOver() {
  // Teesre step par pahunchte hi session ban chuka hota hai. Beech me
  // chhod dene par wo session khula reh jaata — is screen ko chhodne se
  // pehle use band karna zaroori hai.
  await auth.signOut();
  password.value = "";
  confirm.value = "";
  backToEmail();
}
</script>
