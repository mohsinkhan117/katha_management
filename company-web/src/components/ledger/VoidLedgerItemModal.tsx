"use client";

import React, { useState } from "react";
import { AlertTriangle, Loader2, X, ShieldAlert } from "lucide-react";
import { useUser } from "@stackframe/stack";
import { useTenant } from "@/context/TenantContext";
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
  const user = useUser();
  const { activeTenant } = useTenant();
  const [reason, setReason] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  if (!isOpen || !entry) return null;

  const formatCurrency = (minor: number) => {
    return new Intl.NumberFormat("en-PK", {
      style: "currency",
      currency: "PKR",
      maximumFractionDigits: 2,
    }).format((minor || 0) / 100);
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
      const headers: Record<string, string> = {
        "Content-Type": "application/json",
      };
      if (activeTenant?.id) {
        headers["x-tenant-id"] = activeTenant.id;
      }
      const email = user?.primaryEmail || activeTenant?.admin_email;
      if (email) {
        headers["x-user-email"] = email;
      }
      const res = await fetch(`/api/ledger/entries/${entry.id}/void`, {
        method: "POST",
        headers,
        credentials: "include",
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
      <div className="relative w-full max-w-lg bg-white border border-slate-200 rounded-2xl shadow-2xl overflow-hidden text-slate-900">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-slate-200 bg-rose-50/60">
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-xl bg-rose-100 border border-rose-200 text-rose-600">
              <ShieldAlert className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-base font-bold text-slate-900">Void Khata Entry</h2>
              <p className="text-xs text-slate-500">Exclude mistaken entry from expense totals</p>
            </div>
          </div>
          <button
            onClick={onClose}
            disabled={isSubmitting}
            className="p-1.5 rounded-lg text-slate-400 hover:text-slate-700 hover:bg-slate-200/60 transition"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Content */}
        <form onSubmit={handleVoid} className="p-6 space-y-4">
          {error && (
            <div className="p-3 bg-rose-50 border border-rose-200 rounded-xl text-xs text-rose-700 font-medium flex items-start gap-2">
              <AlertTriangle className="w-4 h-4 mt-0.5 shrink-0" />
              <span>{error}</span>
            </div>
          )}

          {/* Entry Summary Box */}
          <div className="bg-slate-50 border border-slate-200 rounded-xl p-4 space-y-2 text-xs">
            <div className="flex justify-between items-center">
              <span className="text-slate-500">Item Brought:</span>
              <span className="font-bold text-slate-900">{entry.title}</span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-slate-500">Quantity:</span>
              <span className="font-mono font-bold text-blue-700">
                {entry.quantity || 1} {entry.unit || "pcs"}
              </span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-slate-500">Total Cost Price:</span>
              <span className="font-mono font-extrabold text-slate-900">
                {formatCurrency(entry.amount_minor)}
              </span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-slate-500">Category:</span>
              <span className="font-semibold text-slate-700">{entry.category_name}</span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-slate-500">Date & Time:</span>
              <span className="text-slate-600 font-mono">
                {new Date(entry.occurred_at).toLocaleString()}
              </span>
            </div>
          </div>

          {/* Required Reason Input */}
          <div className="space-y-1.5">
            <label className="block text-xs font-bold text-slate-700">
              Reason for Voiding <span className="text-rose-600">*</span>
            </label>
            <textarea
              required
              rows={3}
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              placeholder="e.g., Duplicate item entry, wrong quantity or cost price entered..."
              className="w-full px-3.5 py-2.5 bg-white border border-slate-200 rounded-xl text-xs text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-rose-500/20 focus:border-rose-500 resize-none"
            />
            <p className="text-[11px] text-slate-400">
              Minimum 3 characters. Voided items are excluded from daily, weekly, monthly, and yearly expense totals.
            </p>
          </div>

          {/* Actions */}
          <div className="flex items-center justify-end gap-2.5 pt-3 border-t border-slate-100">
            <button
              type="button"
              onClick={onClose}
              disabled={isSubmitting}
              className="px-4 py-2 text-xs font-semibold text-slate-600 hover:bg-slate-100 border border-slate-200 rounded-xl transition"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isSubmitting || reason.trim().length < 3}
              className="px-4 py-2 text-xs font-bold text-white bg-rose-600 hover:bg-rose-500 disabled:opacity-50 disabled:cursor-not-allowed rounded-xl shadow-md shadow-rose-600/20 transition flex items-center gap-1.5"
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
