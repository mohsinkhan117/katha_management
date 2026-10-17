"use client";

import React from "react";
import {
  X,
  Clock,
  User,
  Tag,
  CreditCard,
  ShieldCheck,
  ShieldAlert,
  Calendar,
  AlertCircle,
  Hash,
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
    }).format(minor / 100);
  };

  const isIncome = entry.type === "income";

  return (
    <div className="fixed inset-0 z-50 overflow-hidden bg-slate-900/60 backdrop-blur-sm animate-in fade-in duration-150">
      <div className="absolute inset-0" onClick={onClose} />

      <div className="fixed inset-y-0 right-0 max-w-full flex pl-10">
        <div className="w-screen max-w-md bg-slate-900 border-l border-slate-800 shadow-2xl flex flex-col text-slate-100">
          {/* Header */}
          <div className="flex items-center justify-between px-6 py-5 border-b border-slate-800 bg-slate-950/60">
            <div className="flex items-center gap-3">
              <div
                className={`p-2 rounded-lg border ${
                  entry.is_voided
                    ? "bg-slate-800 border-slate-700 text-slate-400"
                    : isIncome
                    ? "bg-emerald-500/10 border-emerald-500/30 text-emerald-400"
                    : "bg-rose-500/10 border-rose-500/30 text-rose-400"
                }`}
              >
                {entry.is_voided ? (
                  <ShieldAlert className="w-5 h-5 text-amber-400" />
                ) : isIncome ? (
                  <ShieldCheck className="w-5 h-5" />
                ) : (
                  <AlertCircle className="w-5 h-5" />
                )}
              </div>
              <div>
                <h3 className="font-semibold text-white">Entry Details</h3>
                <p className="text-xs text-slate-400 font-mono">ID: {entry.id.slice(0, 8)}...</p>
              </div>
            </div>
            <button
              onClick={onClose}
              className="p-1.5 rounded-lg text-slate-400 hover:text-white hover:bg-slate-800 transition"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          {/* Body */}
          <div className="flex-1 overflow-y-auto p-6 space-y-6">
            {/* Amount Hero */}
            <div className="p-5 rounded-xl bg-slate-950/80 border border-slate-800 text-center space-y-1">
              <span
                className={`inline-block px-2.5 py-0.5 rounded-full text-xs font-semibold uppercase tracking-wider mb-2 ${
                  entry.is_voided
                    ? "bg-slate-800 text-slate-400 line-through"
                    : isIncome
                    ? "bg-emerald-500/10 text-emerald-400 border border-emerald-500/20"
                    : "bg-rose-500/10 text-rose-400 border border-rose-500/20"
                }`}
              >
                {entry.is_voided ? "Voided Record" : isIncome ? "Income" : "Expense"}
              </span>
              <div
                className={`text-3xl font-bold font-mono tracking-tight ${
                  entry.is_voided
                    ? "text-slate-500 line-through"
                    : isIncome
                    ? "text-emerald-400"
                    : "text-rose-400"
                }`}
              >
                {isIncome ? "+" : "-"}
                {formatCurrency(entry.amount_minor)}
              </div>
              <p className="text-sm font-medium text-slate-300 pt-1">{entry.title}</p>
            </div>

            {/* Void Audit Card (if voided) */}
            {entry.is_voided && (
              <div className="p-4 rounded-lg bg-red-950/20 border border-red-500/30 text-xs space-y-2">
                <div className="flex items-center gap-2 font-semibold text-red-400 uppercase tracking-wider">
                  <ShieldAlert className="w-4 h-4" />
                  <span>Void Audit Information</span>
                </div>
                <div className="text-slate-300">
                  <span className="text-slate-400 font-medium">Reason: </span>
                  <span className="italic">"{entry.void_reason}"</span>
                </div>
                {entry.voided_at && (
                  <div className="text-slate-400">
                    <span className="font-medium">Voided At: </span>
                    <span className="font-mono text-slate-300">{new Date(entry.voided_at).toLocaleString()}</span>
                  </div>
                )}
                {entry.voided_by && (
                  <div className="text-slate-400">
                    <span className="font-medium">Voided By User: </span>
                    <span className="font-mono text-slate-300">{entry.voided_by}</span>
                  </div>
                )}
              </div>
            )}

            {/* Core Fields */}
            <div className="space-y-4">
              <h4 className="text-xs font-semibold text-slate-400 uppercase tracking-wider">
                Transaction Meta
              </h4>

              <div className="space-y-3 text-sm">
                <div className="flex items-center justify-between py-2 border-b border-slate-800/80">
                  <div className="flex items-center gap-2 text-slate-400">
                    <Tag className="w-4 h-4" />
                    <span>Category</span>
                  </div>
                  <span className="font-medium text-slate-200">{entry.category_name}</span>
                </div>

                <div className="flex items-center justify-between py-2 border-b border-slate-800/80">
                  <div className="flex items-center gap-2 text-slate-400">
                    <CreditCard className="w-4 h-4" />
                    <span>Payment Method</span>
                  </div>
                  <span className="font-medium text-slate-200 capitalize">
                    {entry.payment_method || "Other"}
                  </span>
                </div>

                <div className="flex items-center justify-between py-2 border-b border-slate-800/80">
                  <div className="flex items-center gap-2 text-slate-400">
                    <Calendar className="w-4 h-4" />
                    <span>Occurred Date & Time</span>
                  </div>
                  <span className="font-mono text-xs text-slate-300">
                    {new Date(entry.occurred_at).toLocaleString()}
                  </span>
                </div>

                <div className="flex items-center justify-between py-2 border-b border-slate-800/80">
                  <div className="flex items-center gap-2 text-slate-400">
                    <Clock className="w-4 h-4" />
                    <span>System Created At</span>
                  </div>
                  <span className="font-mono text-xs text-slate-300">
                    {new Date(entry.created_at).toLocaleString()}
                  </span>
                </div>

                <div className="flex items-center justify-between py-2 border-b border-slate-800/80">
                  <div className="flex items-center gap-2 text-slate-400">
                    <User className="w-4 h-4" />
                    <span>Recorded By</span>
                  </div>
                  <span className="font-medium text-slate-200">
                    {entry.added_by_name || "Admin"}
                  </span>
                </div>

                <div className="flex items-center justify-between py-2 border-b border-slate-800/80">
                  <div className="flex items-center gap-2 text-slate-400">
                    <Hash className="w-4 h-4" />
                    <span>Full UUID</span>
                  </div>
                  <span className="font-mono text-xs text-slate-400 select-all">
                    {entry.id}
                  </span>
                </div>
              </div>
            </div>
          </div>

          {/* Footer Action */}
          <div className="p-6 border-t border-slate-800 bg-slate-950/60">
            {!entry.is_voided ? (
              <button
                type="button"
                onClick={() => onVoidRequest(entry)}
                className="w-full py-2.5 px-4 bg-red-600/10 hover:bg-red-600/20 text-red-400 border border-red-500/30 rounded-lg text-sm font-semibold transition flex items-center justify-center gap-2"
              >
                <ShieldAlert className="w-4 h-4" />
                <span>Void This Entry</span>
              </button>
            ) : (
              <div className="text-center text-xs text-slate-500 italic">
                This transaction has been voided and is read-only.
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

