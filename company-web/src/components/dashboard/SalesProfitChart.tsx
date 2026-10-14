"use client";

import React, { useState } from "react";
import { TrendingUp, Layers, HelpCircle } from "lucide-react";
import { ChartDataPoint } from "./types";

interface SalesProfitChartProps {
  data: ChartDataPoint[];
  periodLabel: string;
}

export function SalesProfitChart({ data, periodLabel }: SalesProfitChartProps) {
  const [activeSeries, setActiveSeries] = useState<"both" | "sales" | "profit">("both");
  const [hoveredIndex, setHoveredIndex] = useState<number | null>(null);

  const maxVal = Math.max(...data.map((d) => Math.max(d.sales, d.profit * 2.5)), 1000);

  const formatCurrency = (val: number) => {
    if (val >= 1000000) {
      return `Rs. ${(val / 1000000).toFixed(2)}M`;
    }
    if (val >= 1000) {
      return `Rs. ${(val / 1000).toFixed(0)}k`;
    }
    return `Rs. ${val.toLocaleString()}`;
  };

  const totalSales = data.reduce((acc, curr) => acc + curr.sales, 0);
  const totalProfit = data.reduce((acc, curr) => acc + curr.profit, 0);
  const overallMargin = totalSales > 0 ? ((totalProfit / totalSales) * 100).toFixed(1) : "0";

  return (
    <div className="bg-white rounded-2xl border border-slate-200 p-5 shadow-sm flex flex-col justify-between">
      {/* Chart Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 pb-4 border-b border-slate-100">
        <div>
          <div className="flex items-center gap-2">
            <h2 className="text-base font-bold text-slate-900">
              Commercial Performance Velocity
            </h2>
            <span className="text-[11px] font-semibold text-slate-500 bg-slate-100 px-2 py-0.5 rounded-full">
              {periodLabel}
            </span>
          </div>
          <p className="text-xs text-slate-500 mt-0.5">
            Compare total gross sales against net operational profit
          </p>
        </div>

        {/* Series Filter Buttons */}
        <div className="flex items-center gap-1.5 self-start sm:self-auto bg-slate-50 p-1 rounded-xl border border-slate-200/80 text-xs font-semibold">
          <button
            onClick={() => setActiveSeries("both")}
            className={`px-3 py-1 rounded-lg transition-all ${
              activeSeries === "both"
                ? "bg-white text-slate-900 shadow-sm border border-slate-200/60"
                : "text-slate-500 hover:text-slate-900"
            }`}
          >
            Combined
          </button>
          <button
            onClick={() => setActiveSeries("sales")}
            className={`flex items-center gap-1.5 px-3 py-1 rounded-lg transition-all ${
              activeSeries === "sales"
                ? "bg-blue-600 text-white shadow-sm"
                : "text-slate-500 hover:text-blue-600"
            }`}
          >
            <span className="w-2 h-2 rounded-full bg-blue-500" />
            Sales
          </button>
          <button
            onClick={() => setActiveSeries("profit")}
            className={`flex items-center gap-1.5 px-3 py-1 rounded-lg transition-all ${
              activeSeries === "profit"
                ? "bg-emerald-600 text-white shadow-sm"
                : "text-slate-500 hover:text-emerald-600"
            }`}
          >
            <span className="w-2 h-2 rounded-full bg-emerald-500" />
            Profit
          </button>
        </div>
      </div>

      {/* Summary KPI Pills */}
      <div className="grid grid-cols-2 sm:grid-cols-3 gap-3 my-4">
        <div className="p-3 bg-blue-50/50 rounded-xl border border-blue-100/60">
          <span className="text-[11px] font-semibold text-blue-700 uppercase tracking-wider block">
            Period Sales
          </span>
          <span className="text-lg font-bold text-blue-950">
            {formatCurrency(totalSales)}
          </span>
        </div>
        <div className="p-3 bg-emerald-50/50 rounded-xl border border-emerald-100/60">
          <span className="text-[11px] font-semibold text-emerald-700 uppercase tracking-wider block">
            Net Profit
          </span>
          <span className="text-lg font-bold text-emerald-950">
            {formatCurrency(totalProfit)}
          </span>
        </div>
        <div className="col-span-2 sm:col-span-1 p-3 bg-slate-50 rounded-xl border border-slate-200/60">
          <span className="text-[11px] font-semibold text-slate-500 uppercase tracking-wider block">
            Avg Margin
          </span>
          <span className="text-lg font-bold text-slate-800">
            {overallMargin}%
          </span>
        </div>
      </div>

      {/* Interactive Bar Chart Visualization */}
      <div className="relative pt-6 pb-2 min-h-[260px] flex items-end justify-between gap-2 sm:gap-4 border-b border-slate-200">
        {data.map((item, index) => {
          const salesHeightPercent = Math.min(100, Math.round((item.sales / maxVal) * 100));
          const profitHeightPercent = Math.min(100, Math.round((item.profit / maxVal) * 100));
          const isHovered = hoveredIndex === index;
          const margin = item.sales > 0 ? ((item.profit / item.sales) * 100).toFixed(1) : "0";

          return (
            <div
              key={item.label}
              className="flex-1 flex flex-col items-center justify-end h-56 relative group cursor-pointer"
              onMouseEnter={() => setHoveredIndex(index)}
              onMouseLeave={() => setHoveredIndex(null)}
            >
              {/* Tooltip on Hover */}
              {isHovered && (
                <div className="absolute -top-16 z-30 bg-slate-900 text-white text-xs rounded-xl px-3 py-2 shadow-xl whitespace-nowrap pointer-events-none transition-all">
                  <div className="font-semibold text-slate-300 text-[11px]">
                    {item.label}
                  </div>
                  <div className="flex items-center gap-3 mt-1">
                    <span className="text-blue-300 font-bold">
                      Sales: {formatCurrency(item.sales)}
                    </span>
                    <span className="text-emerald-300 font-bold">
                      Profit: {formatCurrency(item.profit)} ({margin}%)
                    </span>
                  </div>
                </div>
              )}

              {/* Bars Container */}
              <div className="w-full flex items-end justify-center gap-1 sm:gap-2 h-full">
                {/* Sales Bar */}
                {(activeSeries === "both" || activeSeries === "sales") && (
                  <div
                    style={{ height: `${salesHeightPercent}%` }}
                    className={`w-full max-w-[28px] rounded-t-lg transition-all duration-300 ${
                      isHovered
                        ? "bg-blue-600 shadow-md shadow-blue-500/30 scale-x-105"
                        : "bg-gradient-to-t from-blue-600 to-blue-400 opacity-90"
                    }`}
                  />
                )}

                {/* Profit Bar */}
                {(activeSeries === "both" || activeSeries === "profit") && (
                  <div
                    style={{ height: `${profitHeightPercent}%` }}
                    className={`w-full max-w-[28px] rounded-t-lg transition-all duration-300 ${
                      isHovered
                        ? "bg-emerald-600 shadow-md shadow-emerald-500/30 scale-x-105"
                        : "bg-gradient-to-t from-emerald-600 to-emerald-400 opacity-90"
                    }`}
                  />
                )}
              </div>

              {/* X-Axis Label */}
              <span className="text-[11px] font-medium text-slate-500 mt-2 truncate max-w-full text-center">
                {item.label}
              </span>
            </div>
          );
        })}
      </div>

      {/* Chart Footer Legend */}
      <div className="flex items-center justify-between text-xs text-slate-500 mt-3 pt-2">
        <div className="flex items-center gap-4">
          <div className="flex items-center gap-2">
            <span className="w-3 h-3 rounded-md bg-blue-500" />
            <span className="font-medium text-slate-700">Gross Sales</span>
          </div>
          <div className="flex items-center gap-2">
            <span className="w-3 h-3 rounded-md bg-emerald-500" />
            <span className="font-medium text-slate-700">Net Profit</span>
          </div>
        </div>
        <span className="hidden sm:inline-block text-[11px] text-slate-400">
          Hover over bars for granular breakdown
        </span>
      </div>
    </div>
  );
}

