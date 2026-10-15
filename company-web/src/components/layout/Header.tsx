"use client";

import React, { useState } from "react";
import { usePathname } from "next/navigation";
import {
  Menu,
  Search,
  Bell,
  RefreshCw,
  Building,
  ChevronDown,
  Sparkles,
  Check,
} from "lucide-react";
import { useTenant } from "@/context/TenantContext";

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
  const { activeTenant, availableTenants, switchTenant } = useTenant();
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);

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

      {/* Right: Search, Notifications, Dynamic Tenant selector */}
      <div className="flex items-center gap-2 sm:gap-3">
        {/* Search Bar */}
        <div className="relative hidden md:block w-48 lg:w-64">
          <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" />
          <input
            type="text"
            placeholder="Search orders, parties, SKUs..."
            className="w-full pl-9 pr-3 py-1.5 text-xs bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 text-slate-800 placeholder-slate-400 transition"
          />
        </div>

        {/* Tenant Indicator / Selector */}
        <div className="relative">
          {availableTenants.length > 1 ? (
            <>
              <button
                onClick={() => setIsDropdownOpen(!isDropdownOpen)}
                className="flex items-center gap-2 px-3 py-1.5 bg-slate-50 hover:bg-slate-100 border border-slate-200 rounded-xl text-xs font-semibold text-slate-800 transition"
              >
                <Building className="w-3.5 h-3.5 text-blue-600 shrink-0" />
                <span className="truncate max-w-[130px]">
                  {activeTenant?.name || "Select Tenant"}
                </span>
                <ChevronDown className="w-3 h-3 text-slate-400" />
              </button>

              {isDropdownOpen && (
                <div className="absolute right-0 mt-2 w-64 bg-white border border-slate-200 rounded-2xl shadow-xl py-2 z-50 animate-in fade-in">
                  <div className="px-3 py-1.5 text-[10px] font-bold text-slate-400 uppercase tracking-wider">
                    Switch Organization
                  </div>
                  <div className="max-h-60 overflow-y-auto">
                    {availableTenants.map((tenant) => {
                      const isSelected = activeTenant?.id === tenant.id;
                      return (
                        <button
                          key={tenant.id}
                          onClick={() => {
                            switchTenant(tenant.slug);
                            setIsDropdownOpen(false);
                          }}
                          className={`w-full px-3 py-2 text-left flex items-center justify-between text-xs hover:bg-slate-50 transition ${
                            isSelected ? "bg-blue-50/60 font-bold text-blue-700" : "text-slate-700"
                          }`}
                        >
                          <div className="truncate pr-2">
                            <div className="truncate font-semibold">{tenant.name}</div>
                            <div className="text-[10px] text-slate-400 font-mono">@{tenant.slug}</div>
                          </div>
                          {isSelected && <Check className="w-4 h-4 text-blue-600 shrink-0" />}
                        </button>
                      );
                    })}
                  </div>
                </div>
              )}
            </>
          ) : (
            <div className="flex items-center gap-2 px-3 py-1.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold text-slate-800">
              <Building className="w-3.5 h-3.5 text-blue-600 shrink-0" />
              <span className="truncate max-w-[140px]">
                {activeTenant?.name || "Company Portal"}
              </span>
              <span className="w-2 h-2 rounded-full bg-emerald-500 inline-block" title="Isolated Tenant" />
            </div>
          )}
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
