"use client";

import React from "react";
import { Calendar, Clock, BarChart3 } from "lucide-react";
import { Timeframe } from "./types";

interface TimeframeFilterProps {
  activeTimeframe: Timeframe;
  onTimeframeChange: (timeframe: Timeframe) => void;
  dateRange: string;
}

export function TimeframeFilter({
  activeTimeframe,
  onTimeframeChange,
  dateRange,
}: TimeframeFilterProps) {
  const options: { id: Timeframe; label: string; icon: React.ElementType }[] = [
    { id: "daily", label: "Daily", icon: Clock },
    { id: "weekly", label: "Weekly", icon: BarChart3 },
    { id: "monthly", label: "Monthly", icon: Calendar },
  ];

  return (
    <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 bg-white p-3 sm:p-4 rounded-2xl border border-slate-200 shadow-sm">
      {/* Date Range Description */}
      <div className="flex items-center gap-2.5">
        <div className="w-9 h-9 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center shrink-0">
          <Calendar className="w-4 h-4" />
        </div>
        <div>
          <span className="text-xs font-semibold uppercase tracking-wider text-slate-400">
            Reporting Window
          </span>
          <div className="text-sm font-bold text-slate-800">{dateRange}</div>
        </div>
      </div>

      {/* Tab Switcher */}
      <div className="inline-flex p-1 bg-slate-100 rounded-xl border border-slate-200/60 self-start sm:self-auto">
        {options.map((opt) => {
          const isActive = activeTimeframe === opt.id;
          const Icon = opt.icon;
          return (
            <button
              key={opt.id}
              onClick={() => onTimeframeChange(opt.id)}
              className={`flex items-center gap-1.5 px-3.5 py-1.5 rounded-lg text-xs font-semibold transition-all ${
                isActive
                  ? "bg-white text-blue-600 shadow-sm shadow-slate-200"
                  : "text-slate-600 hover:text-slate-900 hover:bg-slate-200/50"
              }`}
            >
              <Icon className="w-3.5 h-3.5" />
              <span>{opt.label}</span>
            </button>
          );
        })}
      </div>
    </div>
  );
}

