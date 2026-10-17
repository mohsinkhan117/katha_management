import React from "react";
import { AdminDashboardShell } from "@/components/layout/AdminDashboardShell";
import { stackServerApp } from "@/stack";
import { redirect } from "next/navigation";

export const dynamic = "force-dynamic";

export default async function AdminDashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const user = await stackServerApp.getUser();
  if (!user) {
    redirect("/login");
  }

  return <AdminDashboardShell>{children}</AdminDashboardShell>;
}

