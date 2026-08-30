<template>
  <div class="p-6">
    <div class="flex items-start justify-between">
      <div>
        <h1 class="text-xl font-semibold text-ink-gray-9">People</h1>
        <p class="mt-1 text-p-base text-ink-gray-6">
          Decide who can work on tickets and what they are allowed to do
        </p>
      </div>
      <div class="flex gap-2">
        <Button variant="subtle" @click="showHelp = !showHelp">Help</Button>
        <Button v-if="auth.isAdmin" variant="solid" @click="openAdd">
          Add person
        </Button>
      </div>
    </div>

    <div
      v-if="showHelp"
      class="mt-4 rounded-lg border border-outline-blue-2 bg-surface-blue-1 p-4 text-p-base text-ink-gray-8"
    >
      <p class="font-medium">Adding a new person takes two steps</p>
      <ol class="mt-2 list-decimal space-y-1 pl-5 text-ink-gray-7">
        <li>
          They create an account themselves at
          <code class="rounded bg-surface-gray-2 px-1 font-mono">/login</code>,
          or you add them in the Supabase dashboard
          (Authentication &rarr; Users &rarr; Add user).
        </li>
        <li>
          They then appear in the list below as
          <Badge theme="gray" variant="subtle">customer</Badge>. Change their
          access to <strong>Agent</strong> and pick a role.
        </li>
      </ol>
      <p class="mt-3 text-p-sm text-ink-gray-6">
        Or use <strong>Add person</strong> above to create the account for
        them. You set a temporary password and share it with them &mdash;
        there is no email set up yet, so nothing is sent automatically.
      </p>
    </div>

    <!-- people -->
    <div class="mt-5 overflow-hidden rounded-lg border border-outline-gray-2">
      <div
        class="grid grid-cols-12 gap-3 border-b border-outline-gray-2 bg-surface-gray-1 px-4 py-2 text-p-sm font-medium text-ink-gray-6"
      >
        <div class="col-span-4">Person</div>
        <div class="col-span-3">Access</div>
        <div class="col-span-3">Role</div>
        <div class="col-span-2">Status</div>
      </div>

      <div v-if="loading" class="px-4 py-10 text-center">
        <LoadingIndicator class="mx-auto h-5 w-5 text-ink-gray-5" />
      </div>

      <div v-else-if="loadError" class="px-4 py-10 text-center">
        <p class="text-p-base text-ink-red-3">{{ loadError }}</p>
      </div>

      <div
        v-for="p in people"
        v-else
        :key="p.id"
        class="grid grid-cols-12 items-center gap-3 border-b border-outline-gray-2 px-4 py-2.5 last:border-0"
      >
        <div class="col-span-4 flex min-w-0 items-center gap-2">
          <Avatar :label="p.full_name || p.email" size="sm" />
          <div class="min-w-0">
            <p class="truncate text-p-base text-ink-gray-8">
              {{ p.full_name || "—" }}
            </p>
            <p class="truncate text-p-sm text-ink-gray-5">{{ p.email }}</p>
          </div>
        </div>

        <div class="col-span-3">
          <FormControl
            type="select"
            :model-value="p.kind"
            :options="kindOptions"
            :disabled="p.id === auth.profile?.id || saving === p.id"
            @update:model-value="(v: string) => setKind(p, v)"
          />
        </div>

        <div class="col-span-3">
          <FormControl
            type="select"
            :model-value="p.role_id ?? ''"
            :options="roleOptions"
            :disabled="p.kind === 'customer' || saving === p.id"
            @update:model-value="(v: string) => setRole(p, v)"
          />
        </div>

        <div class="col-span-2 flex items-center gap-2">
          <Badge :theme="p.is_active ? 'green' : 'gray'" variant="subtle">
            {{ p.is_active ? "Active" : "Disabled" }}
          </Badge>
          <button
            v-if="p.id !== auth.profile?.id"
            class="text-p-sm text-ink-gray-6 underline hover:text-ink-gray-8"
            :disabled="saving === p.id"
            @click="toggleActive(p)"
          >
            {{ p.is_active ? "Disable" : "Enable" }}
          </button>
        </div>
      </div>
    </div>

    <div
      v-if="lastCreated"
      class="mt-3 rounded-lg border border-outline-green-2 bg-surface-green-1 p-3 text-p-base text-ink-gray-8"
    >
      {{ lastCreated }}
    </div>

    <ErrorMessage :message="saveError" class="mt-3" />

    <p class="mt-2 text-p-sm text-ink-gray-5">
      You cannot change your own access or disable yourself &mdash; that would
      lock you out.
    </p>

    <!-- roles -->
    <h2 class="mt-8 text-lg font-semibold text-ink-gray-9">Roles</h2>
    <p class="mt-1 text-p-base text-ink-gray-6">
      A role is a set of permissions. Change a role here and every agent with
      that role is affected.
    </p>

    <div class="mt-4 overflow-x-auto rounded-lg border border-outline-gray-2">
      <table class="w-full text-p-base">
        <thead class="bg-surface-gray-1 text-p-sm text-ink-gray-6">
          <tr>
            <th class="px-4 py-2 text-left font-medium">Role</th>
            <th
              v-for="perm in PERMISSIONS"
              :key="perm.key"
              class="px-3 py-2 text-center font-medium"
            >
              {{ perm.label }}
            </th>
          </tr>
        </thead>
        <tbody>
          <tr
            v-for="r in roles"
            :key="r.id"
            class="border-t border-outline-gray-2"
          >
            <td class="px-4 py-2.5">
              <p class="text-ink-gray-8">{{ r.name }}</p>
              <p class="text-p-sm text-ink-gray-5">{{ r.description }}</p>
            </td>
            <td
              v-for="perm in PERMISSIONS"
              :key="perm.key"
              class="px-3 py-2.5 text-center"
            >
              <input
                type="checkbox"
                class="rounded"
                :checked="Boolean((r as any)[perm.key])"
                :disabled="r.name === 'Administrator' || savingRole === r.id"
                @change="togglePerm(r, perm.key, ($event.target as HTMLInputElement).checked)"
              />
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <p class="mt-2 text-p-sm text-ink-gray-5">
      The Administrator role cannot be changed &mdash; it always has every
      permission, so there is always someone who can fix things.
    </p>

    <ErrorMessage :message="roleError" class="mt-3" />

    <!-- Add person -->
    <Dialog
      v-model="showAdd"
      :options="{ title: 'Add person', size: 'md' }"
    >
      <template #body-content>
        <div class="space-y-3">
          <FormControl
            v-model="form.full_name"
            label="Full name"
            placeholder="Priya Sharma"
            :disabled="creating"
          />
          <FormControl
            v-model="form.email"
            type="email"
            label="Email"
            placeholder="priya@company.com"
            :disabled="creating"
          />
          <div>
            <FormControl
              v-model="form.password"
              label="Temporary password"
              :disabled="creating"
            />
            <div class="mt-1 flex items-center justify-between">
              <p class="text-p-sm text-ink-gray-5">At least 8 characters</p>
              <button
                class="text-p-sm text-ink-gray-6 underline"
                @click="form.password = randomPassword()"
              >
                Generate
              </button>
            </div>
          </div>
          <FormControl
            v-model="form.kind"
            type="select"
            label="Access"
            :options="kindOptions"
            :disabled="creating"
          />
          <FormControl
            v-if="form.kind !== 'customer'"
            v-model="form.role_id"
            type="select"
            label="Role"
            :options="roleOptions"
            :disabled="creating"
          />

          <div
            class="rounded-lg border border-outline-amber-2 bg-surface-amber-1 p-3 text-p-sm text-ink-gray-7"
          >
            Email is not set up yet, so no invite is sent. Share this password
            with them yourself, and over something safer than plain email.
          </div>

          <ErrorMessage :message="createError" />
        </div>
      </template>
      <template #actions>
        <Button
          variant="solid"
          class="w-full"
          :loading="creating"
          @click="createPerson"
        >
          Create account
        </Button>
      </template>
    </Dialog>
  </div>
