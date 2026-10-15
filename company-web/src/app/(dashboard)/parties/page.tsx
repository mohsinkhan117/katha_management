"use client";

import React, { useState } from "react";
import { BookOpen, Search, Plus, Phone, MapPin, AlertTriangle, CheckCircle, ArrowUpRight } from "lucide-react";

interface PartyItem {
  id: string;
  name: string;
  ownerName: string;
  phone: string;
  territory: string;
  creditLimit: number;
  currentBalance: number;
  status: "Normal" | "Near Limit" | "Exceeded";
}

const mockParties: PartyItem[] = [
  {
    id: "pty-1",
    name: "Madina Kiryana Store",
    ownerName: "Haji Mohammad Sharif",
    phone: "+92 301 2345678",
    territory: "Lahore East",
    creditLimit: 150000,
    currentBalance: 42500,
    status: "Normal",
  },
  {
    id: "pty-2",
    name: "Bismillah General Mart",
    ownerName: "Sheikh Abdul Rasheed",
    phone: "+92 322 3456789",
    territory: "Faisalabad",
    creditLimit: 300000,
    currentBalance: 275000,
    status: "Near Limit",
  },
  {
    id: "pty-3",
    name: "Al-Rehman Traders",
    ownerName: "Chaudhry Akram",
    phone: "+92 334 4567890",
    territory: "Gujranwala",
    creditLimit: 100000,
    currentBalance: 112000,
    status: "Exceeded",
  },
  {
    id: "pty-4",
    name: "Punjab Traders & Agency",
    ownerName: "Malik Usman",
    phone: "+92 300 5678901",
    territory: "Lahore East",
    creditLimit: 500000,
    currentBalance: 145000,
    status: "Normal",
  },
];

import { useTenant } from "@/context/TenantContext";

