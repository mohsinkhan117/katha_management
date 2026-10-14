"use client";

import React from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  ShieldAlert,
  Building2,
  CreditCard,
  Users,
  Activity,
  FileText,
  ChevronLeft,
  ChevronRight,
  X,
  Gauge,
  LogOut,
} from "lucide-react";

interface NavItem {
  label: string;
  href: string;
  icon: React.ElementType;
  badge?: string;
}

const navItems: NavItem[] = [
  {
    label: "Control Plane",
    href: "/",
    icon: Gauge,
  },
  {
    label: "Companies & Tenants",
    href: "/companies",
    icon: Building2,
    badge: "18",
  },
  {
    label: "Subscriptions",
    href: "/subscriptions",
    icon: CreditCard,
  },
  {
    label: "Global Users & RBAC",
    href: "/users",
    icon: Users,
  },
  {
    label: "Platform Analytics",
    href: "/analytics",
    icon: Activity,
  },
  {
    label: "Security Audit Logs",
    href: "/audit-logs",
    icon: FileText,
  },
];

interface AdminSidebarProps {
  isCollapsed: boolean;
  setIsCollapsed: (collapsed: boolean) => void;
  isMobileOpen: boolean;
  setIsMobileOpen: (open: boolean) => void;
}

export function AdminSidebar({
  isCollapsed,
  setIsCollapsed,
  isMobileOpen,
  setIsMobileOpen,
}: AdminSidebarProps) {
  const pathname = usePathname();

  const isRouteActive = (href: string) => {
    if (href === "/") {
      return pathname === "/" || pathname === "";
    }
    return pathname.startsWith(href);
  };

  return (
    <>
      {/* Mobile Backdrop */}
      {isMobileOpen && (
        <div
          onClick={() => setIsMobileOpen(false)}
          className="fixed inset-0 z-40 bg-black/60 backdrop-blur-sm lg:hidden"
          aria-hidden="true"
        />
      )}

      {/* Sidebar Container */}
      <aside
        className={`fixed top-0 bottom-0 left-0 z-50 flex flex-col bg-slate-950 text-white border-r border-slate-800 transition-all duration-300 ease-in-out
          ${isCollapsed ? "lg:w-20" : "lg:w-64"}
          ${
            isMobileOpen
              ? "translate-x-0 w-72"
              : "-translate-x-full lg:translate-x-0"
          }
        `}
      >
        {/* Brand / Header */}
        <div className="h-16 flex items-center justify-between px-4 border-b border-slate-800">
          <div className="flex items-center gap-3 overflow-hidden">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-emerald-600 to-teal-500 flex items-center justify-center shrink-0 shadow-lg shadow-emerald-500/20">
              <ShieldAlert className="w-5 h-5 text-white" />
            </div>
            {(!isCollapsed || isMobileOpen) && (
              <div className="flex flex-col min-w-0">
                <span className="font-bold text-white text-base tracking-tight truncate">
                  Katha SaaS
                </span>
                <span className="text-[11px] font-medium text-emerald-400 uppercase tracking-wider">
                  Super Admin
                </span>
              </div>
            )}
          </div>

          <button
            onClick={() => setIsMobileOpen(false)}
            className="p-1.5 rounded-lg text-slate-400 hover:text-white hover:bg-slate-900 lg:hidden"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Navigation */}
        <nav className="flex-1 overflow-y-auto px-3 py-4 space-y-1.5">
          <div
            className={`px-3 mb-2 text-[11px] font-semibold tracking-wider uppercase text-slate-500 transition-opacity ${
              isCollapsed && !isMobileOpen ? "opacity-0 h-0 overflow-hidden" : "opacity-100"
            }`}
          >
            SaaS Infrastructure
          </div>

          {navItems.map((item) => {
            const active = isRouteActive(item.href);
            const Icon = item.icon;

            return (
              <Link
                key={item.href}
                href={item.href}
                onClick={() => setIsMobileOpen(false)}
                className={`group flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-all relative ${
                  active
                    ? "bg-emerald-600 text-white shadow-md shadow-emerald-600/30"
                    : "text-slate-300 hover:text-white hover:bg-slate-900"
                }`}
                title={isCollapsed && !isMobileOpen ? item.label : undefined}
              >
                <Icon
                  className={`w-5 h-5 shrink-0 transition-transform group-hover:scale-105 ${
                    active ? "text-white" : "text-slate-400 group-hover:text-slate-200"
                  }`}
                />

                {(!isCollapsed || isMobileOpen) && (
                  <span className="truncate flex-1">{item.label}</span>
                )}

                {(!isCollapsed || isMobileOpen) && item.badge && (
                  <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-emerald-500/10 text-emerald-400 border border-emerald-500/30">
                    {item.badge}
                  </span>
                )}

                {isCollapsed && !isMobileOpen && (
                  <div className="absolute left-full ml-3 px-2.5 py-1 bg-slate-800 text-white text-xs rounded-md shadow-lg opacity-0 pointer-events-none group-hover:opacity-100 transition-opacity whitespace-nowrap z-50">
                    {item.label}
                  </div>
                )}
              </Link>
            );
          })}
        </nav>

        {/* Footer with collapse toggle */}
        <div className="p-3 border-t border-slate-800 flex items-center justify-between gap-2">
          <Link
            href="/handler/account-settings"
            className="flex items-center gap-3 min-w-0 flex-1 hover:opacity-80 transition"
          >
            <div className="w-9 h-9 rounded-full bg-slate-800 text-emerald-400 font-bold flex items-center justify-center text-xs shrink-0 ring-1 ring-emerald-500/40">
              SA
            </div>
            {(!isCollapsed || isMobileOpen) && (
              <div className="flex flex-col min-w-0">
                <span className="text-sm font-semibold text-white truncate">
                  Platform Root
                </span>
                <span className="text-[11px] text-slate-400 truncate">
                  ops@katha.com
                </span>
              </div>
            )}
          </Link>

          {(!isCollapsed || isMobileOpen) && (
            <Link
              href="/handler/sign-out"
              className="p-1.5 rounded-lg text-slate-400 hover:text-rose-400 hover:bg-slate-900 transition"
              title="Sign Out"
            >
              <LogOut className="w-4 h-4" />
            </Link>
          )}

          <button
            onClick={() => setIsCollapsed(!isCollapsed)}
            className="hidden lg:flex p-1.5 rounded-lg text-slate-400 hover:text-white hover:bg-slate-900 transition"
            aria-label={isCollapsed ? "Expand sidebar" : "Collapse sidebar"}
          >
            {isCollapsed ? (
              <ChevronRight className="w-5 h-5" />
            ) : (
              <ChevronLeft className="w-5 h-5" />
            )}
          </button>
        </div>
      </aside>
    </>
  );
}

