import "server-only";
import { StackServerApp } from "@stackframe/stack";

const projectId =
  process.env.NEXT_PUBLIC_STACK_PROJECT_ID ||
  process.env.STACK_PROJECT_ID ||
  process.env.NEXT_PUBLIC_HEXCLAVE_PROJECT_ID ||
  "386520db-cfab-4755-a7be-99de4cdeca8a";

const secretServerKey =
  process.env.STACK_SECRET_SERVER_KEY ||
  process.env.HEXCLAVE_SECRET_SERVER_KEY ||
  "ssk_10kbqx0cm1770x2raprzebr91mpd3k49bw3t92hmtg2gg";

export const stackServerApp = new StackServerApp({
  tokenStore: "nextjs-cookie",
  projectId,
  secretServerKey,
  urls: {
    signIn: "/admin/handler/sign-in",
    signUp: "/admin/handler/sign-up",
    afterSignIn: "/admin",
    afterSignUp: "/admin",
    afterSignOut: "/admin/handler/sign-in",
  },
});
