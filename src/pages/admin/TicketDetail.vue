<template>
  <div v-if="loading" class="flex h-full items-center justify-center">
    <LoadingIndicator class="h-5 w-5 text-ink-gray-5" />
  </div>

  <div v-else-if="error" class="p-6">
    <p class="text-p-base text-ink-red-3">{{ error }}</p>
    <Button variant="subtle" class="mt-3" @click="router.push('/admin')">
      Back to dashboard
    </Button>
  </div>

  <div v-else-if="ticket" class="flex h-full">
    <!-- conversation -->
    <div class="flex min-w-0 flex-1 flex-col">
      <div class="border-b border-outline-gray-2 px-6 py-4">
        <button
          class="mb-2 flex items-center gap-1 text-p-sm text-ink-gray-6 hover:text-ink-gray-8"
          @click="router.push('/admin')"
        >
          <FeatherIcon name="arrow-left" class="h-3.5 w-3.5" />
          Back
        </button>
        <h1 class="text-lg font-semibold text-ink-gray-9">
          {{ ticket.subject }}
        </h1>
        <p class="mt-1 text-p-sm text-ink-gray-6">
          #{{ ticket.id }} &middot; {{ ticket.contact_name || "Unknown" }}
          &lt;{{ ticket.raised_by_email }}&gt; &middot;
          {{ formatDate(ticket.created_at) }}
        </p>
      </div>

      <div class="flex-1 overflow-auto px-6 py-4">
        <!-- original request -->
        <div class="rounded-lg border border-outline-gray-2 p-4">
          <div class="mb-2 flex items-center gap-2">
            <Avatar :label="ticket.contact_name || ticket.raised_by_email" size="sm" />
            <span class="text-p-sm font-medium text-ink-gray-8">
              {{ ticket.contact_name || ticket.raised_by_email }}
            </span>
            <span class="text-p-sm text-ink-gray-5">
              {{ formatDate(ticket.created_at) }}
            </span>
          </div>
          <!-- Guest ka HTML hai — bina sanitize kiye render karna XSS hai -->
          <div
            v-if="looksLikeHtml(ticket.description)"
            class="prose prose-sm max-w-none text-ink-gray-8"
            v-html="safeHtml(ticket.description)"
          ></div>
          <p v-else class="whitespace-pre-wrap text-p-base text-ink-gray-8">
            {{ ticket.description }}
          </p>
        </div>

        <!-- replies -->
        <div
          v-for="m in messages"
          :key="m.id"
          class="mt-3 rounded-lg border p-4"
          :class="
            m.is_internal
              ? 'border-outline-amber-2 bg-surface-amber-1'
              : 'border-outline-gray-2 bg-surface-gray-1'
          "
        >
          <div class="mb-2 flex items-center gap-2">
            <Avatar :label="messageAuthor(m)" size="sm" />
            <span class="text-p-sm font-medium text-ink-gray-8">
              {{ messageAuthor(m) }}
            </span>
            <Badge v-if="m.is_internal" theme="orange" variant="subtle">
              Internal note
            </Badge>
            <span class="text-p-sm text-ink-gray-5">
              {{ formatDate(m.created_at) }}
            </span>
          </div>
          <p class="whitespace-pre-wrap text-p-base text-ink-gray-8">{{ m.body }}</p>
        </div>
      </div>

      <!-- reply box -->
      <div class="border-t border-outline-gray-2 px-6 py-4">
        <FormControl
          v-model="reply"
          type="textarea"
          :rows="3"
          :placeholder="
            isInternal
              ? 'Internal note — the customer will not see this'
              : 'Write a reply...'
          "
          :disabled="sending"
        />
        <div class="mt-2 flex items-center justify-between">
          <label class="flex items-center gap-2 text-p-sm text-ink-gray-6">
            <input v-model="isInternal" type="checkbox" class="rounded" />
            Internal note
          </label>
          <Button
            variant="solid"
            :loading="sending"
            :disabled="!reply.trim()"
            @click="sendReply"
          >
            {{ isInternal ? "Add note" : "Send reply" }}
          </Button>
        </div>
        <ErrorMessage :message="replyError" class="mt-2" />
        <p
          v-if="emailSent === false"
          class="mt-2 text-p-sm text-ink-amber-3"
        >
          Reply saved, but the email could not be sent. Check the email
          settings.
        </p>
      </div>
    </div>

    <!-- sidebar -->
    <aside
      class="w-72 shrink-0 space-y-4 overflow-auto border-l border-outline-gray-2 bg-surface-gray-1 p-4"
    >
      <div>
        <FormLabel label="Status" />
        <FormControl
          v-model="ticket.status"
          type="select"
          :options="statusOptions"
          @change="updateField('status', ticket.status)"
        />
      </div>

      <div>
        <FormLabel label="Priority" />
        <FormControl
          v-model="ticket.priority"
          type="select"
          :options="priorityOptions"
          @change="updateField('priority', ticket.priority)"
        />
      </div>

      <div>
        <FormLabel label="Assigned to" />
        <FormControl
          v-model="assignedTo"
          type="select"
          :options="agentOptions"
          :disabled="!auth.can('can_assign_tickets')"
          @change="updateField('assigned_to', assignedTo || null)"
        />
        <p
          v-if="!auth.can('can_assign_tickets')"
          class="mt-1 text-p-sm text-ink-gray-5"
        >
          You do not have permission to assign tickets.
        </p>
      </div>

      <div class="space-y-2 border-t border-outline-gray-2 pt-4 text-p-sm">
        <div class="flex justify-between">
          <span class="text-ink-gray-6">Company</span>
          <span class="text-ink-gray-8">{{ ticket.company_name || "—" }}</span>
        </div>
        <div class="flex justify-between">
          <span class="text-ink-gray-6">Email</span>
          <span class="truncate pl-2 text-ink-gray-8">
            {{ ticket.raised_by_email }}
          </span>
        </div>
        <div class="flex justify-between">
          <span class="text-ink-gray-6">Created</span>
          <span class="text-ink-gray-8">{{ formatDate(ticket.created_at) }}</span>
        </div>
      </div>

      <ErrorMessage :message="saveError" />

      <!-- Delete sabse neeche aur alag rakha hai. Ye wapas nahi aata,
           isliye status/assign ke paas nahi hona chahiye jahan galti se
           click ho jaye. -->
      <div
        v-if="auth.can('can_delete_tickets')"
        class="border-t border-outline-gray-2 pt-4"
      >
        <button
          class="text-p-sm text-ink-red-3 underline hover:text-ink-red-4"
          @click="showDelete = true"
        >
          Delete this ticket
        </button>
      </div>
    </aside>

    <Dialog
      v-model="showDelete"
      :options="{ title: 'Delete this ticket?', size: 'sm' }"
    >
      <template #body-content>
        <p class="text-p-base text-ink-gray-7">
          Ticket #{{ ticket.id }} and every reply on it will be removed. This
          cannot be undone.
        </p>
        <p class="mt-2 text-p-sm text-ink-gray-5">
          If you only want it out of the queue, set the status to
          <strong>Closed</strong> instead &mdash; that keeps the history.
        </p>
        <ErrorMessage :message="deleteError" class="mt-3" />
      </template>
      <template #actions>
        <div class="flex gap-2">
          <Button class="flex-1" @click="showDelete = false">Cancel</Button>
          <Button
            class="flex-1"
            theme="red"
            variant="solid"
            :loading="deleting"
            @click="destroy"
          >
            Delete
          </Button>
        </div>
      </template>
    </Dialog>
  </div>
