"use client";

import React, { useState, useEffect } from "react";
import {
  TrendingUp,
  TrendingDown,
  DollarSign,
  Receipt,
  PieChart,
  Calendar,
  RotateCcw,
  CreditCard,
  Banknote,
  Globe,
  HelpCircle,
  Loader2,
} from "lucide-react";

interface TodaySummaryCardsProps {
  refreshTrigger: number;
}

export interface LedgerSummaryData {
  date: string;
  totalIncomeMinor: number;
  totalExpenseMinor: number;
  netMinor: number;
  count: number;
  topExpenseCategory: { name: string; amountMinor: number } | null;
  paymentSplit: { cash: number; card: number; online: number; other: number };
}

export function TodaySummaryCards({ refreshTrigger }: TodaySummaryCardsProps) {
  const getTodayIso = () => {
    const now = new Date();
    const offsetMs = now.getTimezoneOffset() * 60000;
    return new Date(now.getTime() - offsetMs).toISOString().split("T")[0];
  };

  const todayIso = getTodayIso();
  const [selectedDate, setSelectedDate] = useState(todayIso);
  const [summary, setSummary] = useState<LedgerSummaryData | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let isMounted = true;
    async function fetchSummary() {
      setIsLoading(true);
      setError(null);
      try {
        const res = await fetch(`/api/ledger/summary?date=${selectedDate}`);
        if (!res.ok) {
          throw new Error("Failed to load daily summary");
        }
        const data = await res.json();
        if (isMounted) {
          setSummary(data.data);
        }
      } catch (err: any) {
        if (isMounted) {
          setError(err.message || "Error fetching summary");
        }
      } finally {
        if (isMounted) setIsLoading(false);
      }
    }

    fetchSummary();
    return () => {
      isMounted = false;
    };
  }, [selectedDate, refreshTrigger]);

  const formatCurrency = (minor: number) => {
    return new Intl.NumberFormat("en-PK", {
      style: "currency",
      currency: "PKR",
      maximumFractionDigits: 0,
    }).format(minor / 100);
  };

  const isSelectedToday = selectedDate === todayIso;

  const totalPaymentMinor =
    (summary?.paymentSplit.cash || 0) +
    (summary?.paymentSplit.card || 0) +
    (summary?.paymentSplit.online || 0) +
    (summary?.paymentSplit.other || 0);

  return (
    <div className="space-y-4">
      {/* Date Filter Bar */}
      <div className="flex flex-wrap items-center justify-between gap-3 bg-slate-900 border border-slate-800 rounded-xl p-3 px-4">
        <div className="flex items-center gap-2 text-sm text-slate-300 font-medium">
          <Calendar className="w-4 h-4 text-emerald-400" />
          <span>Daily Performance View:</span>
          <span className="font-semibold text-white">
            {isSelectedToday ? "Today" : selectedDate}
          </span>
        </div>

        <div className="flex items-center gap-2">
          <input
            type="date"
            value={selectedDate}
            onChange={(e) => setSelectedDate(e.target.value)}
            className="px-3 py-1.5 bg-slate-950 border border-slate-700 rounded-lg text-xs font-mono text-slate-200 focus:outline-none focus:ring-1 focus:ring-emerald-500"
          />
          {!isSelectedToday && (
            <button
              onClick={() => setSelectedDate(todayIso)}
              className="flex items-center gap-1.5 px-3 py-1.5 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded-lg text-xs font-medium border border-slate-700 transition"
            >
              <RotateCcw className="w-3.5 h-3.5" />
              <span>Back to Today</span>
            </button>
          )}
          {isLoading && <Loader2 className="w-4 h-4 text-slate-400 animate-spin ml-1" />}
        </div>
      </div>

      {/* Cards Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Income Card */}
        <div className="bg-slate-900 border border-slate-800 rounded-xl p-5 relative overflow-hidden group hover:border-emerald-500/40 transition">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">
              {isSelectedToday ? "Today's Income" : "Day Income"}
            </span>
            <div className="p-2 rounded-lg bg-emerald-500/10 border border-emerald-500/20 text-emerald-400">
              <TrendingUp className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-3">
            <div className="text-2xl font-bold font-mono text-emerald-400">
              {summary ? `+${formatCurrency(summary.totalIncomeMinor)}` : "..."}
            </div>
            <p className="text-xs text-slate-500 mt-1">Inflow from all sales & cash</p>
          </div>
          <div className="absolute top-0 right-0 w-24 h-24 bg-emerald-500/5 rounded-full blur-2xl pointer-events-none" />
        </div>

        {/* Expense Card */}
        <div className="bg-slate-900 border border-slate-800 rounded-xl p-5 relative overflow-hidden group hover:border-rose-500/40 transition">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">
              {isSelectedToday ? "Today's Expenses" : "Day Expenses"}
            </span>
            <div className="p-2 rounded-lg bg-rose-500/10 border border-rose-500/20 text-rose-400">
              <TrendingDown className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-3">
            <div className="text-2xl font-bold font-mono text-rose-400">
              {summary ? `-${formatCurrency(summary.totalExpenseMinor)}` : "..."}
            </div>
            <p className="text-xs text-slate-500 mt-1">
              Top:{" "}
              <span className="text-slate-300 font-medium">
                {summary?.topExpenseCategory
                  ? `${summary.topExpenseCategory.name} (${formatCurrency(
                      summary.topExpenseCategory.amountMinor
                    )})`
                  : "None recorded"}
              </span>
            </p>
          </div>
          <div className="absolute top-0 right-0 w-24 h-24 bg-rose-500/5 rounded-full blur-2xl pointer-events-none" />
        </div>

        {/* Net Today Card */}
        <div className="bg-slate-900 border border-slate-800 rounded-xl p-5 relative overflow-hidden group hover:border-blue-500/40 transition">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">
              {isSelectedToday ? "Net Cash Flow" : "Day Net Margin"}
            </span>
            <div className="p-2 rounded-lg bg-blue-500/10 border border-blue-500/20 text-blue-400">
              <DollarSign className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-3">
            <div
              className={`text-2xl font-bold font-mono ${
                (summary?.netMinor || 0) >= 0 ? "text-blue-400" : "text-amber-400"
              }`}
            >
              {summary
                ? (summary.netMinor >= 0 ? "+" : "") + formatCurrency(summary.netMinor)
                : "..."}
            </div>
            <p className="text-xs text-slate-500 mt-1">Income minus operational expenses</p>
          </div>
          <div className="absolute top-0 right-0 w-24 h-24 bg-blue-500/5 rounded-full blur-2xl pointer-events-none" />
        </div>

        {/* Transactions & Payment Split */}
        <div className="bg-slate-900 border border-slate-800 rounded-xl p-5 relative overflow-hidden group hover:border-purple-500/40 transition">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">
              Activity & Channels
            </span>
            <div className="p-2 rounded-lg bg-purple-500/10 border border-purple-500/20 text-purple-400">
              <Receipt className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-2 space-y-2">
            <div className="flex items-baseline justify-between">
              <span className="text-xl font-bold font-mono text-white">
                {summary ? `${summary.count} entries` : "..."}
              </span>
              <span className="text-xs text-slate-400 font-medium">Valid entries</span>
            </div>

            {/* Micro split bars */}
            {summary && totalPaymentMinor > 0 ? (
              <div className="pt-1 space-y-1">
                <div className="h-1.5 w-full bg-slate-800 rounded-full overflow-hidden flex">
                  <div
                    style={{
                      width: `${(summary.paymentSplit.cash / totalPaymentMinor) * 100}%`,
                    }}
                    className="bg-emerald-500"
                    title="Cash"
                  />
                  <div
                    style={{
                      width: `${(summary.paymentSplit.card / totalPaymentMinor) * 100}%`,
                    }}
                    className="bg-blue-500"
                    title="Card"
                  />
                  <div
                    style={{
                      width: `${(summary.paymentSplit.online / totalPaymentMinor) * 100}%`,
                    }}
                    className="bg-purple-500"
                    title="Online"
                  />
                  <div
                    style={{
                      width: `${(summary.paymentSplit.other / totalPaymentMinor) * 100}%`,
                    }}
                    className="bg-slate-500"
                    title="Other"
                  />
                </div>
                <div className="flex justify-between text-[10px] text-slate-400 font-mono">
                  <span>Cash: {formatCurrency(summary.paymentSplit.cash)}</span>
                  <span>Card: {formatCurrency(summary.paymentSplit.card)}</span>
                  <span>Online: {formatCurrency(summary.paymentSplit.online)}</span>
                </div>
              </div>
            ) : (
              <p className="text-[11px] text-slate-500 italic pt-1">
                No transaction channels recorded yet.
              </p>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

