<template>
  <div class="p-6">
    <h1 class="text-xl font-semibold text-ink-gray-9">Settings</h1>
    <p class="mt-1 text-p-base text-ink-gray-6">
      How your support page looks to customers
    </p>

    <div v-if="loading" class="py-16 text-center">
      <LoadingIndicator class="mx-auto h-5 w-5 text-ink-gray-5" />
    </div>

    <div v-else class="mt-6 grid gap-6 lg:grid-cols-[1fr_360px]">
      <!-- form -->
      <div class="space-y-6">
        <section class="rounded-lg border border-outline-gray-2 p-4">
          <h2 class="text-p-base font-medium text-ink-gray-8">Branding</h2>

          <div class="mt-3 space-y-3">
            <FormControl
              v-model="form.company_name"
              label="Company name"
              :disabled="saving"
            />

            <div>
              <FormControl
                v-model="form.legal_name"
                label="Legal name (for the footer)"
                placeholder="JPH Technologies Pvt Ltd"
                :disabled="saving"
              />
              <p class="mt-1 text-p-sm text-ink-gray-5">
                Shown in the copyright line. Leave blank to use the company
                name above.
              </p>
            </div>

            <div>
              <FormLabel label="Logo" />
              <div class="mt-1 flex items-center gap-3">
                <div
                  class="flex h-12 w-12 shrink-0 items-center justify-center overflow-hidden rounded-lg border border-outline-gray-2"
                  :style="{ background: form.logo_url ? '#fff' : form.accent_color }"
                >
                  <img
                    v-if="form.logo_url"
                    :src="form.logo_url"
                    alt=""
                    class="h-full w-full object-contain"
                  />
                  <span v-else class="text-lg font-semibold text-white">
                    {{ (form.company_name || "J").charAt(0).toUpperCase() }}
                  </span>
                </div>
                <div class="flex-1">
                  <input
                    ref="fileInput"
                    type="file"
                    accept="image/png,image/jpeg,image/svg+xml,image/webp"
                    class="hidden"
                    @change="uploadLogo"
                  />
                  <div class="flex gap-2">
                    <Button
                      variant="subtle"
                      :loading="uploading"
                      @click="fileInput?.click()"
                    >
                      {{ form.logo_url ? "Replace" : "Upload logo" }}
                    </Button>
                    <Button
                      v-if="form.logo_url"
                      variant="ghost"
                      @click="form.logo_url = null"
                    >
                      Remove
                    </Button>
                  </div>
                  <p class="mt-1 text-p-sm text-ink-gray-5">
                    PNG, JPG, SVG or WebP. Under 1 MB.
                  </p>
                </div>
              </div>
              <ErrorMessage :message="uploadError" class="mt-2" />
            </div>

            <div>
              <FormLabel label="Accent colour" />
              <div class="mt-1 flex items-center gap-2">
                <input
                  v-model="form.accent_color"
                  type="color"
                  class="h-8 w-12 cursor-pointer rounded border border-outline-gray-2"
                />
                <FormControl v-model="form.accent_color" class="flex-1" />
              </div>
              <p class="mt-1 text-p-sm text-ink-gray-5">
                Used for the logo badge and highlights when no logo is set.
              </p>
            </div>
          </div>
        </section>

        <section class="rounded-lg border border-outline-gray-2 p-4">
          <h2 class="text-p-base font-medium text-ink-gray-8">
            Support form wording
          </h2>
          <div class="mt-3 space-y-3">
            <FormControl v-model="form.guest_heading" label="Heading" :disabled="saving" />
            <FormControl
              v-model="form.guest_intro"
              type="textarea"
              :rows="2"
              label="Intro line"
              :disabled="saving"
            />
            <FormControl
              v-model="form.guest_submit_label"
              label="Submit button"
              :disabled="saving"
            />
          </div>
        </section>

        <section class="rounded-lg border border-outline-gray-2 p-4">
          <h2 class="text-p-base font-medium text-ink-gray-8">
            After they submit
          </h2>
          <div class="mt-3 space-y-3">
            <FormControl v-model="form.thanks_title" label="Title" :disabled="saving" />
            <FormControl
              v-model="form.thanks_message"
              type="textarea"
              :rows="2"
              label="Message"
              :disabled="saving"
            />
          </div>
        </section>

        <div class="flex items-center gap-3">
          <Button variant="solid" :loading="saving" @click="save">
            Save changes
          </Button>
          <Button variant="subtle" :disabled="saving" @click="reset">
            Discard
          </Button>
          <span v-if="savedAt" class="text-p-sm text-ink-green-3">Saved</span>
        </div>
        <ErrorMessage :message="saveError" />
      </div>

      <!-- preview -->
      <div>
        <p class="mb-2 text-p-sm font-medium text-ink-gray-6">Preview</p>
        <div class="rounded-xl border border-outline-gray-2 bg-surface-gray-1 p-4">
          <div class="mb-4 flex items-center gap-3">
            <div
              class="flex h-10 w-10 shrink-0 items-center justify-center overflow-hidden rounded-lg"
              :style="{ background: form.logo_url ? '#fff' : form.accent_color }"
            >
              <img
                v-if="form.logo_url"
                :src="form.logo_url"
                alt=""
                class="h-full w-full object-contain"
              />
              <span v-else class="text-lg font-semibold text-white">
                {{ (form.company_name || "J").charAt(0).toUpperCase() }}
              </span>
            </div>
            <div class="min-w-0">
              <p class="truncate text-p-base font-semibold text-ink-gray-9">
                {{ form.guest_heading || "—" }}
              </p>
              <p class="truncate text-p-sm text-ink-gray-6">
                {{ form.guest_intro || "—" }}
              </p>
            </div>
          </div>
          <div class="rounded-lg border border-outline-gray-2 bg-surface-base p-3">
            <div class="h-2 w-16 rounded bg-surface-gray-3"></div>
            <div class="mt-2 h-7 rounded border border-outline-gray-2"></div>
            <div class="mt-3 h-2 w-12 rounded bg-surface-gray-3"></div>
            <div class="mt-2 h-7 rounded border border-outline-gray-2"></div>
            <div
              class="mt-4 flex h-8 items-center justify-center rounded-lg text-p-sm font-medium text-white"
              :style="{ background: form.accent_color }"
            >
              {{ form.guest_submit_label || "Submit" }}
            </div>
          </div>
        </div>
        <p class="mt-2 text-p-sm text-ink-gray-5">
          Rough preview. Open the support page to see the real thing.
        </p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { supabase } from "@/lib/supabase";
