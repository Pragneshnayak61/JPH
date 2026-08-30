import vue from "@vitejs/plugin-vue";
// frappe-ui apna Vite plugin ship karta hai. Iske bina uske components ke
// `~icons/lucide/*` imports resolve nahi hote aur build fail ho jaati hai.
import frappeui from "frappe-ui/vite";
import path from "node:path";
import { defineConfig } from "vite";

export default defineConfig({
  plugins: [
    frappeui({ lucideIcons: true }),
    vue(),
  ],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
  optimizeDeps: {
    // frappe-ui built dist ke bajaye apna source ship karta hai, isliye
    // Vite ko uske andar ke deps pre-bundle karne dena padta hai.
    include: ["feather-icons", "showdown", "engine.io-client"],
  },
});
