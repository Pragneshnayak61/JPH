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
              <FormControl
                v-model="form.contact_email"
                type="email"
                label="Contact email (for the footer)"
                placeholder="support@jph.com"
                :disabled="saving"
              />
              <p class="mt-1 text-p-sm text-ink-gray-5">
                Shown under the copyright line. Leave blank to hide it.
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

        <section class="rounded-lg border border-outline-gray-2 p-4">
          <h2 class="text-p-base font-medium text-ink-gray-8">
            Ticket categories
          </h2>
          <p class="mt-0.5 text-p-sm text-ink-gray-6">
            Shown as a dropdown on the support form
          </p>

          <div class="mt-3 space-y-2">
            <div
              v-for="c in categories"
              :key="c.id"
              class="flex items-center gap-2"
            >
              <FormControl
                class="flex-1"
                :model-value="c.name"
                :disabled="savingCat === c.id"
                @change="(e: any) => renameCategory(c, e.target.value)"
              />
              <button
                class="text-p-sm text-ink-gray-6 underline hover:text-ink-gray-8"
                :disabled="savingCat === c.id"
                @click="toggleCategory(c)"
              >
                {{ c.is_active ? "Hide" : "Show" }}
              </button>
              <button
                class="text-p-sm text-ink-red-3 underline hover:text-ink-red-4"
                :disabled="savingCat === c.id"
                @click="askDeleteCategory(c)"
              >
                Delete
              </button>
            </div>
          </div>

          <div class="mt-3 flex gap-2">
            <FormControl
              v-model="newCategory"
              class="flex-1"
              placeholder="New category"
              @keyup.enter="addCategory"
            />
            <Button :disabled="!newCategory.trim()" @click="addCategory">
              Add
            </Button>
          </div>
          <p class="mt-2 text-p-sm text-ink-gray-5">
            Hiding a category keeps it on old tickets but removes it from the
            form. Deleting removes it everywhere.
          </p>
          <ErrorMessage :message="catError" class="mt-2" />
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
          <!-- header -->
          <div class="mb-4 flex items-start gap-3">
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
              <p class="text-p-base font-semibold text-ink-gray-9">
                {{ form.guest_heading || "—" }}
              </p>
              <!-- truncate NAHI: intro poora vakya hota hai, kat jaata to
                   preview ka matlab hi na rehta. -->
              <p class="text-p-sm leading-snug text-ink-gray-6">
                {{ form.guest_intro || "—" }}
              </p>
            </div>
          </div>

          <!-- form: asli labels, khali grey bars nahi -->
          <div class="rounded-lg border border-outline-gray-2 bg-surface-base p-3">
            <div v-for="f in previewFields" :key="f" class="mb-2.5">
              <p class="mb-1 text-p-sm text-ink-gray-6">{{ f }}</p>
              <div class="h-6 rounded border border-outline-gray-2 bg-surface-gray-1"></div>
            </div>
            <div class="mb-2.5">
              <p class="mb-1 text-p-sm text-ink-gray-6">Describe the problem</p>
              <div class="h-12 rounded border border-outline-gray-2 bg-surface-gray-1"></div>
            </div>
            <div
              class="flex h-8 items-center justify-center rounded-lg text-p-sm font-medium text-white"
              :style="{ background: form.accent_color }"
            >
              {{ form.guest_submit_label || "Submit" }}
            </div>
          </div>

          <!-- footer bhi, kyunki legal name aur email yahin set hote hain -->
          <div class="mt-4 border-t border-outline-gray-2 pt-3 text-center">
            <p class="text-p-sm text-ink-gray-5">
              &copy; {{ form.legal_name?.trim() || form.company_name || "—" }}.
              All rights reserved.
            </p>
            <p v-if="form.contact_email?.trim()" class="text-p-sm text-ink-gray-5">
              {{ form.contact_email }}
            </p>
          </div>
        </div>

        <!-- thank-you page ka apna preview: wo alag screen hai, form ke
             saath dikhane se dono ka matlab confuse hota. -->
        <div
          class="mt-3 rounded-xl border border-outline-gray-2 bg-surface-gray-1 p-4 text-center"
        >
          <p class="text-p-sm font-medium text-ink-gray-8">
            {{ form.thanks_title || "—" }}
          </p>
          <p class="mt-1 text-p-sm leading-snug text-ink-gray-6">
            {{ form.thanks_message || "—" }}
          </p>
        </div>

        <p class="mt-2 text-p-sm text-ink-gray-5">
          Colours and wording only. Open the support page to see the real
          layout.
        </p>
      </div>
    </div>

    <!-- Delete category confirm -->
    <Dialog
      v-model="showCatDelete"
      :options="{ title: 'Delete this category?', size: 'sm' }"
    >
      <template #body-content>
        <p class="text-p-base text-ink-gray-7">
          <strong>{{ catToDelete?.name }}</strong> will be removed from the
          support form.
        </p>

        <div v-if="countingCat" class="mt-3 flex items-center gap-2">
          <LoadingIndicator class="h-4 w-4 text-ink-gray-5" />
          <span class="text-p-sm text-ink-gray-6">Checking tickets&hellip;</span>
        </div>

        <!-- Ginti pehle dikhani zaroori hai. "5 tickets isse judi hain"
             padhkar aadmi ruk jaata hai; bina ginti ke wahi click aankh
             band karke ho jaata hai. -->
        <p
          v-else-if="catUsage > 0"
          class="mt-3 rounded-md bg-surface-amber-1 px-3 py-2 text-p-sm text-ink-gray-7"
        >
          <strong>{{ catUsage }}</strong>
          {{ catUsage === 1 ? "ticket uses" : "tickets use" }} this category.
          Those tickets stay, but their category becomes empty and cannot be
          brought back. To keep it on them, use <strong>Hide</strong> instead.
        </p>
        <p v-else class="mt-3 text-p-sm text-ink-gray-5">
          No ticket uses this category, so nothing else changes.
        </p>

        <ErrorMessage :message="catDeleteError" class="mt-3" />
      </template>
      <template #actions>
        <div class="flex gap-2">
          <Button class="flex-1" @click="showCatDelete = false">Cancel</Button>
          <Button
            v-if="catUsage > 0"
            class="flex-1"
            :loading="deletingCat"
            @click="hideInstead"
          >
            Hide
          </Button>
          <Button
            class="flex-1"
            theme="red"
            variant="solid"
            :loading="deletingCat"
            :disabled="countingCat"
            @click="doDeleteCategory"
          >
            Delete
          </Button>
        </div>
      </template>
    </Dialog>
  </div>
