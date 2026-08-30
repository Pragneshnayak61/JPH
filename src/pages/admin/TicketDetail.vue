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
          <p class="whitespace-pre-wrap text-p-base text-ink-gray-8">
            <template v-for="(part, i) in splitMentions(m.body)" :key="i">
              <span
                v-if="part.isMention"
                class="rounded bg-surface-blue-2 px-1 font-medium text-ink-blue-3"
                >{{ part.text }}</span
              >
              <template v-else>{{ part.text }}</template>
            </template>
          </p>
        </div>
      </div>

      <!-- reply box -->
      <div class="border-t border-outline-gray-2 px-6 py-4">
        <div class="relative">
          <FormControl
            ref="replyBox"
            v-model="reply"
            type="textarea"
            :rows="3"
            :placeholder="
              isInternal
                ? 'Internal note — type @ to mention someone'
                : 'Write a reply...'
            "
            :disabled="sending"
            @keyup="onReplyKeyup"
          />

          <!-- @ ke baad list. Sirf internal note me — public reply me
               mention ka koi matlab nahi, wo customer ko jaata hai. -->
          <div
            v-if="mentionOpen && isInternal"
            class="absolute bottom-full left-0 z-10 mb-1 max-h-48 w-64 overflow-auto rounded-lg border border-outline-gray-2 bg-surface-base py-1 shadow-lg"
          >
            <button
              v-for="d in mentionMatches"
              :key="d.id"
              class="block w-full px-3 py-1.5 text-left text-p-sm hover:bg-surface-gray-2"
              @click="pickMention(d)"
            >
              <span class="text-ink-gray-8">{{ d.label }}</span>
              <span v-if="d.specialization" class="text-ink-gray-5">
                · {{ d.specialization }}
              </span>
            </button>
            <p
              v-if="!mentionMatches.length"
              class="px-3 py-1.5 text-p-sm text-ink-gray-5"
            >
              No match
            </p>
          </div>
        </div>
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
        <FormControl v-model="edit.status" type="select" :options="statusOptions" />
      </div>

      <div>
        <FormLabel label="Due date" />
        <FormControl v-model="edit.due_date" type="date" />
        <p v-if="isOverdue" class="mt-1 text-p-sm font-medium text-ink-red-3">
          Overdue
        </p>
      </div>

      <div>
        <FormLabel label="Category" />
        <FormControl
          v-model="edit.category_id"
          type="select"
          :options="categoryOptions"
        />
      </div>

      <div>
        <FormLabel label="Priority" />
        <FormControl v-model="edit.priority" type="select" :options="priorityOptions" />
      </div>

      <div>
        <FormLabel label="Assigned to" />
        <FormControl
          v-model="edit.assigned_to"
          type="select"
          :options="agentOptions"
          :disabled="!auth.can('can_assign_tickets')"
        />
        <p
          v-if="!auth.can('can_assign_tickets')"
          class="mt-1 text-p-sm text-ink-gray-5"
        >
          You do not have permission to assign tickets.
        </p>
      </div>

      <!-- Save button. Pehle har dropdown apne aap save karta tha, par
           @change v-model se PEHLE chalta hai — to purani value save
           hoti thi aur badlav gayab ho jaata tha. -->
      <div class="sticky bottom-0 -mx-4 border-t border-outline-gray-2 bg-surface-gray-1 px-4 py-3">
        <Button
          variant="solid"
          class="w-full"
          :loading="saving"
          :disabled="!isDirty"
          @click="saveChanges"
        >
          {{ isDirty ? "Save changes" : "Saved" }}
        </Button>
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
  FormLabel, LoadingIndicator, toast,
} from "frappe-ui";
import { computed, onMounted, reactive, ref } from "vue";
import { useRouter } from "vue-router";

const props = defineProps<{ id: string }>();
const router = useRouter();
const auth = useAuthStore();

