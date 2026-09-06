import { supabase } from "./supabase";

/**
 * Operations checklist ka saboot — screenshot, backup report, log file.
 *
 * uploadImage.ts SE ALAG KYUN
 *
 * Wo `attachments` bucket me daalta hai, jo PUBLIC hai aur sirf image
 * leta hai. Ticket ke screenshot ke liye wo theek hai — customer bina
 * login apna ticket dekhta hai, isliye image ka URL khula hona zaroori
 * hai.
 *
 * Yahan dono baatein ulti hain. Backup report aur firewall log me
 * hostname, IP, user name aur network ka naksha hota hai — wo URL guess
 * karne par khulna nahi chahiye. Aur PDF/.log/CSV wo bucket reject kar
 * deta hai.
 *
 * Isliye `ops-evidence`: private, aur zyada file types
 * (31_ops_evidence.sql).
 *
 * PRIVATE HONE KA NATEEJA
 *
 * Private bucket ka file seedhe URL se nahi khulta. Har baar signed URL
 * banana padta hai, jo thodi der me khud mar jaata hai. Isiliye database
 * me URL nahi, `file_path` rakha jaata hai — path se signed URL kabhi
 * bhi banaya ja sakta hai, URL se path nikaalna bharosemand nahi.
 */

const BUCKET = "ops-evidence";
const MAX_BYTES = 20 * 1024 * 1024;

/** Bucket par bhi yahi list lagi hai (31_ops_evidence.sql). */
const ALLOWED = [
  "image/png",
  "image/jpeg",
  "image/gif",
  "image/webp",
  "application/pdf",
  "text/plain",
  "text/csv",
  "application/json",
  "application/zip",
  "application/x-zip-compressed",
];

export type EvidenceFile = {
  id: string;
  file_path: string;
  file_name: string;
  file_size: number | null;
  mime_type: string | null;
  created_at: string;
};

/**
 * File chadhata hai aur usse execution se jod deta hai.
 *
 * Do check yahan bhi hain jo bucket par bhi lage hain. Wajah sirf itni
 * ki user ko saaf message mile — server ka error tez hota hai par uska
 * matlab samajhna mushkil.
 */
export async function uploadEvidence(
  executionId: number,
  file: File
): Promise<EvidenceFile> {
  // Kuch browser .log aur .txt ka type khali chhod dete hain. Aise me
  // use text/plain maan lete hain — warna bilkul aam log file bina wajah
  // reject ho jaati.
  const type = file.type || guessType(file.name);

  if (!ALLOWED.includes(type)) {
    throw new Error(
      "Only images, PDF, text, CSV, JSON or ZIP files can be attached."
    );
  }
  if (file.size > MAX_BYTES) {
    throw new Error("That file is over 20 MB. Please attach a smaller one.");
  }

  // Naam khud banate hain, user ka nahi lete — user ke file name me slash
  // ya "../" ho sakta hai, aur do log ek hi naam bhej dein to ek doosre
  // ki file overwrite ho jaati.
  //
  // Folder execution ke id ka hai, taaki storage me dekh kar bhi pata
  // chale ki kaunsi file kis jaanch ki thi.
  const ext = (file.name.split(".").pop() || "bin").toLowerCase().slice(0, 6);
  const path = `${executionId}/${crypto.randomUUID()}.${ext}`;

  const { error: upErr } = await supabase.storage
    .from(BUCKET)
    .upload(path, file, { contentType: type, upsert: false });
  if (upErr) throw new Error(upErr.message);

  const { data, error } = await supabase
    .from("ops_execution_files")
    .insert({
      execution_id: executionId,
      file_path: path,
      file_name: file.name,
      file_size: file.size,
      mime_type: type,
    })
    .select("id, file_path, file_name, file_size, mime_type, created_at")
    .single();

  if (error) {
    // Row na bani to file bekaar padi rahegi aur kabhi kisi ko dikhegi
    // nahi. Use wahin hata dete hain.
    await supabase.storage.from(BUCKET).remove([path]);
    throw new Error(error.message);
  }

  return data as EvidenceFile;
}

/** Ek execution ke saare saboot. */
export async function listEvidence(
  executionId: number
): Promise<EvidenceFile[]> {
  const { data } = await supabase
    .from("ops_execution_files")
    .select("id, file_path, file_name, file_size, mime_type, created_at")
    .eq("execution_id", executionId)
    .order("created_at");
  return (data as EvidenceFile[]) ?? [];
}

/**
 * Dekhne ke liye thodi der ka URL.
 *
 * 5 minute jaan-boojh kar. Itna kaafi hai kholne ke liye, aur agar wo
 * link kahin copy ho kar chala jaye to bahut jaldi bekaar ho jaata hai.
 */
export async function evidenceUrl(path: string): Promise<string | null> {
  const { data } = await supabase.storage
    .from(BUCKET)
    .createSignedUrl(path, 300);
  return data?.signedUrl ?? null;
}

/**
 * Saboot hataana — sirf checklist manage karne walon ke liye.
 *
 * Storage ki policy bhi yahi kehti hai (31_ops_evidence.sql). Jaanch
 * karne wale ko delete nahi diya: saboot ka matlab hi tab hai jab wo
 * baad me mitaya na ja sake.
 */
export async function deleteEvidence(f: EvidenceFile): Promise<void> {
  const { error } = await supabase.storage.from(BUCKET).remove([f.file_path]);
  if (error) throw new Error(error.message);
  await supabase.from("ops_execution_files").delete().eq("id", f.id);
}

function guessType(name: string): string {
  const ext = name.split(".").pop()?.toLowerCase();
  if (ext === "log" || ext === "txt") return "text/plain";
  if (ext === "csv") return "text/csv";
  if (ext === "json") return "application/json";
  return "";
}
