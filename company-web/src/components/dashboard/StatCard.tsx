"use client";

import React from "react";
import {
  TrendingUp,
  TrendingDown,
  DollarSign,
  Briefcase,
  Wallet,
  ShoppingBag,
} from "lucide-react";
import { MetricSummary } from "./types";

interface StatCardProps {
  type: "sales" | "profit" | "collections" | "orders";
  data: MetricSummary;
}

const config = {
  sales: {
    icon: DollarSign,
    iconBg: "bg-blue-50 text-blue-600 border-blue-200",
    gradient: "from-blue-500/10 to-indigo-500/0",
    accentBorder: "hover:border-blue-400",
  },
  profit: {
    icon: TrendingUp,
    iconBg: "bg-emerald-50 text-emerald-600 border-emerald-200",
    gradient: "from-emerald-500/10 to-teal-500/0",
    accentBorder: "hover:border-emerald-400",
  },
  collections: {
    icon: Wallet,
    iconBg: "bg-violet-50 text-violet-600 border-violet-200",
    gradient: "from-violet-500/10 to-purple-500/0",
    accentBorder: "hover:border-violet-400",
  },
  orders: {
    icon: ShoppingBag,
    iconBg: "bg-amber-50 text-amber-600 border-amber-200",
    gradient: "from-amber-500/10 to-yellow-500/0",
    accentBorder: "hover:border-amber-400",
  },
};

export function StatCard({ type, data }: StatCardProps) {
  const currentConfig = config[type];
  const Icon = currentConfig.icon;

  return (
    <div
      className={`relative overflow-hidden bg-white rounded-2xl border border-slate-200 p-5 shadow-sm transition-all duration-200 ${currentConfig.accentBorder} group`}
    >
      {/* Background soft tint */}
      <div
        className={`absolute inset-0 bg-gradient-to-br ${currentConfig.gradient} opacity-50 pointer-events-none`}
      />

      <div className="relative z-10 flex flex-col h-full justify-between">
        {/* Header: Title & Icon */}
        <div className="flex items-center justify-between gap-2">
          <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider">
            {data.title}
          </span>
          <div
            className={`w-9 h-9 rounded-xl flex items-center justify-center border ${currentConfig.iconBg} transition-transform group-hover:scale-110 shadow-sm`}
          >
            <Icon className="w-4 h-4" />
          </div>
        </div>

        {/* Primary Value & Trend Badge */}
        <div className="my-3">
          <div className="text-2xl lg:text-3xl font-extrabold text-slate-900 tracking-tight">
            {data.value}
          </div>

          <div className="flex items-center gap-2 mt-2">
            <span
              className={`inline-flex items-center gap-1 text-xs font-semibold px-2 py-0.5 rounded-full ${
                data.isPositive
                  ? "bg-emerald-50 text-emerald-700 border border-emerald-200"
                  : "bg-rose-50 text-rose-700 border border-rose-200"
              }`}
            >
              {data.isPositive ? (
                <TrendingUp className="w-3 h-3" />
              ) : (
                <TrendingDown className="w-3 h-3" />
              )}
              {data.isPositive ? "+" : "-"}
              {Math.abs(data.changePercent)}%
            </span>
            <span className="text-xs text-slate-500 truncate">
              {data.comparedTo}
            </span>
          </div>
        </div>

        {/* Footer Sub-metrics */}
        <div className="pt-3 border-t border-slate-100 flex items-center justify-between text-xs text-slate-600">
          <span className="truncate">{data.subText}</span>
          {data.secondaryMetric && (
            <span className="font-semibold text-slate-800 text-[11px] bg-slate-50 px-2 py-0.5 rounded border border-slate-200/60 shrink-0">
              {data.secondaryMetric.value}
            </span>
          )}
        </div>
      </div>
    </div>
  );
}

