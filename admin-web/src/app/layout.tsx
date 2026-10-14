import type { Metadata } from "next";
import { StackProvider, StackTheme } from "@stackframe/stack";
import { stackServerApp } from "../stack";
import "./globals.css";

export const metadata: Metadata = {
  title: "Katha Management — Super Admin Control Plane",
  description:
    "Platform Super Admin Console for provisioning Company tenants, managing subscriptions, and monitoring multi-tenant health.",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="antialiased min-h-screen">
        <StackProvider app={stackServerApp}>
          <StackTheme>
            {children}
          </StackTheme>
        </StackProvider>
      </body>
    </html>
  );
}
