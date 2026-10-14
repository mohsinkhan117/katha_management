import React from "react";
import { AdminDashboardShell } from "@/components/layout/AdminDashboardShell";

export default function AdminDashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <AdminDashboardShell>{children}</AdminDashboardShell>;
}

