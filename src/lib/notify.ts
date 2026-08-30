import { supabase } from "./supabase";

/**
 * Email bhejne ki koshish karta hai — aur FAIL HONE PAR CHUP RAHTA HAI.
 *
 * Ye jaan-boojh kar hai. Email ek side-effect hai, asli kaam nahi.
 * Agar Gmail down ho, ya SMTP block ho, ya limit khatam ho jaye — to
 * customer ka ticket phir bhi banna chahiye aur agent ka reply phir bhi
 * save hona chahiye. Ticket kho dena email na jaane se kahin bura hai.
 *
 * Isliye kabhi throw nahi karta, aur caller ko `await` karne ki bhi
 * zaroorat nahi.
 */
export async function notify(
  type: "ticket_created" | "agent_reply" | "ticket_assigned" | "user_invited",
  payload: Record<string, unknown>
): Promise<boolean> {
  try {
    const { error } = await supabase.functions.invoke("notify", {
      body: { type, ...payload },
    });
    if (error) {
      console.warn(`[notify] ${type} failed:`, error.message);
      return false;
    }
    return true;
  } catch (e) {
    console.warn(`[notify] ${type} threw:`, e);
    return false;
  }
}
