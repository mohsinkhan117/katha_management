"use client";

import React, { useState, useEffect, useCallback } from "react";
import {
  Plus,
  ShieldCheck,
  FileSpreadsheet,
  Lock,
  ShoppingBag,
} from "lucide-react";
import { useUser } from "@stackframe/stack";
import { useTenant } from "@/context/TenantContext";
import { LedgerCategory, LedgerEntry } from "@/lib/ledger/service";
import { TodaySummaryCards, FilterPeriodMode } from "@/components/ledger/TodaySummaryCards";
import { LedgerCharts } from "@/components/ledger/LedgerCharts";
import { ExcelLedgerTable } from "@/components/ledger/ExcelLedgerTable";
import { AddLedgerItemModal } from "@/components/ledger/AddLedgerItemModal";
import { VoidLedgerItemModal } from "@/components/ledger/VoidLedgerItemModal";
import { LedgerDetailDrawer } from "@/components/ledger/LedgerDetailDrawer";

export default function CommercialLedgerPage() {
  const user = useUser();
  const { activeTenant, hasAccess } = useTenant();

  // Categories state
  const [categories, setCategories] = useState<LedgerCategory[]>([]);
  const [refreshTrigger, setRefreshTrigger] = useState(0);

  // Shared Date / Month / Year Filter State
  const getTodayIso = () => {
    const now = new Date();
    const offsetMs = now.getTimezoneOffset() * 60000;
    return new Date(now.getTime() - offsetMs).toISOString().split("T")[0];
  };

  const now = new Date();
  const [filterMode, setFilterMode] = useState<FilterPeriodMode>("date");
  const [selectedDate, setSelectedDate] = useState<string>(getTodayIso());
  const [selectedMonth, setSelectedMonth] = useState<number>(now.getMonth() + 1);
  const [selectedYear, setSelectedYear] = useState<number>(now.getFullYear());

  // Modals state
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [selectedEntryForDetails, setSelectedEntryForDetails] = useState<LedgerEntry | null>(null);
  const [selectedEntryForVoid, setSelectedEntryForVoid] = useState<LedgerEntry | null>(null);

  const handleRefresh = useCallback(() => {
    setRefreshTrigger((prev) => prev + 1);
  }, []);

  useEffect(() => {
    let isMounted = true;
    async function loadCategories() {
      try {
        const res = await fetch("/api/ledger/categories");
        if (res.ok) {
          const json = await res.json();
          if (isMounted) {
            setCategories(json.data || []);
          }
        }
      } catch (err) {
        console.error("Failed to load categories:", err);
      }
    }

    loadCategories();
    return () => {
      isMounted = false;
    };
  }, [refreshTrigger]);

  const handleCategoryCreated = (newCat: LedgerCategory) => {
    setCategories((prev) => [...prev, newCat]);
  };

  if (user && !hasAccess) {
    return (
      <div className="min-h-[70vh] flex flex-col items-center justify-center text-center p-6 space-y-4">
        <div className="p-4 rounded-2xl bg-rose-50 border border-rose-200 text-rose-600">
          <Lock className="w-10 h-10" />
        </div>
        <h2 className="text-xl font-bold text-slate-900">Admin-Only Khata Access</h2>
        <p className="text-sm text-slate-500 max-w-md">
          The Party Expense & Purchase Khata Ledger is restricted to authorized administrators of this tenant.
        </p>
      </div>
    );
  }

  return (
    <div className="max-w-7xl mx-auto space-y-6 pb-12">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white border border-slate-200 rounded-2xl p-5 shadow-sm">
        <div className="space-y-1">
          <div className="flex items-center gap-3">
            <div className="p-2.5 rounded-xl bg-emerald-600 text-white shadow-md shadow-emerald-600/20">
              <FileSpreadsheet className="w-5 h-5" />
            </div>
            <div>
              <h1 className="text-xl font-extrabold text-slate-900 tracking-tight">
                Party Khata & Expense Ledger
              </h1>
              <div className="flex flex-wrap items-center gap-2 text-xs text-slate-500 mt-0.5">
                <span className="font-bold text-slate-700">
                  {activeTenant?.name || "Hotel / Business Operations"}
                </span>
                <span>•</span>
                <span>
                  Track items brought (e.g. 100 Chicken + Cost Price) & daily, weekly, monthly expenses
                </span>
                <span>•</span>
                <span className="inline-flex items-center gap-1 text-emerald-700 font-semibold">
                  <ShieldCheck className="w-3.5 h-3.5" />
                  Tenant Isolated
                </span>
              </div>
            </div>
          </div>
        </div>

        {/* Primary Add Item Button */}
        <div className="flex items-center gap-3 self-start sm:self-auto">
          <button
            onClick={() => setIsAddModalOpen(true)}
            className="flex items-center gap-2 px-4 py-2.5 bg-emerald-600 hover:bg-emerald-500 active:bg-emerald-700 text-white font-bold rounded-xl shadow-md shadow-emerald-600/20 text-xs sm:text-sm transition"
          >
            <Plus className="w-4 h-4" />
            <span>Add Item Brought / Expense</span>
          </button>
        </div>
      </div>

      {/* 1. Date / Month / Year Filter Bar & Daily, Weekly, Monthly, Yearly Expense Summary Cards */}
      <TodaySummaryCards
        refreshTrigger={refreshTrigger}
        filterMode={filterMode}
        setFilterMode={setFilterMode}
        selectedDate={selectedDate}
        setSelectedDate={setSelectedDate}
        selectedMonth={selectedMonth}
        setSelectedMonth={setSelectedMonth}
        selectedYear={selectedYear}
        setSelectedYear={setSelectedYear}
      />

      {/* 2. All Items Brought in Selected Period + Excel-Style Khata Table */}
      <ExcelLedgerTable
        categories={categories}
        refreshTrigger={refreshTrigger}
        filterMode={filterMode}
        selectedDate={selectedDate}
        selectedMonth={selectedMonth}
        selectedYear={selectedYear}
        onRefreshNeeded={handleRefresh}
        onSelectEntryForDetails={(entry) => setSelectedEntryForDetails(entry)}
        onSelectEntryForVoid={(entry) => setSelectedEntryForVoid(entry)}
      />

      {/* 3. Visual Graphs & Expense Analytics (Weekly / Monthly / Quarterly) */}
      <LedgerCharts refreshTrigger={refreshTrigger} />

      {/* Modals & Drawers */}
      <AddLedgerItemModal
        isOpen={isAddModalOpen}
        onClose={() => setIsAddModalOpen(false)}
        categories={categories}
        currentUserName={user?.displayName || user?.primaryEmail || "Admin"}
        defaultDate={selectedDate}
        onSuccess={handleRefresh}
        onCategoryCreated={handleCategoryCreated}
      />

      <VoidLedgerItemModal
        isOpen={Boolean(selectedEntryForVoid)}
        onClose={() => setSelectedEntryForVoid(null)}
        entry={selectedEntryForVoid}
        onSuccess={() => {
          handleRefresh();
          setSelectedEntryForVoid(null);
          if (selectedEntryForDetails?.id === selectedEntryForVoid?.id) {
            setSelectedEntryForDetails(null);
          }
        }}
      />

      <LedgerDetailDrawer
        isOpen={Boolean(selectedEntryForDetails)}
        onClose={() => setSelectedEntryForDetails(null)}
        entry={selectedEntryForDetails}
        onVoidRequest={(entry) => {
          setSelectedEntryForVoid(entry);
        }}
      />
    </div>
  );
}
