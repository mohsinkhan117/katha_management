"use client";

import React from "react";
import { Building2, Shield, Receipt, Users, Database } from "lucide-react";

import { useTenant } from "@/context/TenantContext";
import { AlertTriangle } from "lucide-react";

export default function CompanySettingsPage() {
  const { activeTenant, tenantData, hasAccess, isCustomTenant } = useTenant();

  const maxSeats = activeTenant?.max_distributors || 25;
  const usedSeats = isCustomTenant
    ? tenantData?.distributors?.length || 0
    : 12;
  const seatPercent = Math.min(100, Math.round((usedSeats / maxSeats) * 100));

  return (
    <div className="max-w-5xl mx-auto space-y-6">
      {/* No Access / Demo Banner */}
      {!hasAccess && (
        <div className="p-4 bg-amber-50 border border-amber-200 rounded-2xl flex items-start gap-3 text-amber-900 text-xs">
          <AlertTriangle className="w-5 h-5 text-amber-600 shrink-0 mt-0.5" />
          <div>
            <div className="font-bold text-sm">Demo / Sandbox Mode (No Active Tenant)</div>
            <p className="text-amber-700 mt-0.5">
              Your account is not linked to an active company tenant. Displaying simulated company settings.
            </p>
          </div>
        </div>
      )}

      <div>
        <h1 className="text-2xl font-extrabold text-slate-900 tracking-tight">
          Company Settings & Configuration
        </h1>
        <p className="text-xs sm:text-sm text-slate-500 mt-1">
          {isCustomTenant
            ? `Manage settings and distributor quota exclusively for ${activeTenant?.name}.`
            : "Manage your enterprise profile, billing headers, distributor seat limits, and database synchronization."}
        </p>
      </div>

      <div className="space-y-6">
        {/* Company Profile Card */}
        <div className="bg-white rounded-2xl border border-slate-200 p-6 shadow-sm space-y-4">
          <div className="flex items-center gap-3 pb-3 border-b border-slate-100">
            <div className="w-8 h-8 rounded-lg bg-blue-50 text-blue-600 flex items-center justify-center">
              <Building2 className="w-4 h-4" />
            </div>
            <div>
              <h2 className="text-base font-bold text-slate-900">
                Company Profile & Commercial Identity
              </h2>
              <p className="text-xs text-slate-500">
                This appears on distributor order invoices and PDF ledger statements.
              </p>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-xs">
            <div>
              <label className="font-semibold text-slate-700 block mb-1">Company Registered Name</label>
              <input
                type="text"
                defaultValue={activeTenant?.name || "Apex Agro Chemical Ltd."}
                key={activeTenant?.name}
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
              />
            </div>
            <div>
              <label className="font-semibold text-slate-700 block mb-1">Organization Slug</label>
              <input
                type="text"
                defaultValue={activeTenant?.slug || "apex-agro"}
                key={activeTenant?.slug}
                disabled
                className="w-full px-3 py-2 bg-slate-100 border border-slate-200 rounded-xl text-slate-500 focus:outline-none font-mono cursor-not-allowed"
              />
            </div>
            <div>
              <label className="font-semibold text-slate-700 block mb-1">Primary Admin Email</label>
              <input
                type="email"
                defaultValue={activeTenant?.admin_email || "admin@apexagro.com"}
                key={activeTenant?.admin_email}
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
              />
            </div>
            <div>
              <label className="font-semibold text-slate-700 block mb-1">Headquarters Phone</label>
              <input
                type="text"
                defaultValue={activeTenant?.phone || "+92 42 35889900"}
                key={activeTenant?.phone}
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
              />
            </div>
          </div>
        </div>

        {/* Subscription & Seat Allocation */}
        <div className="bg-white rounded-2xl border border-slate-200 p-6 shadow-sm space-y-4">
          <div className="flex items-center justify-between pb-3 border-b border-slate-100">
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-lg bg-emerald-50 text-emerald-600 flex items-center justify-center">
                <Users className="w-4 h-4" />
              </div>
              <div>
                <h2 className="text-base font-bold text-slate-900">
                  Plan Quota & Distributor Seats
                </h2>
                <p className="text-xs text-slate-500">
                  Active field distributor licenses provisioned under your plan.
                </p>
              </div>
            </div>
            <span className="text-xs font-bold capitalize text-blue-700 bg-blue-50 border border-blue-200 px-3 py-1 rounded-full">
              {activeTenant?.plan_tier || "standard"} Tier
            </span>
          </div>

          <div className="p-4 bg-slate-50 rounded-xl border border-slate-200/80 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
            <div>
              <div className="text-xs font-semibold text-slate-700">Distributor Mobile Seats Used</div>
              <div className="text-lg font-extrabold text-slate-900">
                {usedSeats} <span className="text-xs font-normal text-slate-500">of {maxSeats} seats issued</span>
              </div>
            </div>
            <div className="w-full sm:w-48 h-2 bg-slate-200 rounded-full overflow-hidden">
              <div
                style={{ width: `${seatPercent}%` }}
                className="h-full bg-blue-600 rounded-full transition-all duration-500"
              />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
