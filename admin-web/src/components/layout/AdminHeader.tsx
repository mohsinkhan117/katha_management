"use client";

import React from "react";
import { usePathname } from "next/navigation";
import { Menu, Search, Shield, Bell, Terminal } from "lucide-react";

interface AdminHeaderProps {
  onToggleMobileSidebar: () => void;
}

const titles: Record<string, string> = {
  "/": "Multi-Tenant SaaS Control Plane",
  "/companies": "Company Tenant Provisioning",
  "/subscriptions": "Subscription & Quota Management",
  "/users": "Global RBAC & Identity Directory",
  "/analytics": "Platform GMV & Replication Telemetry",
  "/audit-logs": "Security & RLS Audit Logs",
};

export function AdminHeader({ onToggleMobileSidebar }: AdminHeaderProps) {
  const pathname = usePathname();
  const currentTitle = titles[pathname] || "Super Admin Console";

  return (
    <header className="sticky top-0 z-30 h-16 bg-slate-900/90 backdrop-blur-md border-b border-slate-800 px-4 sm:px-6 flex items-center justify-between gap-4">
      <div className="flex items-center gap-3">
        <button
          onClick={onToggleMobileSidebar}
          className="p-2 rounded-xl text-slate-400 hover:text-white hover:bg-slate-800 lg:hidden"
        >
          <Menu className="w-5 h-5" />
        </button>
        <div>
          <h1 className="text-base sm:text-lg font-bold text-white tracking-tight">
            {currentTitle}
          </h1>
          <span className="text-[11px] text-emerald-400 font-mono hidden sm:inline-block">
            Production Cluster • us-east-1
          </span>
        </div>
      </div>

      <div className="flex items-center gap-3">
        <div className="relative hidden md:block w-64">
          <Search className="w-4 h-4 text-slate-500 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" />
          <input
            type="text"
            placeholder="Search tenant slug, company, user..."
            className="w-full pl-9 pr-3 py-1.5 text-xs bg-slate-950 border border-slate-800 rounded-xl text-slate-200 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
          />
        </div>

        <button className="p-2 rounded-xl text-slate-400 hover:text-white hover:bg-slate-800">
          <Bell className="w-4 h-4" />
        </button>
      </div>
    </header>
  );
}

