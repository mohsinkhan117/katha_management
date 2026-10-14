"use client";

import React from "react";
import { Building2, Shield, Receipt, Users, Database } from "lucide-react";

export default function CompanySettingsPage() {
  return (
    <div className="max-w-5xl mx-auto space-y-6">
      <div>
        <h1 className="text-2xl font-extrabold text-slate-900 tracking-tight">
          Company Settings & Configuration
        </h1>
        <p className="text-xs sm:text-sm text-slate-500 mt-1">
          Manage your enterprise profile, billing headers, distributor seat limits, and database synchronization.
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
                defaultValue="Apex Agro Chemical Ltd."
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
              />
            </div>
            <div>
              <label className="font-semibold text-slate-700 block mb-1">Tax NTN / Registration Number</label>
              <input
                type="text"
                defaultValue="PK-7492810-4"
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 focus:outline-none focus:ring-2 focus:ring-blue-500/20 font-mono"
              />
            </div>
            <div>
              <label className="font-semibold text-slate-700 block mb-1">Primary Email</label>
              <input
                type="email"
                defaultValue="finance@apexagro.com"
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
              />
            </div>
            <div>
              <label className="font-semibold text-slate-700 block mb-1">Headquarters Phone</label>
              <input
                type="text"
                defaultValue="+92 42 35889900"
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
            <span className="text-xs font-bold text-blue-700 bg-blue-50 border border-blue-200 px-3 py-1 rounded-full">
              Growth Tier
            </span>
          </div>

          <div className="p-4 bg-slate-50 rounded-xl border border-slate-200/80 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
            <div>
              <div className="text-xs font-semibold text-slate-700">Distributor Mobile Seats Used</div>
              <div className="text-lg font-extrabold text-slate-900">
                12 <span className="text-xs font-normal text-slate-500">of 25 seats active</span>
              </div>
            </div>
            <div className="w-full sm:w-48 h-2 bg-slate-200 rounded-full overflow-hidden">
              <div className="w-[48%] h-full bg-blue-600 rounded-full" />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
