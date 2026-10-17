"use client";

import React from "react";
import {
  X,
  Clock,
  User,
  Tag,
  CreditCard,
  ShieldAlert,
  Calendar,
  Hash,
  Package,
  Store,
} from "lucide-react";
import { LedgerEntry } from "@/lib/ledger/service";

interface LedgerDetailDrawerProps {
  isOpen: boolean;
  onClose: () => void;
  entry: LedgerEntry | null;
  onVoidRequest: (entry: LedgerEntry) => void;
}

export function LedgerDetailDrawer({
  isOpen,
  onClose,
  entry,
  onVoidRequest,
}: LedgerDetailDrawerProps) {
  if (!isOpen || !entry) return null;

  const formatCurrency = (minor: number) => {
    return new Intl.NumberFormat("en-PK", {
      style: "currency",
      currency: "PKR",
      maximumFractionDigits: 2,
    }).format((minor || 0) / 100);
  };

  return (
    <div className="fixed inset-0 z-50 overflow-hidden bg-slate-900/50 backdrop-blur-sm animate-in fade-in duration-150">
      <div className="absolute inset-0" onClick={onClose} />

      <div className="fixed inset-y-0 right-0 max-w-full flex pl-10">
        <div className="w-screen max-w-md bg-white border-l border-slate-200 shadow-2xl flex flex-col text-slate-900">
          {/* Header */}
          <div className="flex items-center justify-between px-6 py-5 border-b border-slate-200 bg-slate-50">
            <div className="flex items-center gap-3">
              <div
                className={`p-2 rounded-xl border ${
                  entry.is_voided
                    ? "bg-slate-100 border-slate-200 text-slate-400"
                    : "bg-emerald-50 border-emerald-200 text-emerald-600"
                }`}
              >
                <Package className="w-5 h-5" />
              </div>
              <div>
                <h3 className="font-bold text-slate-900">Item Khata Details</h3>
                <p className="text-xs text-slate-500 font-mono">
                  ID: {entry.id.slice(0, 8)}...
                </p>
              </div>
            </div>
            <button
              onClick={onClose}
              className="p-1.5 rounded-lg text-slate-400 hover:text-slate-700 hover:bg-slate-200/60 transition"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          {/* Body */}
          <div className="flex-1 overflow-y-auto p-6 space-y-6">
            {/* Hero Cost Card */}
            <div className="p-5 rounded-2xl bg-emerald-50/70 border border-emerald-200 text-center space-y-1.5">
              <span
                className={`inline-block px-2.5 py-0.5 rounded-full text-[11px] font-bold uppercase tracking-wider ${
                  entry.is_voided
                    ? "bg-slate-200 text-slate-500 line-through"
                    : "bg-emerald-600 text-white"
                }`}
              >
                {entry.is_voided
                  ? "Voided Entry"
                  : `${entry.quantity || 1} ${entry.unit || "pcs"} Brought`}
              </span>
              <div
                className={`text-3xl font-extrabold font-mono tracking-tight ${
                  entry.is_voided ? "text-slate-400 line-through" : "text-slate-900"
                }`}
              >
                {formatCurrency(entry.amount_minor)}
              </div>
              <p className="text-sm font-bold text-slate-800">{entry.title}</p>
              <p className="text-xs font-mono text-emerald-800">
                Unit Rate: {formatCurrency(entry.unit_cost_minor || entry.amount_minor)} /{" "}
                {entry.unit || "pcs"}
              </p>
            </div>

            {/* Void Audit Box */}
            {entry.is_voided && (
              <div className="p-4 rounded-xl bg-rose-50 border border-rose-200 text-xs space-y-1.5">
                <div className="flex items-center gap-2 font-bold text-rose-700 uppercase tracking-wider">
                  <ShieldAlert className="w-4 h-4" />
                  <span>Void Audit Trail</span>
                </div>
                <div className="text-slate-700">
                  <span className="font-semibold">Reason: </span>
                  <span className="italic">&ldquo;{entry.void_reason}&rdquo;</span>
                </div>
                {entry.voided_at && (
                  <div className="text-slate-500">
                    <span className="font-semibold">Voided At: </span>
                    <span className="font-mono">
                      {new Date(entry.voided_at).toLocaleString()}
                    </span>
                  </div>
                )}
              </div>
            )}

            {/* Metadata Rows */}
            <div className="space-y-3 text-xs">
              <h4 className="text-[11px] font-bold text-slate-400 uppercase tracking-wider">
                Purchase Information
              </h4>

              <div className="flex items-center justify-between py-2.5 border-b border-slate-100">
                <span className="text-slate-500 flex items-center gap-2">
                  <Package className="w-4 h-4 text-slate-400" />
                  Quantity & Unit
                </span>
                <span className="font-mono font-bold text-slate-900">
                  {entry.quantity || 1} {entry.unit || "pcs"}
                </span>
              </div>

              <div className="flex items-center justify-between py-2.5 border-b border-slate-100">
                <span className="text-slate-500 flex items-center gap-2">
                  <Tag className="w-4 h-4 text-slate-400" />
                  Category
                </span>
                <span className="font-semibold text-slate-800">
                  {entry.category_name || "Expense"}
                </span>
              </div>

              <div className="flex items-center justify-between py-2.5 border-b border-slate-100">
                <span className="text-slate-500 flex items-center gap-2">
                  <Store className="w-4 h-4 text-slate-400" />
                  Supplier / Vendor
                </span>
                <span className="font-semibold text-slate-800">
                  {entry.vendor_name || "Direct Purchase"}
                </span>
              </div>

              <div className="flex items-center justify-between py-2.5 border-b border-slate-100">
                <span className="text-slate-500 flex items-center gap-2">
                  <CreditCard className="w-4 h-4 text-slate-400" />
                  Payment Mode
                </span>
                <span className="font-semibold text-slate-800 uppercase">
                  {entry.payment_method || "Cash"}
                </span>
              </div>

              <div className="flex items-center justify-between py-2.5 border-b border-slate-100">
                <span className="text-slate-500 flex items-center gap-2">
                  <Calendar className="w-4 h-4 text-slate-400" />
                  Date & Time Brought
                </span>
                <span className="font-mono text-slate-800">
                  {new Date(entry.occurred_at).toLocaleString()}
                </span>
              </div>

              <div className="flex items-center justify-between py-2.5 border-b border-slate-100">
                <span className="text-slate-500 flex items-center gap-2">
                  <User className="w-4 h-4 text-slate-400" />
                  Recorded By
                </span>
                <span className="font-semibold text-slate-800">
                  {entry.added_by_name || "Admin"}
                </span>
              </div>

              <div className="flex items-center justify-between py-2.5 border-b border-slate-100">
                <span className="text-slate-500 flex items-center gap-2">
                  <Hash className="w-4 h-4 text-slate-400" />
                  Entry UUID
                </span>
                <span className="font-mono text-[11px] text-slate-400 select-all">
                  {entry.id}
                </span>
              </div>
            </div>
          </div>

          {/* Footer Action */}
          <div className="p-6 border-t border-slate-200 bg-slate-50">
            {!entry.is_voided ? (
              <button
                type="button"
                onClick={() => onVoidRequest(entry)}
                className="w-full py-2.5 px-4 bg-rose-50 hover:bg-rose-100 text-rose-700 border border-rose-200 rounded-xl text-xs font-bold transition flex items-center justify-center gap-2"
              >
                <ShieldAlert className="w-4 h-4" />
                <span>Void This Item Entry</span>
              </button>
            ) : (
              <div className="text-center text-xs text-slate-400 italic">
                This entry has been voided and is excluded from all totals.
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
