"use client";

import React from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  LayoutDashboard,
  ShoppingBag,
  Package,
  BookOpen,
  Users,
  MapPin,
  Settings,
  ChevronLeft,
  ChevronRight,
  TrendingUp,
  X,
  LogOut,
  LogIn,
  Building2,
  FileSpreadsheet,
} from "lucide-react";
import { useUser } from "@stackframe/stack";
import { useTenant } from "@/context/TenantContext";

interface NavItem {
  label: string;
  href: string;
  icon: React.ElementType;
  badge?: string;
  badgeColor?: string;
}

const navItems: NavItem[] = [
  {
    label: "Dashboard",
    href: "/",
    icon: LayoutDashboard,
  },
  {
    label: "B2B Orders",
    href: "/orders",
    icon: ShoppingBag,
    badge: "8 New",
    badgeColor: "bg-blue-500/10 text-blue-600 border border-blue-200",
  },
  {
    label: "Product Catalog",
    href: "/products",
    icon: Package,
  },
  {
    label: "Parties & Khata",
    href: "/parties",
    icon: BookOpen,
  },
  {
    label: "Distributors",
    href: "/distributors",
    icon: Users,
    badge: "12 Active",
    badgeColor: "bg-emerald-500/10 text-emerald-700 border border-emerald-200",
  },
  {
    label: "Territories",
    href: "/territories",
    icon: MapPin,
  },
  {
    label: "Commercial Ledger",
    href: "/ledger",
    icon: FileSpreadsheet,
    badge: "Admin",
    badgeColor: "bg-emerald-500/10 text-emerald-700 border border-emerald-200",
  },
  {
    label: "Settings",
    href: "/settings",
    icon: Settings,
  },
];

interface SidebarProps {
  isCollapsed: boolean;
  setIsCollapsed: (collapsed: boolean) => void;
  isMobileOpen: boolean;
  setIsMobileOpen: (open: boolean) => void;
}