</template>

<script setup lang="ts">
import { notify } from "@/lib/notify";
import { looksLikeHtml, safeHtml } from "@/lib/richText";
import { supabase } from "@/lib/supabase";
import { useAuthStore } from "@/stores/auth";
import {
  Avatar, Badge, Button, Dialog, ErrorMessage, FeatherIcon, FormControl,
  FormLabel, LoadingIndicator,
} from "frappe-ui";
import { onMounted, ref } from "vue";
import { useRouter } from "vue-router";

const props = defineProps<{ id: string }>();
const router = useRouter();
const auth = useAuthStore();

type Ticket = {
  id: number; subject: string; description: string;
  status: string; priority: string;
  raised_by_email: string; contact_name: string | null;
  company_name: string | null; assigned_to: string | null;
  created_at: string;
};
type Message = {
  id: number; body: string; is_internal: boolean;
  author_id: string | null;
  author_name: string | null; author_email: string | null; created_at: string;
};

const ticket = ref<Ticket | null>(null);
const messages = ref<Message[]>([]);
const assignedTo = ref<string>("");
const agentOptions = ref<{ label: string; value: string }[]>([]);
const staffLabels = ref<Record<string, string>>({});

/**
 * Message par kiska naam dikhana hai.
 *
 * author_name me agent ka ASLI naam save hota hai (customer ko wahi
 * dikhna chahiye). Par yahan agent-facing screen hai, aur ek agent ko
 * doosre ka naam nahi dikhna chahiye — isliye author_id se directory
 * ka label lete hain, jo admin ko naam aur agent ko code deta hai.
 * Customer ke apne reply par author_id null hota hai, wahan naam theek hai.
 */
function messageAuthor(m: Message) {
  if (m.author_id && staffLabels.value[m.author_id]) {
    return staffLabels.value[m.author_id];
  }
  return m.author_name || m.author_email || "Customer";
}

const loading = ref(true);
const error = ref("");
const saveError = ref("");
const reply = ref("");
const isInternal = ref(false);
const sending = ref(false);
const replyError = ref("");
// null = abhi koi reply nahi bheji; true/false = pichhli mail gayi ya nahi
const emailSent = ref<boolean | null>(null);
const showDelete = ref(false);
const deleting = ref(false);
const deleteError = ref("");

