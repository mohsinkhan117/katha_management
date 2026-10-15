"use client";

import React, { useState } from "react";
import { dashboardDatasets, createEmptyDashboardDataset } from "@/components/dashboard/mockData";
import { Timeframe, RecentTransaction } from "@/components/dashboard/types";
import { TimeframeFilter } from "@/components/dashboard/TimeframeFilter";
import { StatCard } from "@/components/dashboard/StatCard";
import { SalesProfitChart } from "@/components/dashboard/SalesProfitChart";
import { CollectionsSummary } from "@/components/dashboard/CollectionsSummary";
import { OrdersBreakdown } from "@/components/dashboard/OrdersBreakdown";
import { TopProducts } from "@/components/dashboard/TopProducts";
import { RecentTransactions } from "@/components/dashboard/RecentTransactions";
import { QuickActions } from "@/components/dashboard/QuickActions";
import { Sparkles, Download, ArrowUpRight, ShieldCheck, Database, Info } from "lucide-react";
import Link from "next/link";
import { useTenant } from "@/context/TenantContext";

export default function CompanyExecutiveDashboard() {
  const [timeframe, setTimeframe] = useState<Timeframe>("daily");
  const { activeTenant, tenantData, hasAccess, isCustomTenant } = useTenant();

  // Rule logic:
  // 1. If tenant has access and is a real tenant in DB:
  //    - If it's a new/custom tenant: show REAL DB data (0 if no orders have been placed yet, never fake demo numbers)
  //    - If it's the demo sandbox tenant (Apex Agro): show the sandbox demo dataset
  // 2. If user does NOT have access to any tenant (unauthorized): show dummy/sandbox dataset as demo fallback.
  let currentDataset = dashboardDatasets[timeframe];

  if (hasAccess && isCustomTenant) {
    // Generate isolated dataset from real Neon records
    const empty = createEmptyDashboardDataset(
      timeframe === "daily" ? "Today" : timeframe === "weekly" ? "This Week" : "This Month"
    );

    if (tenantData && tenantData.orders.length > 0) {
      // Build dataset with actual Neon numbers
      const m = tenantData.metrics;
      empty.metrics.sales.numericValue = m.totalSales;
      empty.metrics.sales.value = `Rs. ${m.totalSales.toLocaleString()}`;
      empty.metrics.profit.numericValue = m.totalProfit;
      empty.metrics.profit.value = `Rs. ${m.totalProfit.toLocaleString()}`;
      empty.metrics.collections.numericValue = m.totalPaid;
      empty.metrics.collections.value = `Rs. ${m.totalPaid.toLocaleString()}`;
      empty.metrics.orders.numericValue = m.totalOrders;
      empty.metrics.orders.value = `${m.totalOrders} Orders`;
      empty.collectionsBreakdown.cash = m.totalPaid;
      empty.collectionsBreakdown.outstandingReceivables = Math.max(0, m.totalSales - m.totalPaid);

      // Map real transactions
      empty.recentTransactions = tenantData.orders.slice(0, 5).map((o) => ({
        id: o.id,
        orderNumber: o.orderNumber,
        partyName: o.partyName,
        distributorName: o.distributorName || "Field Agent",
        amount: Number(o.totalAmount),
        status: (o.status === "Delivered" || o.status === "Completed"
          ? "Completed"
          : o.status === "In Transit"
          ? "Processing"
          : "Pending") as RecentTransaction["status"],
        type: "Order" as const,
        time: new Date(o.date).toLocaleDateString(),
      }));
    }

    currentDataset = empty;
  }

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
            {isCustomTenant ? "Tenant Isolated Production DB" : "Commercial Operations Control"}
          </div>
          <h1 className="text-2xl sm:text-3xl font-extrabold tracking-tight text-white">
            {activeTenant?.name || "Apex Agro Chemical Ltd."}
          </h1>
          <p className="text-slate-300 text-xs sm:text-sm mt-1 max-w-xl">
            {isCustomTenant
              ? "Live isolated telemetry for this organization. New dispatches and field claims reflect in real time."
              : "Live telemetry of field orders, multi-party khata collections, and profit velocity across your registered territories."}
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

      {/* No Access / Demo Fallback Banner */}
      {!hasAccess && (
        <div className="p-4 bg-amber-50 border border-amber-200 rounded-2xl flex items-start gap-3 text-amber-900 text-xs">
          <Info className="w-5 h-5 text-amber-600 shrink-0 mt-0.5" />
          <div>
            <div className="font-bold text-sm">Demo / Sandbox Mode (No Active Tenant Access)</div>
            <p className="text-amber-700 mt-0.5">
              Your logged-in account is not associated with any active company tenant. Displaying simulated demo figures for preview.
            </p>
          </div>
        </div>
      )}

      {/* Tenant Isolation Banner Note for new organizations */}
      {hasAccess && isCustomTenant && (!tenantData || tenantData.orders.length === 0) && (
        <div className="p-4 bg-blue-50 border border-blue-200/80 rounded-2xl flex items-start gap-3 text-blue-900 text-xs">
          <Info className="w-5 h-5 text-blue-600 shrink-0 mt-0.5" />
          <div>
            <div className="font-bold text-sm">Tenant Database Initialized</div>
            <p className="text-blue-700 mt-0.5">
              You are signed in to <span className="font-semibold">{activeTenant?.name}</span>. Currently there are 0 orders recorded in Neon PostgreSQL for this tenant. Issue 12-character invite tokens to field distributors to start capturing orders.
            </p>
          </div>
        </div>
      )}

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
