"use client";

import React, { useState, useEffect, useCallback } from "react";
import {
  Receipt,
  Plus,
  ShieldCheck,
  ShieldAlert,
  HelpCircle,
  FileSpreadsheet,
  Lock,
} from "lucide-react";
import { useUser } from "@stackframe/stack";
import { useTenant } from "@/context/TenantContext";
import { LedgerCategory, LedgerEntry } from "@/lib/ledger/service";
import { TodaySummaryCards } from "@/components/ledger/TodaySummaryCards";
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

  // Modals state
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [selectedEntryForDetails, setSelectedEntryForDetails] = useState<LedgerEntry | null>(null);
  const [selectedEntryForVoid, setSelectedEntryForVoid] = useState<LedgerEntry | null>(null);

  // Trigger data reload across summary, charts, and table
  const handleRefresh = useCallback(() => {
    setRefreshTrigger((prev) => prev + 1);
  }, []);

  // Fetch available ledger categories
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

  // Check admin authorization
  if (user && !hasAccess) {
    return (
      <div className="min-h-[70vh] flex flex-col items-center justify-center text-center p-6 space-y-4">
        <div className="p-4 rounded-2xl bg-red-500/10 border border-red-500/20 text-red-400">
          <Lock className="w-10 h-10" />
        </div>
        <h2 className="text-xl font-bold text-white">Admin-Only Access</h2>
        <p className="text-sm text-slate-400 max-w-md">
          The Commercial Cash & Expense Ledger is strictly restricted to shop owners and tenant administrators.
          You do not have administrative privileges for this tenant.
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-6 pb-12">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-slate-900 border border-slate-800 rounded-xl p-5 shadow-lg">
        <div className="space-y-1">
          <div className="flex items-center gap-2.5">
            <div className="p-2 rounded-lg bg-emerald-500/10 border border-emerald-500/20 text-emerald-400">
              <FileSpreadsheet className="w-5 h-5" />
            </div>
            <div>
              <h1 className="text-xl font-bold text-white tracking-tight">
                Commercial Cash & Expense Ledger
              </h1>
              <div className="flex items-center gap-2 text-xs text-slate-400 mt-0.5">
                <span className="font-medium text-slate-300">
                  {activeTenant?.name || "Store Operations"}
                </span>
                <span>•</span>
                <span className="inline-flex items-center gap-1 text-emerald-400 font-medium">
                  <ShieldCheck className="w-3.5 h-3.5" />
                  Tenant Isolated
                </span>
                <span>•</span>
                <span className="text-slate-500">Append-Only Audit</span>
              </div>
            </div>
          </div>
        </div>

        {/* Action Button */}
        <div className="flex items-center gap-3">
          <button
            onClick={() => setIsAddModalOpen(true)}
            className="flex items-center gap-2 px-4 py-2.5 bg-emerald-600 hover:bg-emerald-500 active:bg-emerald-700 text-white font-semibold rounded-lg shadow-lg shadow-emerald-600/20 text-sm transition"
          >
            <Plus className="w-4 h-4" />
            <span>Add Transaction</span>
          </button>
        </div>
      </div>

      {/* 1. Daily Summary Cards */}
      <TodaySummaryCards refreshTrigger={refreshTrigger} />

      {/* 2. Visual Graphs & Expense Analytics */}
      <LedgerCharts refreshTrigger={refreshTrigger} />

      {/* 3. Excel-Like Interactive Ledger Table */}
      <ExcelLedgerTable
        categories={categories}
        refreshTrigger={refreshTrigger}
        onRefreshNeeded={handleRefresh}
        onSelectEntryForDetails={(entry) => setSelectedEntryForDetails(entry)}
        onSelectEntryForVoid={(entry) => setSelectedEntryForVoid(entry)}
      />

      {/* Modals & Drawers */}
      <AddLedgerItemModal
        isOpen={isAddModalOpen}
        onClose={() => setIsAddModalOpen(false)}
        categories={categories}
        currentUserName={user?.displayName || user?.primaryEmail || "Admin"}
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
          // If drawer was open for this entry, close it or update it
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

