"use client";

import React, { useState } from "react";
import { dashboardDatasets } from "@/components/dashboard/mockData";
import { Timeframe } from "@/components/dashboard/types";
import { TimeframeFilter } from "@/components/dashboard/TimeframeFilter";
import { StatCard } from "@/components/dashboard/StatCard";
import { SalesProfitChart } from "@/components/dashboard/SalesProfitChart";
import { CollectionsSummary } from "@/components/dashboard/CollectionsSummary";
import { OrdersBreakdown } from "@/components/dashboard/OrdersBreakdown";
import { TopProducts } from "@/components/dashboard/TopProducts";
import { RecentTransactions } from "@/components/dashboard/RecentTransactions";
import { QuickActions } from "@/components/dashboard/QuickActions";
import { Sparkles, Download, ArrowUpRight } from "lucide-react";
import Link from "next/link";

export default function CompanyExecutiveDashboard() {
  const [timeframe, setTimeframe] = useState<Timeframe>("daily");

  const currentDataset = dashboardDatasets[timeframe];
  const { metrics, chartData, collectionsBreakdown, orderStatuses, topProducts, recentTransactions, dateRange, periodLabel } = currentDataset;

  return (
    <div className="max-w-7xl mx-auto space-y-6 pb-12">
      {/* Top Banner / Welcome Bar */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4 bg-gradient-to-r from-slate-900 via-slate-800 to-indigo-950 p-6 rounded-3xl text-white shadow-xl relative overflow-hidden">
        {/* Decorative backdrop shapes */}
        <div className="absolute right-0 top-0 bottom-0 w-1/3 bg-gradient-to-l from-blue-500/10 to-transparent pointer-events-none" />
        <div className="absolute -right-8 -bottom-8 w-44 h-44 rounded-full bg-blue-600/20 blur-2xl pointer-events-none" />

        <div className="relative z-10">
          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-blue-500/20 text-blue-300 border border-blue-400/30 text-xs font-semibold mb-2">
            <Sparkles className="w-3.5 h-3.5 text-blue-400" />
            Commercial Operations Control
          </div>
          <h1 className="text-2xl sm:text-3xl font-extrabold tracking-tight text-white">
            Apex Agro Chemical Ltd.
          </h1>
          <p className="text-slate-300 text-xs sm:text-sm mt-1 max-w-xl">
            Live telemetry of field orders, multi-party khata collections, and profit velocity across your registered territories.
          </p>
        </div>

        {/* Action Buttons */}
        <div className="relative z-10 flex items-center gap-2 self-start md:self-auto">
          <button
            onClick={() => alert("Exporting Commercial Report PDF...")}
            className="flex items-center gap-1.5 px-3.5 py-2 bg-slate-800/80 hover:bg-slate-700/80 text-white rounded-xl text-xs font-semibold border border-slate-700 transition"
          >
            <Download className="w-3.5 h-3.5" />
            Export Report
          </button>
          <Link
            href="/distributors"
            className="flex items-center gap-1.5 px-4 py-2 bg-blue-600 hover:bg-blue-500 text-white rounded-xl text-xs font-semibold shadow-md shadow-blue-600/30 transition"
          >
            Distributor Network
            <ArrowUpRight className="w-3.5 h-3.5" />
          </Link>
        </div>
      </div>

      {/* Timeframe Selector & Date Range Indicator */}
      <TimeframeFilter
        activeTimeframe={timeframe}
        onTimeframeChange={setTimeframe}
        dateRange={dateRange}
      />

      {/* Quick Actions Shortcuts */}
      <QuickActions />

      {/* 4 Core KPI Stat Cards: Sales, Profit, Collections, Orders */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard type="sales" data={metrics.sales} />
        <StatCard type="profit" data={metrics.profit} />
        <StatCard type="collections" data={metrics.collections} />
        <StatCard type="orders" data={metrics.orders} />
      </div>

      {/* Analytics & Breakdown Section */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        {/* Left: Sales & Profit Interactive Trend Graph (7 cols) */}
        <div className="lg:col-span-7 space-y-6">
          <SalesProfitChart
            data={chartData}
            periodLabel={periodLabel}
          />

          {/* Top Performing SKUs Table */}
          <TopProducts products={topProducts} />
        </div>

        {/* Right: Collections Breakdown & Order Status (5 cols) */}
        <div className="lg:col-span-5 space-y-6">
          {/* Collections Recovery & Method Distribution */}
          <CollectionsSummary data={collectionsBreakdown} />

          {/* Order Fulfillment Status Breakdown */}
          <OrdersBreakdown
            statuses={orderStatuses}
            totalOrders={metrics.orders.numericValue}
          />
        </div>
      </div>

      {/* Full-width Live Activity & Recent Transactions Feed */}
      <RecentTransactions transactions={recentTransactions} />
    </div>
  );
}

