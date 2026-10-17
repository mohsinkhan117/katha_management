"use client";

import React, { useState, useEffect } from "react";
import {
  BarChart3,
  PieChart as PieIcon,
  CreditCard,
  Loader2,
  Calendar,
  Layers,
  ArrowUpRight,
  ArrowDownRight,
} from "lucide-react";

interface LedgerChartsProps {
  refreshTrigger: number;
}

interface DailyItem {
  date: string;
  incomeMinor: number;
  expenseMinor: number;
  netMinor: number;
}

interface CategoryItem {
  name: string;
  amountMinor: number;
  type: "income" | "expense";
}

interface ChartData {
  range: "7d" | "30d" | "90d";
  dailySeries: DailyItem[];
  categories: CategoryItem[];
  paymentSplit: { cash: number; card: number; online: number; other: number };
}

const CATEGORY_COLORS = [
  "#3b82f6", // blue
  "#ef4444", // red
  "#10b981", // emerald
  "#f59e0b", // amber
  "#8b5cf6", // violet
  "#ec4899", // pink
  "#06b6d4", // cyan
  "#14b8a6", // teal
  "#64748b", // slate
];

export function LedgerCharts({ refreshTrigger }: LedgerChartsProps) {
  const [range, setRange] = useState<"7d" | "30d" | "90d">("7d");
  const [data, setData] = useState<ChartData | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [hoveredBarIndex, setHoveredBarIndex] = useState<number | null>(null);

  useEffect(() => {
    let isMounted = true;
    async function fetchChart() {
      setIsLoading(true);
      try {
        const res = await fetch(`/api/ledger/chart?range=${range}`);
        if (!res.ok) throw new Error("Failed to load chart data");
        const json = await res.json();
        if (isMounted) setData(json.data);
      } catch (err) {
        console.error("Error loading chart data:", err);
      } finally {
        if (isMounted) setIsLoading(false);
      }
    }

    fetchChart();
    return () => {
      isMounted = false;
    };
  }, [range, refreshTrigger]);

  const formatCurrency = (minor: number) => {
    return new Intl.NumberFormat("en-PK", {
      style: "currency",
      currency: "PKR",
      maximumFractionDigits: 0,
    }).format(minor / 100);
  };

  const daily = data?.dailySeries || [];
  const maxMinor = Math.max(
    ...daily.map((d) => Math.max(d.incomeMinor, d.expenseMinor)),
    100000 // default minimum scale (1000 PKR)
  );

  // Expense categories calculation
  const expenseCategories = (data?.categories || [])
    .filter((c) => c.type === "expense")
    .sort((a, b) => b.amountMinor - a.amountMinor);

  const totalExpenseMinor = expenseCategories.reduce((sum, c) => sum + c.amountMinor, 0);

  // Donut SVG calculations
  let accumulatedAngle = 0;
  const donutSlices = expenseCategories.map((c, i) => {
    const fraction = totalExpenseMinor > 0 ? c.amountMinor / totalExpenseMinor : 0;
    const angle = fraction * 360;
    const startAngle = accumulatedAngle;
    accumulatedAngle += angle;

    // SVG arc calculation (radius: 40, center: 50, 50)
    const r = 40;
    const cx = 50;
    const cy = 50;
    const startRad = ((startAngle - 90) * Math.PI) / 180;
    const endRad = ((startAngle + angle - 90) * Math.PI) / 180;

    const x1 = cx + r * Math.cos(startRad);
    const y1 = cy + r * Math.sin(startRad);
    const x2 = cx + r * Math.cos(endRad);
    const y2 = cy + r * Math.sin(endRad);

    const largeArcFlag = angle > 180 ? 1 : 0;
    const pathData =
      fraction >= 0.999
        ? `M ${cx} ${cy - r} A ${r} ${r} 0 1 1 ${cx - 0.001} ${cy - r} Z`
        : `M ${cx} ${cy} L ${x1} ${y1} A ${r} ${r} 0 ${largeArcFlag} 1 ${x2} ${y2} Z`;

    return {
      name: c.name,
      amountMinor: c.amountMinor,
      percentage: Math.round(fraction * 100),
      pathData,
      color: CATEGORY_COLORS[i % CATEGORY_COLORS.length],
    };
  });

  return (
    <div className="bg-slate-900 border border-slate-800 rounded-xl p-5 space-y-6">
      {/* Chart Header & Controls */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-slate-800">
        <div className="space-y-1">
          <div className="flex items-center gap-2">
            <BarChart3 className="w-5 h-5 text-emerald-400" />
            <h3 className="font-semibold text-white">Cash Flow & Expense Analytics</h3>
          </div>
          <p className="text-xs text-slate-400">
            Compare daily income vs operational expenses and discover major spending buckets.
          </p>
        </div>

        {/* Range Pill Selector */}
        <div className="flex items-center bg-slate-950 p-1 rounded-lg border border-slate-800 self-start sm:self-auto">
          {(["7d", "30d", "90d"] as const).map((r) => (
            <button
              key={r}
              onClick={() => setRange(r)}
              className={`px-3 py-1 text-xs font-semibold rounded-md transition ${
                range === r
                  ? "bg-slate-800 text-white shadow-sm"
                  : "text-slate-400 hover:text-slate-200"
              }`}
            >
              {r === "7d" ? "7 Days" : r === "30d" ? "30 Days" : "90 Days"}
            </button>
          ))}
        </div>
      </div>

      {isLoading ? (
        <div className="h-64 flex flex-col items-center justify-center gap-2 text-slate-400">
          <Loader2 className="w-6 h-6 animate-spin text-emerald-500" />
          <span className="text-xs">Calculating metrics...</span>
        </div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Main Trend: Daily Income vs Expense Bars (2 cols) */}
          <div className="lg:col-span-2 space-y-3">
            <div className="flex items-center justify-between text-xs text-slate-400">
              <span className="font-medium text-slate-300">Daily Cash Movement</span>
              <div className="flex items-center gap-4">
                <span className="flex items-center gap-1.5">
                  <span className="w-2.5 h-2.5 rounded-sm bg-emerald-500 inline-block" />
                  Income
                </span>
                <span className="flex items-center gap-1.5">
                  <span className="w-2.5 h-2.5 rounded-sm bg-rose-500 inline-block" />
                  Expense
                </span>
              </div>
            </div>

            {/* SVG / Flex Bar Chart */}
            <div className="h-56 relative bg-slate-950/60 border border-slate-800/80 rounded-xl p-4 flex items-end justify-between gap-1 sm:gap-2">
              {daily.map((item, idx) => {
                const incomeHeightPct = Math.min(100, Math.round((item.incomeMinor / maxMinor) * 100));
                const expenseHeightPct = Math.min(100, Math.round((item.expenseMinor / maxMinor) * 100));
                const isHovered = hoveredBarIndex === idx;

                const dayLabel = new Date(item.date).toLocaleDateString("en-US", {
                  month: range === "7d" ? "short" : "numeric",
                  day: "numeric",
                });

                return (
                  <div
                    key={item.date}
                    onMouseEnter={() => setHoveredBarIndex(idx)}
                    onMouseLeave={() => setHoveredBarIndex(null)}
                    className="relative flex-1 h-full flex flex-col justify-end items-center group cursor-pointer"
                  >
                    {/* Tooltip */}
                    {isHovered && (
                      <div className="absolute bottom-full mb-2 z-20 w-44 bg-slate-900 border border-slate-700 p-2.5 rounded-lg shadow-2xl text-[11px] pointer-events-none transform -translate-x-1/2 left-1/2">
                        <div className="font-semibold text-slate-200 pb-1 border-b border-slate-800 font-mono">
                          {new Date(item.date).toDateString()}
                        </div>
                        <div className="space-y-1 pt-1.5 font-mono">
                          <div className="flex justify-between text-emerald-400">
                            <span>Income:</span>
                            <span>+{formatCurrency(item.incomeMinor)}</span>
                          </div>
                          <div className="flex justify-between text-rose-400">
                            <span>Expense:</span>
                            <span>-{formatCurrency(item.expenseMinor)}</span>
                          </div>
                          <div className="flex justify-between text-slate-300 font-semibold pt-1 border-t border-slate-800/60">
                            <span>Net:</span>
                            <span className={item.netMinor >= 0 ? "text-emerald-400" : "text-rose-400"}>
                              {item.netMinor >= 0 ? "+" : ""}
                              {formatCurrency(item.netMinor)}
                            </span>
                          </div>
                        </div>
                      </div>
                    )}

                    {/* Bars Side by Side */}
                    <div className="w-full flex items-end justify-center gap-1 h-full pb-5">
                      <div
                        style={{ height: `${Math.max(incomeHeightPct, 4)}%` }}
                        className={`w-full max-w-[12px] bg-emerald-500 rounded-t-sm transition-all duration-300 ${
                          isHovered ? "bg-emerald-400 scale-y-105" : "opacity-90"
                        }`}
                      />
                      <div
                        style={{ height: `${Math.max(expenseHeightPct, 4)}%` }}
                        className={`w-full max-w-[12px] bg-rose-500 rounded-t-sm transition-all duration-300 ${
                          isHovered ? "bg-rose-400 scale-y-105" : "opacity-90"
                        }`}
                      />
                    </div>

                    {/* X-Axis Date */}
                    <span className="absolute bottom-0 text-[10px] font-mono text-slate-500 group-hover:text-slate-300 truncate max-w-full">
                      {range === "90d" && idx % 7 !== 0 ? "" : dayLabel}
                    </span>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Expense Breakdown: Donut Chart & Categories (1 col) */}
          <div className="space-y-3">
            <div className="flex items-center justify-between text-xs text-slate-400">
              <span className="font-medium text-slate-300">Expense Breakdown</span>
              <span className="font-mono text-rose-400 font-semibold">
                {formatCurrency(totalExpenseMinor)}
              </span>
            </div>

            <div className="bg-slate-950/60 border border-slate-800/80 rounded-xl p-4 flex flex-col justify-between h-56">
              {totalExpenseMinor > 0 ? (
                <div className="flex items-center gap-4 h-full">
                  {/* SVG Donut */}
                  <div className="relative w-28 h-28 shrink-0">
                    <svg viewBox="0 0 100 100" className="w-full h-full transform -rotate-90">
                      {donutSlices.map((slice, i) => (
                        <path
                          key={i}
                          d={slice.pathData}
                          fill={slice.color}
                          className="hover:opacity-80 transition cursor-pointer"
                        >
                          <title>{`${slice.name}: ${formatCurrency(slice.amountMinor)} (${slice.percentage}%)`}</title>
                        </path>
                      ))}
                      {/* Inner circle cutout for donut effect */}
                      <circle cx="50" cy="50" r="24" fill="#020617" />
                    </svg>
                    <div className="absolute inset-0 flex flex-col items-center justify-center text-center pointer-events-none">
                      <span className="text-[9px] uppercase tracking-wider text-slate-500 font-bold">Total</span>
                      <span className="text-[10px] font-mono font-bold text-white">
                        {expenseCategories.length} cats
                      </span>
                    </div>
                  </div>

                  {/* Top Categories List */}
                  <div className="flex-1 overflow-y-auto max-h-44 space-y-1.5 pr-1">
                    {donutSlices.slice(0, 5).map((slice, i) => (
                      <div key={i} className="flex items-center justify-between text-[11px]">
                        <div className="flex items-center gap-1.5 truncate">
                          <span
                            className="w-2 h-2 rounded-full shrink-0"
                            style={{ backgroundColor: slice.color }}
                          />
                          <span className="text-slate-300 truncate" title={slice.name}>
                            {slice.name}
                          </span>
                        </div>
                        <span className="font-mono text-slate-400 font-medium shrink-0 ml-1">
                          {slice.percentage}%
                        </span>
                      </div>
                    ))}
                  </div>
                </div>
              ) : (
                <div className="h-full flex flex-col items-center justify-center text-center text-xs text-slate-500">
                  <PieIcon className="w-8 h-8 text-slate-700 mb-2" />
                  <span>No expenses recorded in this period.</span>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

