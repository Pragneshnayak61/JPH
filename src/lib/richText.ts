import DOMPurify from "dompurify";

/**
 * Guest ka bheja HTML kabhi seedha render mat kijiye.
 *
 * Description ab rich text editor se aata hai, yani HTML. Aur guest form
 * bina login ke khula hai — koi bhi kuch bhi bhej sakta hai. Bina safai
 * ke `v-html` karte to koi `<script>` ya `<img onerror=...>` bhej deta,
 * aur wo AGENT ke logged-in browser me chalta. Wahan se uska session
 * churana mumkin hai.
 *
 * Isliye har jagah render se pehle yahi function.
 */
export function safeHtml(input: string | null | undefined): string {
  if (!input) return "";
  return DOMPurify.sanitize(input, {
    ALLOWED_TAGS: [
      "p", "br", "strong", "em", "u", "s", "code", "pre",
      "ul", "ol", "li", "blockquote", "h1", "h2", "h3", "h4",
      "a", "hr",
    ],
    ALLOWED_ATTR: ["href", "target", "rel"],
    // javascript: aur data: URLs band. Ek <a href="javascript:..."> hi
    // kaafi hai click par code chalane ke liye.
    ALLOWED_URI_REGEXP: /^(?:https?:|mailto:|tel:|#|\/)/i,
  });
}

/**
 * Purane tickets ka description plain text hai (rich editor se pehle ke).
 * Usme koi tag nahi hota, to use HTML ki tarah render karne par saari
 * line breaks gayab ho jaati hain.
 *
 * Isliye pehle dekh lete hain ki HTML jaisa kuch hai bhi ya nahi.
 */
export function looksLikeHtml(s: string | null | undefined): boolean {
  if (!s) return false;
  return /<\/?[a-z][\s\S]*>/i.test(s);
}