export function Sidebar({
  isCollapsed,
  setIsCollapsed,
  isMobileOpen,
  setIsMobileOpen,
}: SidebarProps) {
  const pathname = usePathname();
  const user = useUser();
  const { activeTenant, tenantData, isCustomTenant, hasAccess } = useTenant();

  const ordersCount = isCustomTenant && hasAccess
    ? tenantData?.orders?.length || 0
    : 8;

  const distributorsCount = isCustomTenant && hasAccess
    ? tenantData?.distributors?.length || 0
    : 12;

  const dynamicNavItems: NavItem[] = [
    {
      label: "Dashboard",
      href: "/",
      icon: LayoutDashboard,
    },
    {
      label: "B2B Orders",
      href: "/orders",
      icon: ShoppingBag,
      badge: ordersCount > 0 ? `${ordersCount} New` : undefined,
      badgeColor: "bg-blue-500/10 text-blue-400 border border-blue-500/30",
    },
    {
      label: "Product Catalog",
      href: "/products",
      icon: Package,
    },
    {
      label: "Parties & Khata",
      href: "/parties",
      icon: BookOpen,
    },
    {
      label: "Distributors",
      href: "/distributors",
      icon: Users,
      badge: distributorsCount > 0 ? `${distributorsCount} Active` : undefined,
      badgeColor: "bg-emerald-500/10 text-emerald-400 border border-emerald-500/30",
    },
    {
      label: "Territories",
      href: "/territories",
      icon: MapPin,
    },
    ...(hasAccess
      ? [
          {
            label: "Party Khata Ledger",
            href: "/ledger",
            icon: FileSpreadsheet,
            badge: "Expense",
            badgeColor: "bg-emerald-500/10 text-emerald-400 border border-emerald-500/30",
          },
        ]
      : []),
    {
      label: "Settings",
      href: "/settings",
      icon: Settings,
    },
  ];

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
          className="fixed inset-0 z-40 bg-slate-900/50 backdrop-blur-sm lg:hidden transition-opacity"
          aria-hidden="true"
        />
      )}

      {/* Sidebar Container */}
      <aside
        className={`fixed top-0 bottom-0 left-0 z-50 flex flex-col bg-slate-900 text-white border-r border-slate-800 transition-all duration-300 ease-in-out
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
            <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-blue-600 to-indigo-500 flex items-center justify-center shrink-0 shadow-lg shadow-blue-500/20">
              <Building2 className="w-5 h-5 text-white" />
            </div>
            {(!isCollapsed || isMobileOpen) && (
              <div className="flex flex-col min-w-0">
                <span className="font-bold text-white text-base tracking-tight truncate">
                  {activeTenant?.name || "Katha Portal"}
                </span>
                <span className="text-[11px] font-medium text-blue-400 uppercase tracking-wider">
                  @{activeTenant?.slug || "company"}
                </span>
              </div>
            )}
          </div>

          {/* Close button for mobile */}
          <button
            onClick={() => setIsMobileOpen(false)}
            className="p-1.5 rounded-lg text-slate-400 hover:text-white hover:bg-slate-800 lg:hidden"
            aria-label="Close navigation"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Navigation Items */}
        <nav className="flex-1 overflow-y-auto px-3 py-4 space-y-1.5 scrollbar-thin">
          <div
            className={`px-3 mb-2 text-[11px] font-semibold tracking-wider uppercase text-slate-400 transition-opacity ${
              isCollapsed && !isMobileOpen ? "opacity-0 h-0 overflow-hidden" : "opacity-100"
            }`}
          >
            Main Menu
          </div>

          {dynamicNavItems.map((item) => {
            const active = isRouteActive(item.href);
            const Icon = item.icon;

            return (
              <Link
                key={item.href}
                href={item.href}
                onClick={() => setIsMobileOpen(false)}
                className={`group flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-all relative ${
                  active
                    ? "bg-blue-600 text-white shadow-md shadow-blue-600/30"
                    : "text-slate-300 hover:text-white hover:bg-slate-800/70"
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
                  <span
                    className={`text-[10px] font-semibold px-2 py-0.5 rounded-full ${
                      item.badgeColor || "bg-slate-800 text-slate-300"
                    }`}
                  >
                    {item.badge}
                  </span>
                )}

                {/* Tooltip hint in collapsed mode */}
                {isCollapsed && !isMobileOpen && (
                  <div className="absolute left-full ml-3 px-2.5 py-1 bg-slate-800 text-white text-xs rounded-md shadow-lg opacity-0 pointer-events-none group-hover:opacity-100 transition-opacity whitespace-nowrap z-50">
                    {item.label}
                  </div>
                )}
              </Link>
            );
          })}
        </nav>

        {/* Live Sync Status Pill */}
        {(!isCollapsed || isMobileOpen) && (
          <div className="mx-3 mb-3 p-3 bg-slate-800/60 rounded-xl border border-slate-700/50">
            <div className="flex items-center gap-2">
              <span className="relative flex h-2.5 w-2.5">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-emerald-500"></span>
              </span>
              <span className="text-xs font-semibold text-slate-200">
                PowerSync Active
              </span>
            </div>
            <p className="text-[11px] text-slate-400 mt-1">
              Field distributor ledgers synced in real-time.
            </p>
          </div>
        )}

        {/* User Profile & Collapse Toggle Footer */}
        <div className="p-3 border-t border-slate-800 flex items-center justify-between gap-2">
          <Link
            href="/settings"
            className="flex items-center gap-3 min-w-0 flex-1 hover:opacity-80 transition"
            title="Company Profile Settings"
          >
            <div className="w-9 h-9 rounded-full bg-gradient-to-tr from-blue-500 to-indigo-600 text-white font-bold flex items-center justify-center text-xs shrink-0 ring-2 ring-slate-800">
              {activeTenant?.name
                ? activeTenant.name.split(" ").map((w) => w[0]).filter(Boolean).slice(0, 2).join("").toUpperCase()
                : "CA"}
            </div>
            {(!isCollapsed || isMobileOpen) && (
              <div className="flex flex-col min-w-0">
                <span className="text-sm font-semibold text-white truncate">
                  {user?.displayName || activeTenant?.name || "Company Admin"}
                </span>
                <span className="text-[11px] text-slate-400 truncate">
                  {user?.primaryEmail || activeTenant?.admin_email || "tenant@katha.com"}
                </span>
              </div>
            )}
          </Link>

          {(!isCollapsed || isMobileOpen) && (
            user ? (
              <Link
                href="/handler/sign-out"
                className="p-1.5 rounded-lg text-slate-400 hover:text-rose-400 hover:bg-slate-800 transition"
                title="Sign Out"
              >
                <LogOut className="w-4 h-4" />
              </Link>
            ) : (
              <Link
                href="/handler/sign-in"
                className="p-1.5 rounded-lg text-emerald-400 hover:text-emerald-300 hover:bg-slate-800 transition"
                title="Sign In"
              >
                <LogIn className="w-4 h-4" />
              </Link>
            )
          )}

          {/* Desktop Collapse / Expand Toggle Button */}
          <button
            onClick={() => setIsCollapsed(!isCollapsed)}
            className="hidden lg:flex p-1.5 rounded-lg text-slate-400 hover:text-white hover:bg-slate-800 transition"
            aria-label={isCollapsed ? "Expand sidebar" : "Collapse sidebar"}
            title={isCollapsed ? "Expand sidebar" : "Collapse sidebar"}
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

