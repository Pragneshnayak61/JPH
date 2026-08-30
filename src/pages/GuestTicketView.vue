<template>
  <div class="min-h-full bg-surface-gray-1 py-10">
    <div class="mx-auto w-full max-w-2xl px-4">
      <div v-if="loading" class="py-20 text-center">
        <LoadingIndicator class="mx-auto h-5 w-5 text-ink-gray-5" />
      </div>

      <div
        v-else-if="!ticket"
        class="rounded-xl border border-outline-gray-2 bg-surface-base p-8 text-center"
      >
        <h1 class="text-lg font-semibold text-ink-gray-9">Ticket not found</h1>
        <p class="mt-2 text-p-base text-ink-gray-6">
          This link is not valid. Check that you copied all of it.
        </p>
        <Button variant="subtle" class="mt-4" @click="router.push('/')">
          Raise a new ticket
        </Button>
      </div>

      <template v-else>
        <div class="mb-5">
          <h1 class="text-lg font-semibold text-ink-gray-9">
            {{ ticket.subject }}
          </h1>
          <div class="mt-2 flex items-center gap-2">
            <Badge :theme="statusTheme[ticket.status]" variant="subtle">
              {{ statusLabel[ticket.status] }}
            </Badge>
            <span class="text-p-sm text-ink-gray-5">
              Ticket #{{ ticket.id }} &middot; {{ formatDate(ticket.created_at) }}
            </span>
          </div>
        </div>

        <!-- conversation -->
        <div class="space-y-3">
          <div class="rounded-xl border border-outline-gray-2 bg-surface-base p-4">
            <p class="mb-2 text-p-sm font-medium text-ink-gray-7">
              {{ ticket.contact_name || "You" }}
            </p>
            <div
              v-if="looksLikeHtml(ticket.description)"
              class="prose prose-sm max-w-none text-ink-gray-8"
              v-html="safeHtml(ticket.description)"
            ></div>
            <p v-else class="whitespace-pre-wrap text-p-base text-ink-gray-8">
              {{ ticket.description }}
            </p>
          </div>

          <div
            v-for="(m, i) in ticket.messages"
            :key="i"
            class="rounded-xl border border-outline-gray-2 bg-surface-base p-4"
          >
            <div class="mb-2 flex items-center justify-between">
              <p class="text-p-sm font-medium text-ink-gray-7">
                {{ m.author_name || "Support" }}
              </p>
              <p class="text-p-sm text-ink-gray-5">
                {{ formatDate(m.created_at) }}
              </p>
            </div>
            <p class="whitespace-pre-wrap text-p-base text-ink-gray-8">
              {{ m.body }}
            </p>
          </div>
        </div>

        <!-- reply -->
        <div
          class="mt-4 rounded-xl border border-outline-gray-2 bg-surface-base p-4"
        >
          <FormControl
            v-model="reply"
            type="textarea"
            :rows="4"
            label="Add a message"
            placeholder="Anything else we should know?"
            :disabled="sending"
          />
          <ErrorMessage :message="replyError" class="mt-2" />
          <Button
            variant="solid"
            class="mt-3 w-full"
            :loading="sending"
            :disabled="!reply.trim()"
            @click="send"
          >
            Send
          </Button>
        </div>

        <p class="mt-4 text-center text-p-sm text-ink-gray-5">
          Keep this page bookmarked to check back on your ticket.
        </p>
      </template>

      <SiteFooter />
    </div>
  </div>
</template>

<script setup lang="ts">
import SiteFooter from "@/components/SiteFooter.vue";
import { looksLikeHtml, safeHtml } from "@/lib/richText";
import { supabase } from "@/lib/supabase";
import {
  Badge, Button, ErrorMessage, FormControl, LoadingIndicator,
} from "frappe-ui";
import { onMounted, ref } from "vue";
import { useRouter } from "vue-router";

const props = defineProps<{ token: string }>();
const router = useRouter();

type GuestTicket = {
  id: number; subject: string; description: string;
  status: string; priority: string;
  contact_name: string | null; company_name: string | null;
  created_at: string;
  messages: { body: string; author_name: string | null; created_at: string }[];
};

const ticket = ref<GuestTicket | null>(null);
const loading = ref(true);
const reply = ref("");
const sending = ref(false);
const replyError = ref("");

const statusTheme: Record<string, string> = {
  open: "orange", replied: "blue", resolved: "green", closed: "gray",
};
// Customer ko "Replied" jaisa andar ka lafz dikhane ka koi matlab nahi —
// use ye samajhna hai ki gend kiske paale me hai.
const statusLabel: Record<string, string> = {
  open: "Waiting for support",
  replied: "Support has replied",
  resolved: "Resolved",
  closed: "Closed",
};

function formatDate(s: string) {
  return new Date(s).toLocaleString(undefined, {
    day: "numeric", month: "short", hour: "2-digit", minute: "2-digit",
  });
}

async function load() {
  loading.value = true;
  const { data } = await supabase.rpc("get_guest_ticket", {
    p_token: props.token,
  });
  ticket.value = (data as GuestTicket) ?? null;
  loading.value = false;
}

async function send() {
  if (!reply.value.trim()) return;
  sending.value = true;
  replyError.value = "";
  try {
    const { error } = await supabase.rpc("add_guest_reply", {
      p_token: props.token,
      p_body: reply.value.trim(),
    });
    if (error) throw error;
    reply.value = "";
    await load();
  } catch (e: any) {
    replyError.value = e?.message || "Could not send your message";
  } finally {
    sending.value = false;
  }
}

onMounted(load);
</script>
