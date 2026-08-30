import { supabase } from "./supabase";

/**
 * frappe-ui ke TextEditor ka image upload.
 *
 * Iske bina toolbar ka image button "failed to upload" deta hai — uska
 * default upload Frappe ke server (`/api/method/upload_file`) ko
 * dhoondhta hai, jo hamare paas hai hi nahi. Ye function usi jagah
 * Supabase Storage me daal deta hai.
 *
 * Return shape frappe-ui ka apna hai: { file_name, file_size, file_url }.
 */
export type UploadedFile = {
  file_name: string;
  file_size: number;
  file_url: string;
};

const BUCKET = "attachments";
const MAX_BYTES = 5 * 1024 * 1024;
const ALLOWED = ["image/png", "image/jpeg", "image/gif", "image/webp"];

export async function uploadImage(file: File): Promise<UploadedFile> {
  // Ye do check bucket par bhi lage hain (server side). Yahan sirf
  // isliye ki user ko saaf message mile — server ka error tez hota hai
  // par uska matlab samajhna mushkil.
  if (!ALLOWED.includes(file.type)) {
    throw new Error("Only PNG, JPG, GIF or WebP images can be attached.");
  }
  if (file.size > MAX_BYTES) {
    throw new Error("That image is over 5 MB. Please attach a smaller one.");
  }

  // Naam khud banate hain, user ka nahi lete. User ke file name me
  // slash ya "../" ho sakta hai, aur do log ek hi naam bhej dein to
  // ek doosre ki file overwrite ho jaati.
  const ext = (file.name.split(".").pop() || "png").toLowerCase().slice(0, 5);
  const path = `${crypto.randomUUID()}.${ext}`;

  const { error } = await supabase.storage
    .from(BUCKET)
    .upload(path, file, { contentType: file.type, upsert: false });
  if (error) throw new Error(error.message);

  const { data } = supabase.storage.from(BUCKET).getPublicUrl(path);
  return {
    file_name: file.name,
    file_size: file.size,
    file_url: data.publicUrl,
  };
}
