import type { Metadata } from "next";
import { StackProvider, StackTheme } from "@stackframe/stack";
import { stackServerApp } from "../stack";
import { TenantProvider } from "@/context/TenantContext";
import "./globals.css";

export const metadata: Metadata = {
  title: "Katha Management — Company Admin Portal",
  description:
    "Company Admin Dashboard for managing products, territories, distributor invite tokens, and B2B orders.",
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
            <TenantProvider>
              {children}
            </TenantProvider>
          </StackTheme>
        </StackProvider>
      </body>
    </html>
  );
}
