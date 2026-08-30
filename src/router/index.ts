import { useAuthStore } from "@/stores/auth";
import { createRouter, createWebHistory } from "vue-router";
import type { RouteRecordRaw } from "vue-router";

// Bina iske `to.meta.requiresAuth` ka type `unknown` rehta hai.
declare module "vue-router" {
  interface RouteMeta {
    requiresAuth?: boolean;
    staff?: boolean;
  }
}

/**
 * Route meta:
 *   requiresAuth  - login zaroori hai
 *   staff         - sirf agent/admin
 *
 * NOTE: Frappe Helpdesk me `public: true` ka matlab "bina login" NAHI tha —
 * wo sirf "customer wala portal" batata tha, aur guard phir bhi sabko login
 * par bhej deta tha. Yahan wo confusion nahi hai: jis route par
 * `requiresAuth` nahi likha, wo sach me bina login khulta hai.
 */
const routes: RouteRecordRaw[] = [
  // ---------------------------------------------------------- public
  {
    path: "/",
    name: "GuestTicket",
    component: () => import("@/pages/GuestTicket.vue"),
  },
  {
    path: "/submitted/:token",
    name: "TicketSubmitted",
    component: () => import("@/pages/TicketSubmitted.vue"),
    props: true,
  },
  {
    path: "/login",
    name: "Login",
    component: () => import("@/pages/Login.vue"),
  },

  // ---------------------------------------------------------- staff
  {
    path: "/admin",
    component: () => import("@/layouts/AdminLayout.vue"),
    meta: { requiresAuth: true, staff: true },
    children: [
      {
        path: "",
        name: "Dashboard",
        component: () => import("@/pages/admin/Dashboard.vue"),
      },
      {
        path: "tickets/:id",
        name: "TicketDetail",
        component: () => import("@/pages/admin/TicketDetail.vue"),
        props: true,
      },
      {
        path: "agents",
        name: "Agents",
        component: () => import("@/pages/admin/Agents.vue"),
      },
    ],
  },

  { path: "/:pathMatch(.*)*", redirect: "/" },
];

export const router = createRouter({
  history: createWebHistory(),
  routes,
});

/**
 * Guard. Pehle ye likha hi nahi gaya tha — routes par `requiresAuth: true`
 * pada tha par use padhne wala koi code nahi tha, isliye /admin bina login
 * ke khul jaata tha. (RLS ki wajah se data nahi aata tha, par page khulta tha.)
 */
router.beforeEach(async (to) => {
  const auth = useAuthStore();

  // Page reload par Supabase ka session async load hota hai. Iska intezaar
  // na karein to guard session milne se PEHLE chal jaata hai aur logged-in
  // user ko bhi login page par bhej deta hai.
  if (!auth.ready) await auth.init();

  if (!to.meta.requiresAuth) {
    // Logged-in staff ko login page par rukne ka koi matlab nahi.
    if (to.name === "Login" && auth.isLoggedIn && auth.isStaff) {
      return { name: "Dashboard" };
    }
    return true;
  }

  if (!auth.isLoggedIn) {
    return { name: "Login", query: { next: to.fullPath } };
  }

  // Customer login kar sakta hai, par agent desk uske liye nahi hai.
  if (to.meta.staff && !auth.isStaff) {
    return { name: "GuestTicket" };
  }

  return true;
});
