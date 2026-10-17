"use client";

import React, { useState, useEffect, useRef } from "react";
import {
  X,
  Plus,
  Loader2,
  TrendingUp,
  TrendingDown,
  CreditCard,
  Banknote,
  Globe,
  HelpCircle,
  Calendar,
  Clock,
  User,
  CheckCircle2,
} from "lucide-react";
import { LedgerCategory } from "@/lib/ledger/service";

interface AddLedgerItemModalProps {
  isOpen: boolean;
  onClose: () => void;
  categories: LedgerCategory[];
  currentUserName: string;
  onSuccess: () => void;
  onCategoryCreated: (category: LedgerCategory) => void;
}

export function AddLedgerItemModal({
  isOpen,
  onClose,
  categories,
  currentUserName,
  onSuccess,
  onCategoryCreated,
}: AddLedgerItemModalProps) {
  const [type, setType] = useState<"income" | "expense">("income");
  const [title, setTitle] = useState("");
  const [categoryId, setCategoryId] = useState("");
  const [amountInput, setAmountInput] = useState("");
  const [paymentMethod, setPaymentMethod] = useState<"cash" | "card" | "online" | "other">("cash");
  const [dateTime, setDateTime] = useState("");

  // Custom Category Creation State
  const [isAddingCategory, setIsAddingCategory] = useState(false);
  const [newCategoryName, setNewCategoryName] = useState("");
  const [isCreatingCategory, setIsCreatingCategory] = useState(false);

  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [successToast, setSuccessToast] = useState<string | null>(null);

  const titleInputRef = useRef<HTMLInputElement>(null);

  // Initialize date time string to local ISO
  useEffect(() => {
    if (isOpen) {
      const now = new Date();
      const offsetMs = now.getTimezoneOffset() * 60000;
      const localISOTime = new Date(now.getTime() - offsetMs).toISOString().slice(0, 16);
      setDateTime(localISOTime);
      setError(null);
      setSuccessToast(null);

      // Autofocus Title input for fast keyboard entry
      setTimeout(() => {
        titleInputRef.current?.focus();
      }, 100);
    }
  }, [isOpen]);

  // Filter categories by selected Type
  const filteredCategories = categories.filter((c) => c.type === type);

  // Auto-select first matching category when type changes
  useEffect(() => {
    if (filteredCategories.length > 0) {
      if (!filteredCategories.some((c) => c.id === categoryId)) {
        setCategoryId(filteredCategories[0].id);
      }
    } else {
      setCategoryId("");
    }
  }, [type, filteredCategories, categoryId]);

  if (!isOpen) return null;

  // Convert decimal PKR input to integer minor units (paise)
  const getAmountMinor = (): number => {
    const parsed = parseFloat(amountInput);
    if (isNaN(parsed) || parsed <= 0) return 0;
    return Math.round(parsed * 100);
  };

  const handleCreateCategory = async () => {
    if (!newCategoryName.trim()) return;
    try {
      setIsCreatingCategory(true);
      const res = await fetch("/api/ledger/categories", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          name: newCategoryName.trim(),
          type,
        }),
      });
      const json = await res.json();
      if (json.success && json.data) {
        onCategoryCreated(json.data);
        setCategoryId(json.data.id);
        setIsAddingCategory(false);
        setNewCategoryName("");
      } else {
        setError(json.error || "Failed to create category");
      }
    } catch (err: any) {
      setError(err.message);
    } finally {
      setIsCreatingCategory(false);
    }
  };

  const submitEntry = async (keepOpen: boolean = false) => {
    const amountMinor = getAmountMinor();
    if (!title.trim()) {
      setError("Please provide an entry title.");
      titleInputRef.current?.focus();
      return;
    }
    if (!categoryId) {
      setError("Please select a valid category.");
      return;
    }
    if (amountMinor <= 0) {
      setError("Amount must be greater than 0.00.");
      return;
    }

    try {
      setIsSubmitting(true);
      setError(null);

      const payload = {
        type,
        title: title.trim(),
        categoryId,
        amountMinor,
        currency: "PKR",
        paymentMethod,
        occurredAt: dateTime ? new Date(dateTime).toISOString() : new Date().toISOString(),
      };

      const res = await fetch("/api/ledger/entries", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });

      const json = await res.json();
      if (json.success) {
        onSuccess();
        if (keepOpen) {
          setTitle("");
          setAmountInput("");
          setSuccessToast(`Entry "${payload.title}" saved. Ready for next entry.`);
          setTimeout(() => setSuccessToast(null), 3500);
          titleInputRef.current?.focus();
        } else {
          onClose();
        }
      } else {
        setError(json.error || "Failed to save ledger entry.");
      }
    } catch (err: any) {
      setError(err.message || "An unexpected error occurred.");
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    submitEntry(false);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm animate-in fade-in duration-200">
      <div className="bg-white rounded-2xl max-w-lg w-full p-6 shadow-2xl border border-slate-100 relative max-h-[92vh] overflow-y-auto">
        <button
          onClick={onClose}
          className="absolute top-4 right-4 text-slate-400 hover:text-slate-600 p-1 rounded-lg"
          tabIndex={-1}
        >
          <X className="w-5 h-5" />
        </button>

        {/* Modal Header */}
        <div className="flex items-center gap-3 mb-5">
          <div
            className={`w-10 h-10 rounded-xl flex items-center justify-center text-white ${
              type === "income" ? "bg-emerald-600 shadow-emerald-600/30" : "bg-rose-600 shadow-rose-600/30"
            } shadow-md transition-colors`}
          >
            {type === "income" ? <TrendingUp className="w-5 h-5" /> : <TrendingDown className="w-5 h-5" />}
          </div>
          <div>
            <h2 className="text-lg font-bold text-slate-900">Record Commercial Ledger Entry</h2>
            <p className="text-xs text-slate-500">Shop owner append-only money in and out tracker</p>
          </div>
        </div>

        {/* Feedback Alerts */}
        {error && (
          <div className="mb-4 p-3 bg-rose-50 border border-rose-200 rounded-xl text-rose-700 text-xs animate-in fade-in">
            {error}
          </div>
        )}

        {successToast && (
          <div className="mb-4 p-3 bg-emerald-50 border border-emerald-200 rounded-xl text-emerald-800 text-xs flex items-center gap-2 animate-in fade-in">
            <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />
            <span className="font-semibold">{successToast}</span>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4 text-xs">
          {/* 1. Income vs Expense Toggle */}
          <div>
            <label className="font-semibold text-slate-700 block mb-1.5">Entry Type *</label>
            <div className="grid grid-cols-2 gap-2 p-1 bg-slate-100 rounded-xl">
              <button
                type="button"
                onClick={() => setType("income")}
                className={`flex items-center justify-center gap-2 py-2 rounded-lg font-bold transition-all ${
                  type === "income"
                    ? "bg-white text-emerald-700 shadow-sm border border-emerald-200"
                    : "text-slate-500 hover:text-slate-800"
                }`}
              >
                <TrendingUp className="w-4 h-4 text-emerald-600" />
                Income (Money In)
              </button>
              <button
                type="button"
                onClick={() => setType("expense")}
                className={`flex items-center justify-center gap-2 py-2 rounded-lg font-bold transition-all ${
                  type === "expense"
                    ? "bg-white text-rose-700 shadow-sm border border-rose-200"
                    : "text-slate-500 hover:text-slate-800"
                }`}
              >
                <TrendingDown className="w-4 h-4 text-rose-600" />
                Expense (Money Out)
              </button>
            </div>
          </div>

          {/* 2. Title & Amount */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label className="font-semibold text-slate-700 block mb-1">Title / Description *</label>
              <input
                ref={titleInputRef}
                type="text"
                required
                placeholder={type === "income" ? "e.g. Counter Cash Sales" : "e.g. Shop Rent October"}
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 focus:outline-none focus:ring-2 focus:ring-blue-500/20 font-medium"
              />
            </div>

            <div>
              <label className="font-semibold text-slate-700 block mb-1">Amount (PKR) *</label>
              <input
                type="number"
                step="0.01"
                min="0.01"
                required
                placeholder="0.00"
                value={amountInput}
                onChange={(e) => setAmountInput(e.target.value)}
                className={`w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 font-mono font-bold text-sm ${
                  type === "income" ? "text-emerald-700 focus:ring-emerald-500/20" : "text-rose-700 focus:ring-rose-500/20"
                }`}
              />
            </div>
          </div>

          {/* 3. Category Selector & Add New Category */}
          <div>
            <div className="flex items-center justify-between mb-1">
              <label className="font-semibold text-slate-700">Category *</label>
              <button
                type="button"
                onClick={() => setIsAddingCategory(!isAddingCategory)}
                className="text-[11px] font-semibold text-blue-600 hover:text-blue-700 flex items-center gap-0.5"
              >
                <Plus className="w-3 h-3" />
                {isAddingCategory ? "Select existing" : "Add custom category"}
              </button>
            </div>

            {isAddingCategory ? (
              <div className="flex gap-2">
                <input
                  type="text"
                  placeholder={`New ${type} category name...`}
                  value={newCategoryName}
                  onChange={(e) => setNewCategoryName(e.target.value)}
                  className="flex-1 px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
                />
                <button
                  type="button"
                  disabled={isCreatingCategory || !newCategoryName.trim()}
                  onClick={handleCreateCategory}
                  className="px-3 py-2 bg-blue-600 hover:bg-blue-500 text-white rounded-xl font-semibold disabled:opacity-60 transition"
                >
                  {isCreatingCategory ? <Loader2 className="w-3.5 h-3.5 animate-spin" /> : "Save"}
                </button>
              </div>
            ) : (
              <select
                value={categoryId}
                onChange={(e) => setCategoryId(e.target.value)}
                required
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
              >
                {filteredCategories.map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.name} {c.is_default ? "(Default)" : ""}
                  </option>
                ))}
              </select>
            )}
          </div>

          {/* 4. Payment Method */}
          <div>
            <label className="font-semibold text-slate-700 block mb-1.5">Payment Method</label>
            <div className="grid grid-cols-4 gap-2">
              {[
                { key: "cash", label: "Cash", icon: Banknote },
                { key: "card", label: "Card", icon: CreditCard },
                { key: "online", label: "Online", icon: Globe },
                { key: "other", label: "Other", icon: HelpCircle },
              ].map((m) => {
                const Icon = m.icon;
                const isSelected = paymentMethod === m.key;
                return (
                  <button
                    key={m.key}
                    type="button"
                    onClick={() => setPaymentMethod(m.key as any)}
                    className={`flex flex-col items-center justify-center py-2 px-1 rounded-xl border text-[11px] font-semibold transition ${
                      isSelected
                        ? "bg-blue-50 border-blue-500 text-blue-700 shadow-sm"
                        : "bg-slate-50 border-slate-200 text-slate-600 hover:bg-slate-100"
                    }`}
                  >
                    <Icon className="w-4 h-4 mb-1" />
                    {m.label}
                  </button>
                );
              })}
            </div>
          </div>

          {/* 5. Date & Time & Added By (Audit) */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label className="font-semibold text-slate-700 block mb-1">Occurred Date & Time</label>
              <div className="relative">
                <input
                  type="datetime-local"
                  required
                  value={dateTime}
                  onChange={(e) => setDateTime(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
                />
              </div>
            </div>

            <div>
              <label className="font-semibold text-slate-700 block mb-1">Recorded By (Session)</label>
              <div className="flex items-center gap-2 px-3 py-2 bg-slate-100 border border-slate-200 rounded-xl text-slate-600 cursor-not-allowed">
                <User className="w-4 h-4 text-slate-400 shrink-0" />
                <span className="truncate font-medium">{currentUserName || "Admin"}</span>
              </div>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="pt-4 border-t border-slate-100 flex items-center justify-between gap-2">
            <button
              type="button"
              onClick={() => submitEntry(true)}
              disabled={isSubmitting}
              className="px-3.5 py-2 border border-slate-200 hover:bg-slate-50 text-slate-700 rounded-xl font-semibold transition disabled:opacity-60"
            >
              Save & Add Another
            </button>

            <div className="flex items-center gap-2">
              <button
                type="button"
                onClick={onClose}
                className="px-4 py-2 text-slate-500 hover:text-slate-800 transition"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={isSubmitting}
                className={`px-5 py-2 text-white font-bold rounded-xl shadow-md flex items-center gap-1.5 transition disabled:opacity-60 ${
                  type === "income" ? "bg-emerald-600 hover:bg-emerald-500 shadow-emerald-600/20" : "bg-rose-600 hover:bg-rose-500 shadow-rose-600/20"
                }`}
              >
                {isSubmitting && <Loader2 className="w-3.5 h-3.5 animate-spin" />}
                Save Entry (Enter)
              </button>
            </div>
          </div>
        </form>
      </div>
    </div>
  );
}

