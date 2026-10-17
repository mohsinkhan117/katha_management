import React from "react";
import { DashboardShell } from "@/components/layout/DashboardShell";
import { stackServerApp } from "@/stack";
import { redirect } from "next/navigation";

export const dynamic = "force-dynamic";

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const user = await stackServerApp.getUser();
  if (!user) {
    redirect("/login");
  }

  return <DashboardShell>{children}</DashboardShell>;
}

