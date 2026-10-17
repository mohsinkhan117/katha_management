"use client";

import React, { useState } from "react";
import Link from "next/link";
import { ShieldAlert, Clock, Sparkles, LogOut } from "lucide-react";
import { Sidebar } from "./Sidebar";
import { Header } from "./Header";
import { useTenant } from "@/context/TenantContext";

interface DashboardShellProps {
  children: React.ReactNode;
}

export function DashboardShell({ children }: DashboardShellProps) {
  const [isCollapsed, setIsCollapsed] = useState(false);
  const [isMobileOpen, setIsMobileOpen] = useState(false);
  const { activeTenant, isDeactivated, deactivationReason } = useTenant();

  const isFreeTrial = activeTenant?.plan_tier === "free_trial";
  const daysRemaining = activeTenant?.days_remaining;

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 flex">
      {/* Global Persistent Sidebar */}
      <Sidebar
        isCollapsed={isCollapsed}
        setIsCollapsed={setIsCollapsed}
        isMobileOpen={isMobileOpen}
        setIsMobileOpen={setIsMobileOpen}
      />

      {/* Main Content Area */}
      <div
        className={`flex-1 flex flex-col min-h-screen transition-all duration-300 ease-in-out ${
          isCollapsed ? "lg:pl-20" : "lg:pl-64"
        }`}
      >
        {/* Global Header */}
        <Header
          isCollapsed={isCollapsed}
          onToggleCollapse={() => setIsCollapsed(!isCollapsed)}
          onToggleMobileSidebar={() => setIsMobileOpen(!isMobileOpen)}
        />

        {/* 1-Month Free Tier Status Banner */}
        {!isDeactivated && isFreeTrial && (
          <div className="bg-gradient-to-r from-emerald-900 via-emerald-800 to-teal-900 text-white px-4 sm:px-6 py-2.5 text-xs flex flex-wrap items-center justify-between gap-2 border-b border-emerald-700/60">
            <div className="flex items-center gap-2">
              <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-emerald-500/20 border border-emerald-400/40 text-emerald-200 font-bold uppercase tracking-wider text-[10px]">
                <Sparkles className="w-3 h-3 text-emerald-300" />
                1-Month Free Tier Active
              </span>
              <span className="text-emerald-100 font-medium">
                Your sign-up activated a 30-day Free Trial for{" "}
                <strong className="text-white">{activeTenant?.name}</strong>.
              </span>
            </div>
            <div className="flex items-center gap-2 font-mono font-bold text-amber-300">
              <Clock className="w-3.5 h-3.5" />
              <span>
                {daysRemaining !== null && daysRemaining !== undefined
                  ? `${daysRemaining} day${daysRemaining === 1 ? "" : "s"} remaining before automatic deactivation`
                  : "30 days trial"}
              </span>
            </div>
          </div>
        )}

        {/* Dynamic Page Content or Deactivated Lock Screen */}
        <main className="flex-1 p-4 sm:p-6 lg:p-8 overflow-y-auto">
          {isDeactivated ? (
            <div className="min-h-[72vh] flex items-center justify-center p-4">
              <div className="max-w-lg w-full bg-white border-2 border-rose-200 rounded-3xl p-8 text-center shadow-xl space-y-5">
                <div className="w-16 h-16 rounded-2xl bg-rose-50 border border-rose-200 text-rose-600 flex items-center justify-center mx-auto shadow-sm">
                  <ShieldAlert className="w-8 h-8" />
                </div>
                <div className="space-y-2">
                  <span className="inline-block px-3 py-1 rounded-full bg-rose-100 text-rose-700 text-[11px] font-bold uppercase tracking-wider">
                    Tenant Deactivated
                  </span>
                  <h2 className="text-2xl font-extrabold text-slate-900">
                    {activeTenant?.is_expired
                      ? "1-Month Free Tier Expired"
                      : "Company Account Deactivated"}
                  </h2>
                  <p className="text-xs sm:text-sm text-slate-600 leading-relaxed">
                    {deactivationReason ||
                      "Your 1-month Free Tier period has ended and this company tenant has been automatically deactivated. Please contact the Platform Super Admin to upgrade your plan or reactivate your tenant."}
                  </p>
                </div>

                <div className="bg-slate-50 border border-slate-200 rounded-2xl p-4 text-left text-xs space-y-1.5">
                  <div className="flex justify-between">
                    <span className="text-slate-500">Company Tenant:</span>
                    <span className="font-bold text-slate-900">{activeTenant?.name}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-500">Admin Email:</span>
                    <span className="font-mono text-slate-700">{activeTenant?.admin_email}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-500">Plan Tier:</span>
                    <span className="uppercase font-bold text-rose-600">
                      {activeTenant?.plan_tier === "free_trial" ? "Free Tier (1 Month)" : activeTenant?.plan_tier}
                    </span>
                  </div>
                  {activeTenant?.expires_at && (
                    <div className="flex justify-between">
                      <span className="text-slate-500">Expired On:</span>
                      <span className="font-mono text-slate-700">
                        {new Date(activeTenant.expires_at).toLocaleDateString()}
                      </span>
                    </div>
                  )}
                </div>

                <div className="pt-2 flex flex-wrap items-center justify-center gap-3">
                  <Link
                    href="/handler/sign-out"
                    className="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-slate-900 hover:bg-slate-800 text-white text-xs font-bold transition"
                  >
                    <LogOut className="w-4 h-4" />
                    Sign Out / Switch Account
                  </Link>
                </div>
              </div>
            </div>
          ) : (
            children
          )}
        </main>
      </div>
    </div>
  );
}

