"use client";

import React, { useState } from "react";
import { AlertTriangle, Loader2, X, ShieldAlert } from "lucide-react";
import { LedgerEntry } from "@/lib/ledger/service";

interface VoidLedgerItemModalProps {
  isOpen: boolean;
  onClose: () => void;
  entry: LedgerEntry | null;
  onSuccess: () => void;
}

export function VoidLedgerItemModal({
  isOpen,
  onClose,
  entry,
  onSuccess,
}: VoidLedgerItemModalProps) {
  const [reason, setReason] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  if (!isOpen || !entry) return null;

  const formatCurrency = (minor: number) => {
    return new Intl.NumberFormat("en-PK", {
      style: "currency",
      currency: "PKR",
      maximumFractionDigits: 2,
    }).format(minor / 100);
  };

  const handleVoid = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!reason.trim() || reason.trim().length < 3) {
      setError("Please provide a valid void reason (at least 3 characters).");
      return;
    }

    setIsSubmitting(true);
    setError(null);

    try {
      const res = await fetch(`/api/ledger/entries/${entry.id}/void`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ reason: reason.trim() }),
      });

      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.error || "Failed to void ledger entry");
      }

      setReason("");
      onSuccess();
      onClose();
    } catch (err: any) {
      setError(err.message || "Failed to void entry. Please try again.");
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm animate-in fade-in duration-150">
      <div className="relative w-full max-w-lg bg-slate-900 border border-slate-800 rounded-xl shadow-2xl overflow-hidden text-slate-100">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-slate-800 bg-red-950/20">
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-red-500/10 border border-red-500/20 text-red-400">
              <ShieldAlert className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-lg font-semibold text-white">Void Ledger Entry</h2>
              <p className="text-xs text-slate-400">Permanent audit recording</p>
            </div>
          </div>
          <button
            onClick={onClose}
            disabled={isSubmitting}
            className="p-1 rounded-lg text-slate-400 hover:text-white hover:bg-slate-800 transition"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Content */}
        <form onSubmit={handleVoid} className="p-6 space-y-5">
          {error && (
            <div className="p-3 bg-red-500/10 border border-red-500/20 rounded-lg text-sm text-red-400 flex items-start gap-2">
              <AlertTriangle className="w-4 h-4 mt-0.5 shrink-0" />
              <span>{error}</span>
            </div>
          )}

          {/* Entry Summary Box */}
          <div className="bg-slate-800/60 border border-slate-700/60 rounded-lg p-4 space-y-2 text-sm">
            <div className="flex justify-between items-center">
              <span className="text-slate-400">Title:</span>
              <span className="font-medium text-white">{entry.title}</span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-slate-400">Amount:</span>
              <span className={`font-mono font-semibold ${entry.type === "income" ? "text-emerald-400" : "text-rose-400"}`}>
                {entry.type === "income" ? "+" : "-"}{formatCurrency(entry.amount_minor)}
              </span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-slate-400">Category:</span>
              <span className="text-slate-200">{entry.category_name}</span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-slate-400">Date & Time:</span>
              <span className="text-slate-300 font-mono text-xs">
                {new Date(entry.occurred_at).toLocaleString()}
              </span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-slate-400">Added By:</span>
              <span className="text-slate-300">{entry.added_by_name || "Admin"}</span>
            </div>
          </div>

          {/* Warning Note */}
          <div className="p-3.5 bg-amber-500/10 border border-amber-500/20 rounded-lg text-xs text-amber-300 leading-relaxed">
            <span className="font-semibold text-amber-200">Notice:</span> Ledger records are append-only.
            Voiding will not delete the record; it will be marked as voided with an audit timestamp and reason,
            and excluded from all financial calculations and balances.
          </div>

          {/* Required Reason Input */}
          <div className="space-y-1.5">
            <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider">
              Reason for Voiding <span className="text-red-400">*</span>
            </label>
            <textarea
              required
              rows={3}
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              placeholder="e.g. Duplicate entry recorded by mistake, wrong amount entered..."
              className="w-full px-3 py-2 bg-slate-950/80 border border-slate-700 rounded-lg text-sm text-slate-100 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500 resize-none"
            />
            <p className="text-[11px] text-slate-400">
              Minimum 3 characters. This explanation will be permanently recorded in the audit trail.
            </p>
          </div>

          {/* Actions */}
          <div className="flex items-center justify-end gap-3 pt-3 border-t border-slate-800">
            <button
              type="button"
              onClick={onClose}
              disabled={isSubmitting}
              className="px-4 py-2 text-sm font-medium text-slate-400 hover:text-white bg-slate-800/80 hover:bg-slate-800 border border-slate-700 rounded-lg transition"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isSubmitting || reason.trim().length < 3}
              className="px-4 py-2 text-sm font-medium text-white bg-red-600 hover:bg-red-500 active:bg-red-700 disabled:opacity-50 disabled:cursor-not-allowed rounded-lg shadow-lg shadow-red-600/20 transition flex items-center gap-2"
            >
              {isSubmitting && <Loader2 className="w-4 h-4 animate-spin" />}
              <span>Confirm & Void Entry</span>
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

