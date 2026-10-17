"use client";

import React, { useEffect, useState } from "react";
import {
  Calendar,
  CalendarDays,
  CalendarRange,
  Clock,
  RotateCcw,
  Loader2,
  Package,
  TrendingDown,
  ChevronLeft,
  ChevronRight,
  Layers,
} from "lucide-react";

export type FilterPeriodMode = "date" | "week" | "month" | "year" | "all";

interface TodaySummaryCardsProps {
  refreshTrigger: number;
  filterMode: FilterPeriodMode;
  setFilterMode: (mode: FilterPeriodMode) => void;
  selectedDate: string;
  setSelectedDate: (date: string) => void;
  selectedMonth: number;
  setSelectedMonth: (month: number) => void;
  selectedYear: number;
  setSelectedYear: (year: number) => void;
}

export interface HorizonMetric {
  costMinor: number;
  entries: number;
  quantity: number;
}

export interface LedgerSummaryData {
  date: string;
  month: number;
  year: number;
  daily: HorizonMetric;
  weekly: HorizonMetric;
  monthly: HorizonMetric;
  yearly: HorizonMetric;
  topExpenseCategory: { name: string; amountMinor: number } | null;
}

const MONTH_NAMES = [
  "January",
  "February",
  "March",
  "April",
  "May",
  "June",
  "July",
  "August",
  "September",
  "October",
  "November",
  "December",
];

const YEARS = [2024, 2025, 2026, 2027, 2028];

