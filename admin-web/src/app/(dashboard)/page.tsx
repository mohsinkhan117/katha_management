"use client";

import React from "react";
import Link from "next/link";
import {
  Building2,
  CreditCard,
  Users,
  Activity,
  FileText,
  ShieldCheck,
  Zap,
  Server,
  ArrowUpRight,
} from "lucide-react";

const stats = [
  { label: "Active Tenants", value: "18 Companies", change: "+3 this month", isPositive: true },
  { label: "Connected Distributors", value: "142 Seats", change: "89% active", isPositive: true },
  { label: "Platform GMV (MTD)", value: "Rs. 48.2M", change: "+16.4%", isPositive: true },
  { label: "PowerSync Replication", value: "99.98%", change: "Healthy (<50ms lag)", isPositive: true },
];

const adminModules = [
  {
    title: "Companies & Tenant Provisioning",
    href: "/companies",
    icon: Building2,
    desc: "Onboard new Company accounts, issue Company Admin credentials, and suspend or activate tenants.",
  },
  {
    title: "Subscriptions & Plan Quotas",
    href: "/subscriptions",
    icon: CreditCard,
    desc: "Manage Free vs. Premium tiers, set max distributor seat limits, and track billing cycles.",
  },
  {
    title: "Global Users & RBAC Directory",
    href: "/users",
    icon: Users,
    desc: "Audit Super Admins, Company Admins, and connected Field Distributors across all tenants.",
  },
  {
    title: "Platform Analytics & Sync Health",
    href: "/analytics",
    icon: Activity,
    desc: "Monitor Supabase + PowerSync replication telemetry, active tenants, and total platform GMV.",
  },
  {
    title: "Security & Audit Logs",
    href: "/audit-logs",
    icon: FileText,
    desc: "Review invite token brute-force alerts, tenant provisioning logs, and RLS policy events.",
  },
];

export default function SuperAdminDashboardPage() {
  return (
    <div className="max-w-7xl mx-auto space-y-6">
      {/* SaaS Infrastructure Header */}
      <div className="p-6 rounded-3xl bg-gradient-to-r from-slate-900 via-slate-900 to-emerald-950 border border-slate-800 text-white shadow-xl">
        <div className="flex items-center gap-2 text-xs font-semibold uppercase tracking-wider text-emerald-400 bg-emerald-950/80 border border-emerald-800/80 px-3 py-1 rounded-full w-fit">
          <Zap className="w-3.5 h-3.5 text-emerald-400" />
          Katha Multi-Tenant SaaS Control Plane
        </div>
        <h1 className="text-3xl font-extrabold mt-3 text-white tracking-tight">
          Super Admin Global Control
        </h1>
        <p className="text-slate-400 text-xs sm:text-sm mt-1 max-w-2xl">
          Provision tenant company databases, enforce distributor license seat quotas, and monitor live cross-tenant replication.
        </p>
      </div>

      {/* KPI Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {stats.map((s) => (
          <div key={s.label} className="p-4 bg-slate-900 border border-slate-800 rounded-2xl">
            <span className="text-xs text-slate-400 block">{s.label}</span>
            <div className="text-2xl font-bold text-white mt-1">{s.value}</div>
            <span className="text-[11px] font-semibold text-emerald-400 mt-1 block">
              {s.change}
            </span>
          </div>
        ))}
      </div>

      {/* Modules Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {adminModules.map((m) => {
          const Icon = m.icon;
          return (
            <Link
              key={m.href}
              href={m.href}
              className="p-5 bg-slate-900 rounded-2xl border border-slate-800 hover:border-emerald-500/60 transition group flex flex-col justify-between"
            >
              <div>
                <div className="w-9 h-9 rounded-xl bg-slate-800 text-emerald-400 flex items-center justify-center mb-3 group-hover:scale-105 transition-transform">
                  <Icon className="w-4 h-4" />
                </div>
                <h2 className="text-base font-semibold text-white group-hover:text-emerald-300 transition">
                  {m.title}
                </h2>
                <p className="text-xs text-slate-400 mt-1.5">{m.desc}</p>
              </div>
              <div className="flex items-center gap-1 text-xs text-emerald-400 font-semibold mt-4">
                Open Console
                <ArrowUpRight className="w-3.5 h-3.5" />
              </div>
            </Link>
          );
        })}
      </div>
    </div>
  );
}