</template>

<script setup lang="ts">
import { supabase } from "@/lib/supabase";
import { useSettingsStore, type SiteSettings } from "@/stores/settings";
import {
  Button, Dialog, ErrorMessage, FormControl, FormLabel, LoadingIndicator,
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

// Asli form ke fields, usi kram me. Hardcoded hai — preview me asli
// dropdown/editor chalane ka koi faayda nahi, sirf shakl dikhani hai.
const previewFields = [
  "Your name", "Email", "Company name", "Category", "Subject", "Priority",
];

// ---------------------------------------------------------------- categories
type Category = { id: string; name: string; is_active: boolean; sort_order: number };
const categories = ref<Category[]>([]);
const newCategory = ref("");
const catError = ref("");
const savingCat = ref<string | null>(null);

async function loadCategories() {
  const { data } = await supabase
    .from("ticket_categories")
    .select("id, name, is_active, sort_order")
    .order("sort_order");
  categories.value = data ?? [];
}

async function addCategory() {
  const name = newCategory.value.trim();
  if (!name) return;
  catError.value = "";
  // Sabse bade sort_order se aage. Naya item hamesha neeche jaana chahiye,
  // warna list ka kram har baar badalta rehta.
  const next = Math.max(0, ...categories.value.map((c) => c.sort_order)) + 10;
  const { error } = await supabase
    .from("ticket_categories")
    .insert({ name, sort_order: next });
  if (error) {
    catError.value = error.message;
    return;
  }
  newCategory.value = "";
  await loadCategories();
}

async function renameCategory(c: Category, name: string) {
  const next = name.trim();
  if (!next || next === c.name) return;
  savingCat.value = c.id;
  catError.value = "";
  const { error } = await supabase
    .from("ticket_categories")
    .update({ name: next })
    .eq("id", c.id);
  savingCat.value = null;
  if (error) catError.value = error.message;
  await loadCategories();
}

async function toggleCategory(c: Category) {
  savingCat.value = c.id;
  // Hide = form se hat jaati hai, par purane tickets par bani rehti hai.
  // Isiliye ye delete se pehle wala, surakshit raasta hai.
  const { error } = await supabase
    .from("ticket_categories")
    .update({ is_active: !c.is_active })
    .eq("id", c.id);
  savingCat.value = null;
  if (error) catError.value = error.message;
  await loadCategories();
}

// -------------------------------------------------------- delete category
//
// tickets.category_id par FK "on delete set null" hai — category mitte hi
// un tickets ka category khaali ho jaata hai, aur wapas nahi aata. Isliye
// pehle ginti dikhate hain aur saath me Hide ka rasta bhi dete hain.
const showCatDelete = ref(false);
const catToDelete = ref<Category | null>(null);
const catUsage = ref(0);
const countingCat = ref(false);
const deletingCat = ref(false);
const catDeleteError = ref("");

async function askDeleteCategory(c: Category) {
  catToDelete.value = c;
  catDeleteError.value = "";
  catUsage.value = 0;
  showCatDelete.value = true;

  // head: true — sirf ginti chahiye, rows nahi. Poore tickets kheenchna
  // bekaar hai jab dikhana sirf ek number hai.
  countingCat.value = true;
  const { count, error } = await supabase
    .from("tickets")
    .select("id", { count: "exact", head: true })
    .eq("category_id", c.id);
  countingCat.value = false;

  if (error) {
    // Ginti na mile to delete rokte nahi, par aadmi ko bata dete hain ki
    // wo bina ginti dekhe faisla kar raha hai.
    catDeleteError.value = "Could not check how many tickets use this: " + error.message;
    return;
  }
  catUsage.value = count ?? 0;
}

async function hideInstead() {
  const c = catToDelete.value;
  if (!c) return;
  deletingCat.value = true;
  catDeleteError.value = "";
  const { error } = await supabase
    .from("ticket_categories")
    .update({ is_active: false })
    .eq("id", c.id);
  deletingCat.value = false;
  if (error) {
    catDeleteError.value = error.message;
    return;
  }
  showCatDelete.value = false;
  await loadCategories();
}

async function doDeleteCategory() {
  const c = catToDelete.value;
  if (!c) return;
  deletingCat.value = true;
  catDeleteError.value = "";
  const { error } = await supabase
    .from("ticket_categories")
    .delete()
    .eq("id", c.id);
  deletingCat.value = false;
  if (error) {
    catDeleteError.value = error.message;
    return;
  }
  showCatDelete.value = false;
  await loadCategories();
}

onMounted(async () => {
  await Promise.all([store.load(true), loadCategories()]);
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