export function TodaySummaryCards({
  refreshTrigger,
  filterMode,
  setFilterMode,
  selectedDate,
  setSelectedDate,
  selectedMonth,
  setSelectedMonth,
  selectedYear,
  setSelectedYear,
}: TodaySummaryCardsProps) {
  const [summary, setSummary] = useState<LedgerSummaryData | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  const getTodayIso = () => {
    const now = new Date();
    const offsetMs = now.getTimezoneOffset() * 60000;
    return new Date(now.getTime() - offsetMs).toISOString().split("T")[0];
  };

  const todayIso = getTodayIso();

  useEffect(() => {
    let isMounted = true;
    async function fetchSummary() {
      setIsLoading(true);
      try {
        const params = new URLSearchParams({
          date: selectedDate,
          month: String(selectedMonth),
          year: String(selectedYear),
        });
        const res = await fetch(`/api/ledger/summary?${params.toString()}`);
        if (!res.ok) throw new Error("Failed to load summary");
        const json = await res.json();
        if (isMounted && json.data) {
          setSummary(json.data);
        }
      } catch (err) {
        console.error("Error fetching summary:", err);
      } finally {
        if (isMounted) setIsLoading(false);
      }
    }

    fetchSummary();
    return () => {
      isMounted = false;
    };
  }, [selectedDate, selectedMonth, selectedYear, refreshTrigger]);

  const formatCurrency = (minor: number) => {
    return new Intl.NumberFormat("en-PK", {
      style: "currency",
      currency: "PKR",
      maximumFractionDigits: 0,
    }).format((minor || 0) / 100);
  };

  const shiftDate = (daysDelta: number) => {
    const d = new Date(selectedDate);
    d.setDate(d.getDate() + daysDelta);
    const nextIso = d.toISOString().split("T")[0];
    setSelectedDate(nextIso);
    setSelectedMonth(d.getMonth() + 1);
    setSelectedYear(d.getFullYear());
    setFilterMode("date");
  };

  const handleResetToToday = () => {
    const d = new Date(todayIso);
    setSelectedDate(todayIso);
    setSelectedMonth(d.getMonth() + 1);
    setSelectedYear(d.getFullYear());
    setFilterMode("date");
  };

  const isToday = selectedDate === todayIso;

  return (
    <div className="space-y-4">
      {/* Unified Date / Month / Year Filter Control Bar */}
      <div className="bg-white border border-slate-200 rounded-2xl p-4 shadow-sm space-y-3">
        <div className="flex flex-wrap items-center justify-between gap-3">
          {/* Period Mode Selector Tabs */}
          <div className="flex flex-wrap items-center gap-1.5 bg-slate-100 p-1 rounded-xl">
            {[
              { id: "date", label: "Specific Date (Daily)", icon: Calendar },
              { id: "week", label: "Weekly (7 Days)", icon: Clock },
              { id: "month", label: "Monthly View", icon: CalendarDays },
              { id: "year", label: "Yearly View", icon: CalendarRange },
              { id: "all", label: "All Time", icon: Layers },
            ].map((tab) => {
              const Icon = tab.icon;
              const active = filterMode === tab.id;
              return (
                <button
                  key={tab.id}
                  type="button"
                  onClick={() => setFilterMode(tab.id as FilterPeriodMode)}
                  className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold transition-all ${
                    active
                      ? "bg-white text-emerald-700 shadow-sm border border-emerald-200"
                      : "text-slate-600 hover:text-slate-900"
                  }`}
                >
                  <Icon className={`w-3.5 h-3.5 ${active ? "text-emerald-600" : "text-slate-400"}`} />
                  <span>{tab.label}</span>
                </button>
              );
            })}
          </div>

          {isLoading && (
            <div className="flex items-center gap-1.5 text-xs text-slate-500">
              <Loader2 className="w-4 h-4 animate-spin text-emerald-600" />
              <span>Updating totals...</span>
            </div>
          )}
        </div>

        {/* Specific Date, Month, and Year Selectors */}
        <div className="flex flex-wrap items-center justify-between gap-3 pt-2 border-t border-slate-100">
          {/* 1. Date Picker (Day Filter) */}
          <div className="flex flex-wrap items-center gap-2">
            <span className="text-xs font-bold text-slate-600">Filter by Date:</span>
            <div className="flex items-center gap-1">
              <button
                type="button"
                onClick={() => shiftDate(-1)}
                title="Previous Day"
                className="p-1.5 rounded-lg border border-slate-200 hover:bg-slate-50 text-slate-600"
              >
                <ChevronLeft className="w-3.5 h-3.5" />
              </button>
              <input
                type="date"
                value={selectedDate}
                onChange={(e) => {
                  const val = e.target.value;
                  if (val) {
                    setSelectedDate(val);
                    const d = new Date(val);
                    setSelectedMonth(d.getMonth() + 1);
                    setSelectedYear(d.getFullYear());
                    setFilterMode("date");
                  }
                }}
                className={`px-3 py-1.5 rounded-lg text-xs font-mono font-bold border transition ${
                  filterMode === "date"
                    ? "bg-emerald-50 border-emerald-500 text-emerald-900 ring-2 ring-emerald-500/15"
                    : "bg-slate-50 border-slate-200 text-slate-700"
                }`}
              />
              <button
                type="button"
                onClick={() => shiftDate(1)}
                title="Next Day"
                className="p-1.5 rounded-lg border border-slate-200 hover:bg-slate-50 text-slate-600"
              >
                <ChevronRight className="w-3.5 h-3.5" />
              </button>
              {!isToday && (
                <button
                  type="button"
                  onClick={handleResetToToday}
                  className="flex items-center gap-1 px-2.5 py-1.5 rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-semibold transition"
                >
                  <RotateCcw className="w-3 h-3" />
                  <span>Today</span>
                </button>
              )}
            </div>
          </div>

          {/* 2. Month & Year Selectors */}
          <div className="flex flex-wrap items-center gap-3">
            <div className="flex items-center gap-1.5">
              <span className="text-xs font-bold text-slate-600">Month:</span>
              <select
                value={selectedMonth}
                onChange={(e) => {
                  setSelectedMonth(Number(e.target.value));
                  setFilterMode("month");
                }}
                className={`px-3 py-1.5 rounded-lg text-xs font-bold border transition ${
                  filterMode === "month"
                    ? "bg-emerald-50 border-emerald-500 text-emerald-900 ring-2 ring-emerald-500/15"
                    : "bg-slate-50 border-slate-200 text-slate-700"
                }`}
              >
                {MONTH_NAMES.map((name, idx) => (
                  <option key={name} value={idx + 1}>
                    {name}
                  </option>
                ))}
              </select>
            </div>

            <div className="flex items-center gap-1.5">
              <span className="text-xs font-bold text-slate-600">Year:</span>
              <select
                value={selectedYear}
                onChange={(e) => {
                  setSelectedYear(Number(e.target.value));
                  if (filterMode !== "month") {
                    setFilterMode("year");
                  }
                }}
                className={`px-3 py-1.5 rounded-lg text-xs font-mono font-bold border transition ${
                  filterMode === "year" || filterMode === "month"
                    ? "bg-emerald-50 border-emerald-500 text-emerald-900 ring-2 ring-emerald-500/15"
                    : "bg-slate-50 border-slate-200 text-slate-700"
                }`}
              >
                {YEARS.map((y) => (
                  <option key={y} value={y}>
                    {y}
                  </option>
                ))}
              </select>
            </div>
          </div>
        </div>
      </div>

      {/* 4 Expense Tracking Cards: Daily, Weekly, Monthly, Yearly (Click any card to filter table!) */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* 1. Daily Expenses Card */}
        <div
          onClick={() => setFilterMode("date")}
          className={`cursor-pointer bg-white rounded-2xl p-5 border transition-all shadow-sm ${
            filterMode === "date"
              ? "border-emerald-500 ring-2 ring-emerald-500/15"
              : "border-slate-200 hover:border-emerald-300"
          }`}
        >
          <div className="flex items-center justify-between">
            <span className="text-[11px] font-bold text-slate-500 uppercase tracking-wider">
              {isToday ? "Today's Total Cost" : `Cost on ${selectedDate}`}
            </span>
            <div className="p-2 rounded-xl bg-emerald-50 text-emerald-600 border border-emerald-200">
              <Calendar className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-3">
            <div className="text-2xl font-extrabold font-mono text-slate-900">
              {summary ? formatCurrency(summary.daily.costMinor) : "..."}
            </div>
            <div className="flex items-center justify-between mt-1.5 text-xs text-slate-500">
              <span className="font-semibold text-emerald-700">
                {summary ? `${summary.daily.entries} items brought` : "..."}
              </span>
              <span className="font-mono text-[11px]">
                Qty: {summary ? summary.daily.quantity : 0}
              </span>
            </div>
          </div>
        </div>

        {/* 2. Weekly Expenses Card */}
        <div
          onClick={() => setFilterMode("week")}
          className={`cursor-pointer bg-white rounded-2xl p-5 border transition-all shadow-sm ${
            filterMode === "week"
              ? "border-blue-500 ring-2 ring-blue-500/15"
              : "border-slate-200 hover:border-blue-300"
          }`}
        >
          <div className="flex items-center justify-between">
            <span className="text-[11px] font-bold text-slate-500 uppercase tracking-wider">
              Weekly Expense (7 Days)
            </span>
            <div className="p-2 rounded-xl bg-blue-50 text-blue-600 border border-blue-200">
              <Clock className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-3">
            <div className="text-2xl font-extrabold font-mono text-slate-900">
              {summary ? formatCurrency(summary.weekly.costMinor) : "..."}
            </div>
            <div className="flex items-center justify-between mt-1.5 text-xs text-slate-500">
              <span className="font-semibold text-blue-700">
                {summary ? `${summary.weekly.entries} items brought` : "..."}
              </span>
              <span className="font-mono text-[11px]">
                Qty: {summary ? summary.weekly.quantity : 0}
              </span>
            </div>
          </div>
        </div>

        {/* 3. Monthly Expenses Card */}
        <div
          onClick={() => setFilterMode("month")}
          className={`cursor-pointer bg-white rounded-2xl p-5 border transition-all shadow-sm ${
            filterMode === "month"
              ? "border-purple-500 ring-2 ring-purple-500/15"
              : "border-slate-200 hover:border-purple-300"
          }`}
        >
          <div className="flex items-center justify-between">
            <span className="text-[11px] font-bold text-slate-500 uppercase tracking-wider">
              {MONTH_NAMES[selectedMonth - 1]} {selectedYear} Cost
            </span>
            <div className="p-2 rounded-xl bg-purple-50 text-purple-600 border border-purple-200">
              <CalendarDays className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-3">
            <div className="text-2xl font-extrabold font-mono text-slate-900">
              {summary ? formatCurrency(summary.monthly.costMinor) : "..."}
            </div>
            <div className="flex items-center justify-between mt-1.5 text-xs text-slate-500">
              <span className="font-semibold text-purple-700">
                {summary ? `${summary.monthly.entries} items in month` : "..."}
              </span>
              <span className="font-mono text-[11px]">
                Qty: {summary ? summary.monthly.quantity : 0}
              </span>
            </div>
          </div>
        </div>

        {/* 4. Yearly Expenses Card */}
        <div
          onClick={() => setFilterMode("year")}
          className={`cursor-pointer bg-white rounded-2xl p-5 border transition-all shadow-sm ${
            filterMode === "year"
              ? "border-amber-500 ring-2 ring-amber-500/15"
              : "border-slate-200 hover:border-amber-300"
          }`}
        >
          <div className="flex items-center justify-between">
            <span className="text-[11px] font-bold text-slate-500 uppercase tracking-wider">
              Year {selectedYear} Total Cost
            </span>
            <div className="p-2 rounded-xl bg-amber-50 text-amber-600 border border-amber-200">
              <CalendarRange className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-3">
            <div className="text-2xl font-extrabold font-mono text-slate-900">
              {summary ? formatCurrency(summary.yearly.costMinor) : "..."}
            </div>
            <div className="flex items-center justify-between mt-1.5 text-xs text-slate-500">
              <span className="font-semibold text-amber-700">
                {summary ? `${summary.yearly.entries} items in ${selectedYear}` : "..."}
              </span>
              <span className="truncate max-w-[120px]" title={summary?.topExpenseCategory?.name}>
                Top: {summary?.topExpenseCategory?.name || "None"}
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
