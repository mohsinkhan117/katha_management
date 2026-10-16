import React from "react";
import { AdminDashboardShell } from "@/components/layout/AdminDashboardShell";
import { stackServerApp } from "@/stack";
import { redirect } from "next/navigation";

export default async function AdminDashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const user = await stackServerApp.getUser();
  if (!user) {
    redirect("/admin/handler/sign-in");
  }

  return <AdminDashboardShell>{children}</AdminDashboardShell>;
}