export default function CompanyPartiesPage() {
  const { activeTenant, tenantData, hasAccess, isCustomTenant } = useTenant();
  const [search, setSearch] = useState("");

  // Rule logic:
  // For custom tenants with access, extract parties from their real orders/ledger in Neon.
  // If clean, show 0 parties and empty state.
  // If unauthorized/no access, show mockParties as demo preview.
  let effectiveParties: PartyItem[] = mockParties;

  if (hasAccess && isCustomTenant) {
    if (tenantData && tenantData.orders && tenantData.orders.length > 0) {
      // Group orders by party_name
      const partyMap = new Map<string, { totalAmount: number; paidAmount: number }>();
      tenantData.orders.forEach((o) => {
        const cur = partyMap.get(o.partyName) || { totalAmount: 0, paidAmount: 0 };
        cur.totalAmount += Number(o.totalAmount || 0);
        cur.paidAmount += Number(o.paidAmount || 0);
        partyMap.set(o.partyName, cur);
      });

      effectiveParties = Array.from(partyMap.entries()).map(([name, data], idx) => {
        const balance = Math.max(0, data.totalAmount - data.paidAmount);
        const limit = 200000;
        let status: PartyItem["status"] = "Normal";
        if (balance > limit) status = "Exceeded";
        else if (balance > limit * 0.8) status = "Near Limit";

        return {
          id: `pty-real-${idx + 1}`,
          name,
          ownerName: "Proprietor",
          phone: "+92 300 0000000",
          territory: "Assigned Territory",
          creditLimit: limit,
          currentBalance: balance,
          status,
        };
      });
    } else {
      effectiveParties = [];
    }
  }

  const filteredParties = effectiveParties.filter(
    (p) =>
      p.name.toLowerCase().includes(search.toLowerCase()) ||
      p.ownerName.toLowerCase().includes(search.toLowerCase()) ||
      p.territory.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="max-w-7xl mx-auto space-y-6">
      {/* No Access / Demo Banner */}
      {!hasAccess && (
        <div className="p-4 bg-amber-50 border border-amber-200 rounded-2xl flex items-start gap-3 text-amber-900 text-xs">
          <AlertTriangle className="w-5 h-5 text-amber-600 shrink-0 mt-0.5" />
          <div>
            <div className="font-bold text-sm">Demo / Sandbox Mode (No Active Tenant)</div>
            <p className="text-amber-700 mt-0.5">
              Your account is not linked to an active company tenant. Displaying simulated parties and khata records.
            </p>
          </div>
        </div>
      )}

      {/* Top Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-extrabold text-slate-900 tracking-tight">
            Parties & Centralized Khata Ledger
          </h1>
          <p className="text-xs sm:text-sm text-slate-500 mt-1">
            Track customer credit limits, outstanding ledger balances, and payment recovery across all territories.
          </p>
        </div>

        <button
          onClick={() => alert("Open New Party Modal")}
          className="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-500 text-white rounded-xl text-xs font-semibold shadow-md shadow-blue-600/20 transition self-start sm:self-auto"
        >
          <Plus className="w-4 h-4" />
          Add Customer Party
        </button>
      </div>

      {/* Search Bar */}
      <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm">
        <div className="relative max-w-md">
          <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search party name, proprietor, or territory..."
            className="w-full pl-9 pr-4 py-2 text-xs bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 text-slate-800"
          />
        </div>
      </div>

      {/* Parties Table */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead>
              <tr className="bg-slate-50/80 border-b border-slate-200 text-slate-500 uppercase tracking-wider text-[11px]">
                <th className="py-3 px-4 font-semibold">Party Store</th>
                <th className="py-3 px-4 font-semibold">Proprietor & Phone</th>
                <th className="py-3 px-4 font-semibold">Territory</th>
                <th className="py-3 px-4 font-semibold text-right">Credit Limit</th>
                <th className="py-3 px-4 font-semibold text-right">Current Ledger Dues</th>
                <th className="py-3 px-4 font-semibold text-center">Status</th>
                <th className="py-3 px-4 font-semibold text-right">Ledger</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {filteredParties.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-12 px-4 text-center">
                    <div className="max-w-sm mx-auto flex flex-col items-center justify-center space-y-3">
                      <div className="w-12 h-12 rounded-2xl bg-slate-100 text-slate-400 flex items-center justify-center">
                        <BookOpen className="w-6 h-6" />
                      </div>
                      <div className="space-y-1">
                        <div className="text-sm font-bold text-slate-800">
                          {effectiveParties.length === 0
                            ? "No customer parties registered yet"
                            : "No matching parties found"}
                        </div>
                        <p className="text-xs text-slate-500">
                          {effectiveParties.length === 0
                            ? "Parties registered by field distributors during sales visits will automatically appear in this centralized ledger."
                            : "Try searching with a different name, proprietor, or territory."}
                        </p>
                      </div>
                      {effectiveParties.length === 0 && (
                        <button
                          onClick={() => alert("Open New Party Modal")}
                          className="mt-2 inline-flex items-center gap-1.5 px-3 py-1.5 bg-blue-50 text-blue-700 hover:bg-blue-100 rounded-lg text-xs font-semibold transition"
                        >
                          <Plus className="w-3.5 h-3.5" />
                          Add First Customer Party
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ) : (
                filteredParties.map((p) => (
                  <tr key={p.id} className="hover:bg-slate-50/80 transition">
                    <td className="py-3 px-4 font-bold text-slate-900">
                      {p.name}
                    </td>
                    <td className="py-3 px-4 text-slate-600">
                      <div>{p.ownerName}</div>
                      <div className="text-[11px] text-slate-400">{p.phone}</div>
                    </td>
                    <td className="py-3 px-4 text-slate-600">
                      {p.territory}
                    </td>
                    <td className="py-3 px-4 text-right font-medium text-slate-700">
                      Rs. {p.creditLimit.toLocaleString()}
                    </td>
                    <td className="py-3 px-4 text-right font-bold text-slate-900">
                      Rs. {p.currentBalance.toLocaleString()}
                    </td>
                    <td className="py-3 px-4 text-center">
                      {p.status === "Exceeded" ? (
                        <span className="inline-flex items-center gap-1 text-[11px] font-semibold px-2 py-0.5 rounded-full bg-rose-50 text-rose-700 border border-rose-200">
                          <AlertTriangle className="w-3 h-3" />
                          Limit Exceeded
                        </span>
                      ) : p.status === "Near Limit" ? (
                        <span className="inline-flex items-center gap-1 text-[11px] font-semibold px-2 py-0.5 rounded-full bg-amber-50 text-amber-700 border border-amber-200">
                          Near Limit
                        </span>
                      ) : (
                        <span className="inline-flex items-center gap-1 text-[11px] font-semibold px-2 py-0.5 rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200">
                          <CheckCircle className="w-3 h-3" />
                          Healthy
                        </span>
                      )}
                    </td>
                    <td className="py-3 px-4 text-right">
                      <button
                        onClick={() => alert(`Opening Khata Ledger for ${p.name}`)}
                        className="text-xs font-semibold text-blue-600 hover:text-blue-700 inline-flex items-center gap-1"
                      >
                        View Khata
                        <ArrowUpRight className="w-3.5 h-3.5" />
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