</template>

<script setup lang="ts">
import { notify } from "@/lib/notify";
import { supabase } from "@/lib/supabase";
import { useAuthStore } from "@/stores/auth";
import {
  Avatar, Badge, Button, Dialog, ErrorMessage, FormControl, LoadingIndicator,
} from "frappe-ui";
import { computed, onMounted, reactive, ref } from "vue";

const auth = useAuthStore();

type Person = {
  id: string; email: string; full_name: string | null;
  kind: "admin" | "agent" | "customer";
  role_id: string | null; is_active: boolean;
};
type Role = {
  id: string; name: string; description: string | null;
  [k: string]: unknown;
};

const PERMISSIONS = [
  { key: "can_view_all_tickets", label: "See all tickets" },
  { key: "can_assign_tickets", label: "Assign tickets" },
  { key: "can_delete_tickets", label: "Delete tickets" },
  { key: "can_manage_agents", label: "Manage people" },
  { key: "can_manage_customers", label: "Manage customers" },
  { key: "can_change_settings", label: "Change settings" },
];

const people = ref<Person[]>([]);
const roles = ref<Role[]>([]);
const loading = ref(true);
const loadError = ref("");
const saveError = ref("");
const roleError = ref("");
const saving = ref<string | null>(null);
const savingRole = ref<string | null>(null);
const showHelp = ref(false);
const lastCreated = ref("");

const kindOptions = [
  { label: "Admin", value: "admin" },
  { label: "Agent", value: "agent" },
  { label: "Customer", value: "customer" },
];

