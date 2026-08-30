import { createRouter, createWebHistory } from "vue-router";
import type { RouteRecordRaw } from "vue-router";

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
