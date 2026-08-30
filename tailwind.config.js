import typography from "@tailwindcss/typography";
import frappeUIPreset from "frappe-ui/tailwind";

/** @type {import('tailwindcss').Config} */
export default {
  presets: [frappeUIPreset],
  content: [
    "./index.html",
    "./src/**/*.{vue,js,ts,jsx,tsx}",
    // frappe-ui apna source ship karta hai (built dist nahi), isliye uske
    // components ko yahan scan karna zaroori hai — warna unki classes
    // final CSS me aayengi hi nahi aur design toota hua dikhega.
    "./node_modules/frappe-ui/src/**/*.{vue,js,ts,jsx,tsx}",
  ],
  safelist: [{ pattern: /!(text|bg)-/, variants: ["hover", "active"] }],
  theme: {
    extend: {
      height: { 18: "68px" },
      margin: { 3.5: "14px" },
      padding: { 2.5: "10px", 3.5: "14px" },
    },
  },
  plugins: [typography],
};