import { useSettingsStore, type SiteSettings } from "@/stores/settings";
import {
  Button, ErrorMessage, FormControl, FormLabel, LoadingIndicator,
} from "frappe-ui";
import { onMounted, ref } from "vue";

const store = useSettingsStore();

const form = ref<SiteSettings>({ ...store.settings });
const loading = ref(true);
const saving = ref(false);
const uploading = ref(false);
const saveError = ref("");
const uploadError = ref("");
const savedAt = ref(false);
const fileInput = ref<HTMLInputElement | null>(null);

onMounted(async () => {
  await store.load(true);
  form.value = { ...store.settings };
  loading.value = false;
});

function reset() {
  form.value = { ...store.settings };
  saveError.value = "";
}

async function save() {
  saving.value = true;
  saveError.value = "";
  savedAt.value = false;
  try {
    await store.save({ ...form.value });
    savedAt.value = true;
    setTimeout(() => (savedAt.value = false), 2500);
  } catch (e: any) {
    saveError.value = e?.message || "Could not save";
  } finally {
    saving.value = false;
  }
}

async function uploadLogo(e: Event) {
  const file = (e.target as HTMLInputElement).files?.[0];
  if (!file) return;
  uploadError.value = "";

  // 1 MB se bada logo ki zaroorat nahi hoti, aur bada file guest form
  // ko dheema kar deta — wo page sabse zyada khulta hai.
  if (file.size > 1024 * 1024) {
    uploadError.value = "That file is over 1 MB. Please use a smaller image.";
    return;
  }

  uploading.value = true;
  try {
    // Naam me timestamp isliye ki purani file browser/CDN cache me pad
    // jaati hai — same naam rakhne par naya logo dikhta hi nahi.
    const ext = file.name.split(".").pop()?.toLowerCase() || "png";
    const path = `logo-${Date.now()}.${ext}`;

    const { error } = await supabase.storage
      .from("branding")
      .upload(path, file, { upsert: true, contentType: file.type });
    if (error) throw error;

    const { data } = supabase.storage.from("branding").getPublicUrl(path);
    form.value.logo_url = data.publicUrl;
  } catch (e: any) {
    uploadError.value = e?.message || "Could not upload the logo";
  } finally {
    uploading.value = false;
    if (fileInput.value) fileInput.value.value = "";
  }
}
</script>
