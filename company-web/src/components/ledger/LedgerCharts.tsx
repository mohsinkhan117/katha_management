"use client";

import React, { useState, useEffect } from "react";
import { BarChart3, PieChart as PieIcon, Loader2 } from "lucide-react";

import { useUser } from "@stackframe/stack";
import { useTenant } from "@/context/TenantContext";

interface LedgerChartsProps {
  refreshTrigger: number;
}

interface DailyItem {
  date: string;
  label?: string;
  incomeMinor: number;
  expenseMinor: number;
  itemCount?: number;
  netMinor: number;
}

interface CategoryItem {
  name: string;
  amountMinor: number;
  count?: number;
}

interface ChartData {
  range: string;
  dailySeries: DailyItem[];
  categories: CategoryItem[];
  categoryBreakdown?: CategoryItem[];
}

const CATEGORY_COLORS = [
  "#059669", // emerald-600
  "#2563eb", // blue-600
  "#7c3aed", // violet-600
  "#d97706", // amber-600
  "#e11d48", // rose-600
  "#0891b2", // cyan-600
  "#4f46e5", // indigo-600
  "#64748b", // slate-500
];

export function LedgerCharts({ refreshTrigger }: LedgerChartsProps) {
  const user = useUser();
  const { activeTenant } = useTenant();
  const [range, setRange] = useState<"7d" | "30d" | "90d">("7d");
  const [data, setData] = useState<ChartData | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [hoveredBarIndex, setHoveredBarIndex] = useState<number | null>(null);

  useEffect(() => {
    let isMounted = true;
    async function fetchChart() {
      setIsLoading(true);
      try {
        const headers: Record<string, string> = {};
        if (activeTenant?.id) {
          headers["x-tenant-id"] = activeTenant.id;
        }
        const email = user?.primaryEmail || activeTenant?.admin_email;
        if (email) {
          headers["x-user-email"] = email;
        }
        const res = await fetch(`/api/ledger/chart?range=${range}`, {
          headers,
          credentials: "include",
        });
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
  }, [range, refreshTrigger, activeTenant?.id, user?.primaryEmail]);

  const formatCurrency = (minor: number) => {
    return new Intl.NumberFormat("en-PK", {
      style: "currency",
      currency: "PKR",
      maximumFractionDigits: 0,
    }).format((minor || 0) / 100);
  };

  const daily = data?.dailySeries || [];
  const maxMinor = Math.max(
    ...daily.map((d) => d.expenseMinor || 0),
    100000
  );

  const expenseCategories = (data?.categories || data?.categoryBreakdown || []).sort(
    (a, b) => b.amountMinor - a.amountMinor
  );

  const totalExpenseMinor = expenseCategories.reduce(
    (sum, c) => sum + c.amountMinor,
    0
  );

  let accumulatedAngle = 0;
  const donutSlices = expenseCategories.map((c, i) => {
    const fraction = totalExpenseMinor > 0 ? c.amountMinor / totalExpenseMinor : 0;
    const angle = fraction * 360;
    const startAngle = accumulatedAngle;
    accumulatedAngle += angle;

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
    <div className="bg-white border border-slate-200 rounded-2xl p-5 shadow-sm space-y-5">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-3 border-b border-slate-100">
        <div>
          <div className="flex items-center gap-2">
            <BarChart3 className="w-5 h-5 text-emerald-600" />
            <h3 className="font-bold text-slate-900">
              Daily, Weekly & Monthly Expense Trends
            </h3>
          </div>
          <p className="text-xs text-slate-500">
            Visual breakdown of hotel/party purchase costs over time and by category
          </p>
        </div>

        <div className="flex items-center bg-slate-100 p-1 rounded-xl border border-slate-200 self-start sm:self-auto">
          {(["7d", "30d", "90d"] as const).map((r) => (
            <button
              key={r}
              onClick={() => setRange(r)}
              className={`px-3 py-1 text-xs font-bold rounded-lg transition ${
                range === r
                  ? "bg-white text-emerald-700 shadow-sm border border-emerald-200"
                  : "text-slate-600 hover:text-slate-900"
              }`}
            >
              {r === "7d" ? "Weekly (7d)" : r === "30d" ? "Monthly (30d)" : "Quarterly (90d)"}
            </button>
          ))}
        </div>
      </div>

      {isLoading ? (
        <div className="h-52 flex flex-col items-center justify-center gap-2 text-slate-400">
          <Loader2 className="w-6 h-6 animate-spin text-emerald-600" />
          <span className="text-xs">Loading expense graphs...</span>
        </div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Daily Purchase Cost Trend */}
          <div className="lg:col-span-2 space-y-2">
            <div className="flex items-center justify-between text-xs text-slate-500">
              <span className="font-semibold text-slate-700">
                Daily Purchase Costs ({range === "7d" ? "Last 7 Days" : range === "30d" ? "Last 30 Days" : "Last 90 Days"})
              </span>
              <span className="flex items-center gap-1.5 font-medium">
                <span className="w-2.5 h-2.5 rounded-sm bg-emerald-600 inline-block" />
                Total Cost Brought
              </span>
            </div>

            <div className="h-52 relative bg-slate-50/70 border border-slate-200/80 rounded-xl p-4 flex items-end justify-between gap-1 sm:gap-2">
              {daily.map((item, idx) => {
                const heightPct = Math.min(
                  100,
                  Math.round((item.expenseMinor / maxMinor) * 100)
                );
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
                    {isHovered && (
                      <div className="absolute bottom-full mb-2 z-20 w-44 bg-slate-900 text-white p-2.5 rounded-xl shadow-xl text-[11px] pointer-events-none transform -translate-x-1/2 left-1/2">
                        <div className="font-bold text-slate-200 pb-1 border-b border-slate-700 font-mono">
                          {new Date(item.date).toDateString()}
                        </div>
                        <div className="space-y-1 pt-1.5 font-mono">
                          <div className="flex justify-between text-emerald-400 font-bold">
                            <span>Total Cost:</span>
                            <span>{formatCurrency(item.expenseMinor)}</span>
                          </div>
                          {item.itemCount !== undefined && (
                            <div className="flex justify-between text-slate-300">
                              <span>Items Brought:</span>
                              <span>{item.itemCount} entries</span>
                            </div>
                          )}
                        </div>
                      </div>
                    )}

                    <div className="w-full flex items-end justify-center h-full pb-5">
                      <div
                        style={{ height: `${Math.max(heightPct, 4)}%` }}
                        className={`w-full max-w-[18px] rounded-t-md transition-all duration-200 ${
                          item.expenseMinor > 0
                            ? isHovered
                              ? "bg-emerald-500 scale-y-105"
                              : "bg-emerald-600"
                            : "bg-slate-200"
                        }`}
                      />
                    </div>

                    <span className="absolute bottom-0 text-[10px] font-mono text-slate-500 truncate max-w-full">
                      {range === "90d" && idx % 7 !== 0 ? "" : dayLabel}
                    </span>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Category Breakdown Donut */}
          <div className="space-y-2">
            <div className="flex items-center justify-between text-xs">
              <span className="font-semibold text-slate-700">Cost by Category</span>
              <span className="font-mono text-emerald-700 font-bold">
                {formatCurrency(totalExpenseMinor)}
              </span>
            </div>

            <div className="bg-slate-50/70 border border-slate-200/80 rounded-xl p-4 flex flex-col justify-between h-52">
              {totalExpenseMinor > 0 ? (
                <div className="flex items-center gap-4 h-full">
                  <div className="relative w-28 h-28 shrink-0">
                    <svg
                      viewBox="0 0 100 100"
                      className="w-full h-full transform -rotate-90"
                    >
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
                      <circle cx="50" cy="50" r="24" fill="#f8fafc" />
                    </svg>
                    <div className="absolute inset-0 flex flex-col items-center justify-center text-center pointer-events-none">
                      <span className="text-[9px] uppercase tracking-wider text-slate-400 font-bold">
                        Categories
                      </span>
                      <span className="text-xs font-mono font-extrabold text-slate-800">
                        {expenseCategories.length}
                      </span>
                    </div>
                  </div>

                  <div className="flex-1 overflow-y-auto max-h-40 space-y-1.5 pr-1">
                    {donutSlices.slice(0, 6).map((slice, i) => (
                      <div
                        key={i}
                        className="flex items-center justify-between text-[11px]"
                      >
                        <div className="flex items-center gap-1.5 truncate">
                          <span
                            className="w-2.5 h-2.5 rounded-full shrink-0"
                            style={{ backgroundColor: slice.color }}
                          />
                          <span
                            className="text-slate-700 font-medium truncate"
                            title={slice.name}
                          >
                            {slice.name}
                          </span>
                        </div>
                        <span className="font-mono text-slate-600 font-bold shrink-0 ml-1">
                          {slice.percentage}%
                        </span>
                      </div>
                    ))}
                  </div>
                </div>
              ) : (
                <div className="h-full flex flex-col items-center justify-center text-center text-xs text-slate-400">
                  <PieIcon className="w-8 h-8 text-slate-300 mb-2" />
                  <span>No category expenses in this range yet.</span>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
