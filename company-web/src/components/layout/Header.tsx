"use client";

import React from "react";
import { usePathname } from "next/navigation";
import {
  Menu,
  Search,
  Bell,
  RefreshCw,
  Building,
  ChevronDown,
  Sparkles,
} from "lucide-react";

interface HeaderProps {
  onToggleMobileSidebar: () => void;
  onToggleCollapse: () => void;
  isCollapsed: boolean;
}

const pageTitles: Record<string, { title: string; subtitle: string }> = {
  "/": {
    title: "Executive Dashboard",
    subtitle: "Real-time daily, weekly, and monthly commercial metrics",
  },
  "/orders": {
    title: "B2B Orders & Fulfillment",
    subtitle: "Incoming orders synced from field distributor mobile apps",
  },
  "/products": {
    title: "Product Master Catalog",
    subtitle: "Manage company SKU lines, packaging units, and price tiers",
  },
  "/parties": {
    title: "Parties & Khata Ledger",
    subtitle: "Centralized credit limits, receivables, and customer ledger books",
  },
  "/distributors": {
    title: "Distributor Network & Tokens",
    subtitle: "Issue 12-character onboarding tokens and monitor distributor sales",
  },
  "/territories": {
    title: "Territories & Field Zones",
    subtitle: "Geographical sales boundaries and distributor assignments",
  },
  "/settings": {
    title: "Company Settings",
    subtitle: "Business profile, invoice headers, and multi-tenant preferences",
  },
};

export function Header({
  onToggleMobileSidebar,
  onToggleCollapse,
  isCollapsed,
}: HeaderProps) {
  const pathname = usePathname();
  const currentMeta = pageTitles[pathname] || {
    title: "Company Portal",
    subtitle: "Katha Management B2B Operations",
  };

  return (
    <header className="sticky top-0 z-30 h-16 bg-white/90 backdrop-blur-md border-b border-slate-200 px-4 sm:px-6 flex items-center justify-between gap-4 transition-all">
      {/* Left: Mobile Toggle & Page Title */}
      <div className="flex items-center gap-3 min-w-0">
        <button
          onClick={onToggleMobileSidebar}
          className="p-2 rounded-xl text-slate-600 hover:text-slate-900 hover:bg-slate-100 lg:hidden"
          aria-label="Open mobile menu"
        >
          <Menu className="w-5 h-5" />
        </button>

        <div className="flex flex-col min-w-0">
          <div className="flex items-center gap-2">
            <h1 className="text-lg font-bold text-slate-900 tracking-tight truncate">
              {currentMeta.title}
            </h1>
            <span className="hidden sm:inline-flex items-center gap-1 text-[11px] font-semibold text-blue-700 bg-blue-50 border border-blue-200/60 px-2 py-0.5 rounded-full">
              <Sparkles className="w-3 h-3 text-blue-600" />
              Live Sync
            </span>
          </div>
          <p className="text-xs text-slate-500 truncate hidden md:block">
            {currentMeta.subtitle}
          </p>
        </div>
      </div>

      {/* Right: Search, Notifications, Tenant selector */}
      <div className="flex items-center gap-2 sm:gap-3">
        {/* Search Bar */}
        <div className="relative hidden md:block w-56 lg:w-72">
          <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" />
          <input
            type="text"
            placeholder="Search orders, parties, SKUs..."
            className="w-full pl-9 pr-3 py-1.5 text-xs bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 text-slate-800 placeholder-slate-400 transition"
          />
        </div>

        {/* Tenant Branch Selector */}
        <div className="hidden sm:flex items-center gap-2 px-3 py-1.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-medium text-slate-700">
          <Building className="w-3.5 h-3.5 text-slate-500" />
          <span className="truncate max-w-[110px]">Lahore Central</span>
          <ChevronDown className="w-3 h-3 text-slate-400" />
        </div>

        {/* Sync Status Button */}
        <button
          title="Manual Force Sync with PowerSync & Supabase"
          className="p-2 rounded-xl text-slate-600 hover:text-slate-900 hover:bg-slate-100 transition relative"
        >
          <RefreshCw className="w-4 h-4" />
        </button>

        {/* Notification Bell */}
        <button
          title="Notifications"
          className="p-2 rounded-xl text-slate-600 hover:text-slate-900 hover:bg-slate-100 transition relative"
        >
          <Bell className="w-4 h-4" />
          <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-rose-500 rounded-full ring-2 ring-white"></span>
        </button>
      </div>
    </header>
  );
}

