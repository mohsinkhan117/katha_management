import "server-only";
import { StackServerApp } from "@stackframe/stack";

export const stackServerApp = new StackServerApp({
  tokenStore: "nextjs-cookie",
  urls: {
    signIn: "/admin/handler/sign-in",
    signUp: "/admin/handler/sign-up",
    afterSignIn: "/admin",
    afterSignUp: "/admin",
    afterSignOut: "/admin/handler/sign-in",
  },
});