type Ticket = {
  id: number; subject: string; description: string;
  status: string; priority: string;
  raised_by_email: string; contact_name: string | null;
  company_name: string | null; assigned_to: string | null;
  category_id: string | null;
  due_date: string | null;
  created_at: string;
};
type Message = {
  id: number; body: string; is_internal: boolean;
  author_id: string | null;
  author_name: string | null; author_email: string | null; created_at: string;
};

const ticket = ref<Ticket | null>(null);
const messages = ref<Message[]>([]);
/**
 * Sidebar ke saare badalne wale field ek jagah.
 *
 * Pehle har field seedha save hota tha (@change par). Wo do wajah se
 * galat tha:
 *   - @change v-model se PEHLE chalta hai, to purani value jaati thi
 *   - har chhote badlav par ek request, aur aadha-adhoora state bach
 *     jaata agar beech me koi fail ho jaye
 */
const edit = reactive({
  status: "",
  priority: "",
  assigned_to: "",
  category_id: "",
  due_date: "",
});
// Jo server par hai. Isse tulna karke pata chalta hai kuch badla ya nahi.
let saved = { ...edit };
const saving = ref(false);

const isDirty = computed(
  () => JSON.stringify(edit) !== JSON.stringify(saved)
);

async function saveChanges() {
  saving.value = true;
  saveError.value = "";
  try {
    const { error } = await supabase
      .from("tickets")
      .update({
        status: edit.status,
        priority: edit.priority,
        // khali string nahi — ye uuid/date columns hain, "" unke liye
        // invalid hai aur Postgres error de deta hai
        assigned_to: edit.assigned_to || null,
        category_id: edit.category_id || null,
        due_date: edit.due_date || null,
      })
      .eq("id", Number(props.id));
    if (error) throw error;

    saved = { ...edit };
    if (ticket.value) ticket.value.status = edit.status;
    toast.success("Ticket updated");
  } catch (e: any) {
    saveError.value = e?.message || "Could not save";
    toast.error("Could not save the ticket");
  } finally {
    saving.value = false;
  }
}
const agentOptions = ref<{ label: string; value: string }[]>([]);
const staffLabels = ref<Record<string, string>>({});

// Band ho chuke ticket par "Overdue" dikhana bekaar hai — kaam ho gaya,
// deri ab maayne nahi rakhti.
const isOverdue = computed(() => {
  if (!edit.due_date) return false;
  if (["resolved", "closed"].includes(edit.status)) return false;
  return new Date(edit.due_date) < new Date(new Date().toDateString());
});
const categoryOptions = ref<{ label: string; value: string }[]>([]);

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
// ---------------------------------------------------------------- mentions
type Directory = { id: string; label: string; specialization: string | null };
const directory = ref<Directory[]>([]);
const mentionOpen = ref(false);
const mentionQuery = ref("");

const mentionMatches = computed(() => {
  const q = mentionQuery.value.toLowerCase();
  return directory.value
    .filter((d) => !q || d.label.toLowerCase().includes(q)
                || (d.specialization ?? "").toLowerCase().includes(q))
    .slice(0, 8);
});

/**
 * Cursor se pehle "@abc" jaisa kuch hai ya nahi, ye dekhta hai.
 *
 * Sirf tab khulta hai jab @ ek naye shabd ki shuruaat me ho — warna
 * email likhte waqt ("a@b.com") bhi list khul jaati.
 */
function onReplyKeyup(e: KeyboardEvent) {
  if (!isInternal.value) {
    mentionOpen.value = false;
    return;
  }
  const el = e.target as HTMLTextAreaElement;
  const upto = reply.value.slice(0, el.selectionStart ?? 0);
  const m = upto.match(/(?:^|\s)@([\w-]*)$/);
  if (m) {
    mentionQuery.value = m[1];
    mentionOpen.value = true;
  } else {
    mentionOpen.value = false;
  }
}

