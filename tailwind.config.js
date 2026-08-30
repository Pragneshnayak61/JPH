import typography from "@tailwindcss/typography";
import frappeUIPreset from "frappe-ui/tailwind";

/** @type {import('tailwindcss').Config} */
export default {
  presets: [frappeUIPreset],
  content: [
    "./index.html",
    "./src/**/*.{vue,js,ts,jsx,tsx}",
    // frappe-ui apna source ship karta hai (built dist nahi), isliye uske
    // components ko yahan scan karna zaroori hai â€” warna unki classes
    // final CSS me aayengi hi nahi aur design toota hua dikhega.
    "./node_modules/frappe-ui/src/**/*.{vue,js,ts,jsx,tsx}",
  ],
  // NOTE: yahan pehle safelist thi:
  //   safelist: [{ pattern: /!(text|bg)-/, variants: ["hover", "active"] }]
  // Wo Frappe Helpdesk se copy ki thi, par hamare liye bekaar hai —
  // frappe-ui me `!text-`/`!bg-` sirf 5 jagah, aur sab STATIC strings me.
  // Unhe upar wala content glob pehle hi scan kar leta hai.
  // Safelist har color x hover/active ki hazaaron classes bana rahi thi.
  theme: {
    extend: {
      height: { 18: "68px" },
      margin: { 3.5: "14px" },
      padding: { 2.5: "10px", 3.5: "14px" },
    },
  },
  plugins: [typography],
};
