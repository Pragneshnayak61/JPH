/**
 * Is browser se bane tickets yaad rakhta hai.
 *
 * Problem ye thi: guest ko ticket ka link milta hai, par agar wo bookmark
 * karna bhool gaya to ticket tak dobara pahunchne ka koi raasta hi nahi
 * bachta — na login hai, na email.
 *
 * Ye poora hal NAHI hai. Sirf usi browser par kaam karta hai. Doosre
 * device se, ya history saaf karne par, ye list khali ho jayegi.
 * Asli hal email hai (link mail me bhej dena) — wo baad me lagega.
 *
 * Shared computer par ye thoda risk hai: agla banda wahi list dekh lega.
 * Isliye page par "Forget" ka option bhi diya hai.
 */

const KEY = "jph.my-tickets";
const MAX = 20;

export type SavedTicket = {
  token: string;
  id: number | string;
  subject: string;
  saved_at: string;
};

/**
 * localStorage har jagah kaam nahi karta — private window, cookies band,
 * ya storage bhara hua. In sab me ye throw karta hai. Ticket banna isse
 * kabhi nahi rukna chahiye, isliye har jagah try/catch.
 */
export function getMyTickets(): SavedTicket[] {
  try {
    const raw = localStorage.getItem(KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

export function rememberTicket(t: SavedTicket): void {
  try {
    const all = getMyTickets().filter((x) => x.token !== t.token);
    all.unshift(t);
    localStorage.setItem(KEY, JSON.stringify(all.slice(0, MAX)));
  } catch {
    // Yaad na rakh paye to bhi ticket ban chuka hai. Chup rehna hi theek hai.
  }
}

export function forgetTickets(): void {
  try {
    localStorage.removeItem(KEY);
  } catch {
    /* ignore */
  }
}