const roleOptions = computed(() => [
  { label: "No role", value: "" },
  ...roles.value.map((r) => ({ label: r.name, value: r.id })),
]);

async function load() {
  try {
    const [{ data: p, error: e1 }, { data: r, error: e2 }] = await Promise.all([
      supabase
        .from("profiles")
        .select("id, email, full_name, kind, role_id, is_active")
        .order("kind")
        .order("email"),
      supabase.from("roles").select("*").order("name"),
    ]);
    if (e1) throw e1;
    if (e2) throw e2;
    people.value = (p as Person[]) ?? [];
    roles.value = (r as Role[]) ?? [];
  } catch (e: any) {
    loadError.value = e?.message || "Could not load people";
  } finally {
    loading.value = false;
  }
}

async function patch(p: Person, changes: Record<string, unknown>) {
  saving.value = p.id;
  saveError.value = "";
  const { error } = await supabase
    .from("profiles")
    .update(changes)
    .eq("id", p.id);
  saving.value = null;
  if (error) {
    saveError.value = error.message;
    await load(); // server ka sach wapas le aao
    return false;
  }
  Object.assign(p, changes);
  return true;
}

async function setKind(p: Person, kind: string) {
  // Customer banate waqt role hata dena zaroori hai — warna DB me ek aisa
  // customer bach jaata hai jiske paas agent wala role laga hua hai.
  const changes: Record<string, unknown> =
    kind === "customer" ? { kind, role_id: null } : { kind };
  await patch(p, changes);
}

function setRole(p: Person, roleId: string) {
  return patch(p, { role_id: roleId || null });
}

function toggleActive(p: Person) {
  return patch(p, { is_active: !p.is_active });
}

async function togglePerm(r: Role, key: string, value: boolean) {
  savingRole.value = r.id;
  roleError.value = "";
  const { error } = await supabase
    .from("roles")
    .update({ [key]: value })
    .eq("id", r.id);
  savingRole.value = null;
  if (error) {
    roleError.value = error.message;
    await load();
    return;
  }
  r[key] = value;
  // Agar apne hi role ki permission badli hai to store refresh karo,
  // warna UI purani permissions ke hisaab se chalti rahegi.
  if (auth.profile?.role_id === r.id) await auth.loadProfile();
}

// ---------------------------------------------------------------- add person
const showAdd = ref(false);
const creating = ref(false);
const createError = ref("");
const form = reactive({
  full_name: "", email: "", password: "", kind: "agent", role_id: "",
});

function randomPassword() {
  // crypto se, Math.random se nahi — Math.random predictable hota hai
  // aur ye password kisi ke account ka pehla taala banega.
  const chars = "abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789!@#$";
  const bytes = crypto.getRandomValues(new Uint32Array(16));
  return Array.from(bytes, (b) => chars[b % chars.length]).join("");
}

function openAdd() {
  createError.value = "";
  form.full_name = "";
  form.email = "";
  form.password = randomPassword();
  form.kind = "agent";
  form.role_id = roles.value.find((r) => r.name === "Agent")?.id ?? "";
  showAdd.value = true;
}

async function createPerson() {
  createError.value = "";
  if (!form.email.trim()) return (createError.value = "Please enter an email");
  if (form.password.length < 8)
    return (createError.value = "Password must be at least 8 characters");

  creating.value = true;
  try {
    // Edge function chahiye — user banane wali key browser me nahi rakh sakte.
    const { data, error } = await supabase.functions.invoke("create-user", {
      body: {
        email: form.email.trim(),
        password: form.password,
        full_name: form.full_name.trim(),
        kind: form.kind,
        role_id: form.role_id || null,
      },
    });
    // functions.invoke non-2xx par error deta hai par body nigal jaata hai,
    // isliye asli message nikalne ki koshish karte hain — warna user ko
    // sirf "Edge Function returned a non-2xx status code" dikhta hai.
    if (error) {
      const ctx = (error as any).context;
      const msg = ctx && typeof ctx.json === "function"
        ? (await ctx.json().catch(() => null))?.error
        : null;
      throw new Error(msg || error.message);
    }
    if ((data as any)?.error) throw new Error((data as any).error);

    // Welcome mail. Na jaye to bhi account ban chuka hai — admin password
    // haath se de sakta hai, isliye ise fail hone dena theek hai.
    const mailed = await notify("user_invited", {
      email: form.email.trim(),
      password: form.password,
      full_name: form.full_name.trim(),
    });

    showAdd.value = false;
    lastCreated.value = mailed
      ? `Account created and the details were emailed to ${form.email.trim()}.`
      : `Account created, but the email could not be sent. Share this password yourself: ${form.password}`;
    await load();
  } catch (e: any) {
    createError.value = e?.message || "Could not create the account";
  } finally {
    creating.value = false;
  }
}

onMounted(load);
</script>