async function destroy() {
  deleting.value = true;
  deleteError.value = "";
  try {
    const { error, count } = await supabase
      .from("tickets")
      .delete({ count: "exact" })
      .eq("id", Number(props.id));
    if (error) throw error;

    // RLS rok de to delete "safal" dikhta hai par 0 rows jaati hain.
    // Bina is check ke user ko lagta ki ticket mit gaya, aur wo list me
    // wapas dikhta rehta.
    if (!count) {
      throw new Error("You do not have permission to delete this ticket.");
    }
    router.push("/admin");
  } catch (e: any) {
    deleteError.value = e?.message || "Could not delete the ticket";
  } finally {
    deleting.value = false;
  }
}

const statusOptions = [
  { label: "Open", value: "open" },
  { label: "Replied", value: "replied" },
  { label: "Resolved", value: "resolved" },
  { label: "Closed", value: "closed" },
];
const priorityOptions = [
  { label: "Low", value: "low" },
  { label: "Medium", value: "medium" },
  { label: "High", value: "high" },
  { label: "Urgent", value: "urgent" },
];

function formatDate(s: string) {
  return new Date(s).toLocaleString(undefined, {
    day: "numeric", month: "short", hour: "2-digit", minute: "2-digit",
  });
}

async function load() {
  try {
    const { data: t, error: e1 } = await supabase
      .from("tickets")
      .select("*")
      .eq("id", Number(props.id))
      .single();
    if (e1) throw e1;
    ticket.value = t as Ticket;
    assignedTo.value = t.assigned_to ?? "";

    const { data: m } = await supabase
      .from("ticket_messages")
      .select("id, body, is_internal, author_id, author_name, author_email, created_at")
      .eq("ticket_id", Number(props.id))
      .order("created_at");
    messages.value = (m as Message[]) ?? [];

    // profiles se seedha nahi padh sakte — ab RLS sirf apni profile aur
    // admin ko sab deti hai. staff_directory() agent ko sirf "Agent 1"
    // jaisa code deta hai, admin ko asli naam.
    const { data: dir } = await supabase.rpc("staff_directory");
    // Dropdown me specialization bhi — "AG-02" akela dekhkar agent ko
    // pata hi nahi chalta ki ticket kise dena chahiye.
    const withRole = (d: any) =>
      d.specialization ? `${d.label} · ${d.specialization}` : d.label;

    staffLabels.value = Object.fromEntries(
      (dir ?? []).map((d: any) => [d.id, withRole(d)])
    );
    agentOptions.value = [
      { label: "Unassigned", value: "" },
      ...(dir ?? []).map((d: any) => ({ label: withRole(d), value: d.id })),
    ];
  } catch (e: any) {
    // RLS chup-chaap khali result deti hai, error nahi — isliye "not found"
    // ka matlab "hai hi nahi" ya "aapko dekhne ki permission nahi", dono
    // ho sakta hai. User ko dono ek hi jaisa dikhta hai, aur yahi sahi hai.
    error.value = e?.message || "Could not load this ticket";
  } finally {
    loading.value = false;
  }
}

async function updateField(field: string, value: unknown) {
  saveError.value = "";
  const { error: e } = await supabase
    .from("tickets")
    .update({ [field]: value })
    .eq("id", Number(props.id));
  if (e) saveError.value = e.message;
}

async function sendReply() {
  if (!reply.value.trim()) return;
  sending.value = true;
  replyError.value = "";
  try {
    // .select() isliye ki message ka id chahiye — notify function usi id
    // se message dhoondh kar mail bhejta hai (body client se nahi leta).
    const { data: msg, error: e } = await supabase
      .from("ticket_messages")
      .insert({
        ticket_id: Number(props.id),
        author_id: auth.profile?.id ?? null,
        author_email: auth.profile?.email ?? null,
        author_name: auth.profile?.full_name ?? auth.profile?.email ?? null,
        body: reply.value.trim(),
        is_internal: isInternal.value,
      })
      .select("id")
      .single();
    if (e) throw e;

    // Internal note kabhi mail nahi hona chahiye. Ye check server par bhi
    // hai — galti se chala gaya to wapas nahi le sakte.
    if (!isInternal.value && msg) {
      emailSent.value = await notify("agent_reply", { message_id: msg.id });
    }

    // Public reply ka matlab hai gend ab customer ke paale me hai.
    // Internal note par status nahi badalna chahiye — wo sirf team ke liye hai.
    if (!isInternal.value && ticket.value && ticket.value.status === "open") {
      await updateField("status", "replied");
      ticket.value.status = "replied";
    }

    reply.value = "";
    isInternal.value = false;
    await load();
  } catch (e: any) {
    replyError.value = e?.message || "Could not send the reply";
  } finally {
    sending.value = false;
  }
}

onMounted(load);
</script>