/**
 * "@AG-01" dhoondhne wali regex.
 *
 * Do baatein zaroori hain, aur dono bhoolne par chup-chaap galat kaam
 * karti hain:
 *
 * 1. Template literal me `\w` likhne par JS backslash gira deta hai —
 *    regex `[w-]` ban jaati hai, `[\w-]` nahi. Isliye normal string me
 *    "\\w" likha hai.
 *
 * 2. Label me regex ke special akshar ho sakte hain (admin ID kuch bhi
 *    rakh sakta hai, jaise "AG.01"). Bina escape kiye "." har akshar se
 *    match kar jaata.
 */
function mentionRegex(label: string) {
  const safe = label.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  return new RegExp("@" + safe + "(?![\\w-])");
}

function pickMention(d: Directory) {
  // Aakhri "@abc" ko poore label se badal do.
  reply.value = reply.value.replace(/(^|\s)@[\w-]*$/, `$1@${d.label} `);
  mentionOpen.value = false;
}

/**
 * Message ko tukdo me todta hai taaki @AG-02 ko alag rang de sakein.
 * v-html se karte to guest ka bheja HTML bhi chal jaata — yahan sirf
 * text hai, isliye ye tarika surakshit hai.
 */
function splitMentions(body: string) {
  const known = directory.value.map((d) => d.label);
  const out: { text: string; isMention: boolean }[] = [];
  const re = /@([\w-]+)/g;
  let last = 0;
  let m: RegExpExecArray | null;
  while ((m = re.exec(body))) {
    if (!known.includes(m[1])) continue;
    if (m.index > last) out.push({ text: body.slice(last, m.index), isMention: false });
    out.push({ text: m[0], isMention: true });
    last = m.index + m[0].length;
  }
  if (last < body.length) out.push({ text: body.slice(last), isMention: false });
  return out;
}

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
    Object.assign(edit, {
      status: t.status,
      priority: t.priority,
      assigned_to: t.assigned_to ?? "",
      category_id: t.category_id ?? "",
      due_date: t.due_date ?? "",
    });
    saved = { ...edit };

    const { data: m } = await supabase
      .from("ticket_messages")
      .select("id, body, is_internal, author_id, author_name, author_email, created_at")
      .eq("ticket_id", Number(props.id))
      .order("created_at");
    messages.value = (m as Message[]) ?? [];

    // profiles se seedha nahi padh sakte — ab RLS sirf apni profile aur
    // admin ko sab deti hai. staff_directory() agent ko sirf "Agent 1"
    // jaisa code deta hai, admin ko asli naam.
    const { data: cats } = await supabase
      .from("ticket_categories")
      .select("id, name")
      .order("sort_order");
    categoryOptions.value = [
      { label: "None", value: "" },
      ...(cats ?? []).map((c: any) => ({ label: c.name, value: c.id })),
    ];

    const { data: dir } = await supabase.rpc("staff_directory");
    // Dropdown me specialization bhi — "AG-02" akela dekhkar agent ko
    // pata hi nahi chalta ki ticket kise dena chahiye.
    const withRole = (d: any) =>
      d.specialization ? `${d.label} · ${d.specialization}` : d.label;

    directory.value = (dir ?? []).map((d: any) => ({
      id: d.id, label: d.label, specialization: d.specialization,
    }));
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

    // Mentions alag table me. Body me se dhoondhte hain, na ki UI ke
    // state se — user pick karke text haath se mita bhi sakta hai.
    if (isInternal.value && msg) {
      const hit = directory.value.filter((d) =>
        mentionRegex(d.label).test(reply.value)
      );
      if (hit.length) {
        await supabase.from("message_mentions").insert(
          hit.map((d) => ({
            message_id: msg.id,
            ticket_id: Number(props.id),
            profile_id: d.id,
            mentioned_by: auth.profile?.id ?? null,
          }))
        );
      }
    }

    // Public reply ka matlab hai gend ab customer ke paale me hai.
    // Internal note par status nahi badalna chahiye — wo sirf team ke liye hai.
    if (!isInternal.value && ticket.value && ticket.value.status === "open") {
      await updateField("status", "replied");
      ticket.value.status = "replied";
      edit.status = "replied";
      saved.status = "replied";
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
