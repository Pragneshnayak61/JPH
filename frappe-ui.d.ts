// frappe-ui apna Vite plugin plain JS me ship karta hai, uske types nahi hain.
// Iske bina `vue-tsc -b` fail ho jaata hai — aur Cloudflare Pages wahi
// chalata hai (`npm run build` = vue-tsc -b && vite build).
declare module "frappe-ui/vite" {
  import type { PluginOption } from "vite";
  const frappeui: (options?: Record<string, unknown>) => PluginOption;
  export default frappeui;
}

declare module "frappe-ui/tailwind" {
  const preset: Record<string, unknown>;
  export default preset;
}
