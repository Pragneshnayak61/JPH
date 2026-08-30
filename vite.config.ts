import vue from "@vitejs/plugin-vue";
import frappeui from "frappe-ui/vite";
import path from "node:path";
import { defineConfig } from "vite";

export default defineConfig({
  plugins: [
    // frappe-ui ka plugin hum SIRF icons ke liye chahiye — uske bina uske
    // components ke `~icons/lucide/*` imports resolve nahi hote aur build
    // fail ho jaati hai.
    //
    // Baaki sab band kar diya, kyunki wo Frappe backend maan kar chalte hain
    // aur hamare paas wo hai hi nahi:
    //   frappeProxy    - Frappe server par proxy karta (yahan Supabase hai)
    //   jinjaBootData  - Frappe ke Jinja template se data uthata
    //   buildConfig    - Frappe ki site directory dhundhta; isi se build me
    //                    "No common_site_config.json found" aur "Could not
    //                    find build output directory" warnings aa rahi thi
    frappeui({
      lucideIcons: true,
      frappeProxy: false,
      jinjaBootData: false,
      buildConfig: false,
    }),
    vue(),
  ],
  resolve: {
    alias: {
      // import.meta.dirname, __dirname nahi — Vite ka naya config loader
      // __dirname ko support nahi karta aur warning deta hai.
      "@": path.resolve(import.meta.dirname, "./src"),
    },
  },
  optimizeDeps: {
    // frappe-ui built dist ke bajaye apna source ship karta hai, isliye
    // Vite ko uske andar ke deps pre-bundle karne dena padta hai.
    include: ["feather-icons", "showdown", "engine.io-client"],
  },
});
