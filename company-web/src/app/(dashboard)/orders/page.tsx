"use client";

import React, { useState } from "react";
import {
  ShoppingBag,
  Filter,
  Search,
  Plus,
  Eye,
  CheckCircle,
  Truck,
  Clock,
  XCircle,
  FileText,
} from "lucide-react";

interface OrderItem {
  id: string;
  orderNumber: string;
  partyName: string;
  distributorName: string;
  itemsCount: number;
  totalAmount: number;
  paidAmount: number;
  status: "Pending" | "In Transit" | "Delivered" | "Cancelled";
  date: string;
}

const mockOrders: OrderItem[] = [
  {
    id: "ord-1",
    orderNumber: "ORD-2026-1049",
    partyName: "Madina Kiryana Store",
    distributorName: "Ali Hassan (Lahore East)",
    itemsCount: 14,
    totalAmount: 34500,
    paidAmount: 34500,
    status: "Delivered",
    date: "14 Oct 2026, 10:20 AM",
  },
  {
    id: "ord-2",
    orderNumber: "ORD-2026-1048",
    partyName: "Al-Rehman Traders",
    distributorName: "Tariq Mehmood (Gujranwala)",
    itemsCount: 8,
    totalAmount: 18200,
    paidAmount: 10000,
    status: "In Transit",
    date: "14 Oct 2026, 09:45 AM",
  },
  {
    id: "ord-3",
    orderNumber: "ORD-2026-1047",
    partyName: "Ittehad Super Store",
    distributorName: "Ali Hassan (Lahore East)",
    itemsCount: 22,
    totalAmount: 41800,
    paidAmount: 0,
    status: "Pending",
    date: "14 Oct 2026, 08:30 AM",
  },
  {
    id: "ord-4",
    orderNumber: "ORD-2026-1046",
    partyName: "Bismillah General Mart",
    distributorName: "Zubair Khan (Faisalabad)",
    itemsCount: 30,
    totalAmount: 85000,
    paidAmount: 85000,
    status: "Delivered",
    date: "13 Oct 2026, 04:15 PM",
  },
  {
    id: "ord-5",
    orderNumber: "ORD-2026-1045",
    partyName: "Punjab Traders & Agency",
    distributorName: "Ali Hassan (Lahore East)",
    itemsCount: 35,
    totalAmount: 88400,
    paidAmount: 50000,
    status: "Delivered",
    date: "13 Oct 2026, 02:00 PM",
  },
  {
    id: "ord-6",
    orderNumber: "ORD-2026-1044",
    partyName: "Chaudhry & Sons Wholesalers",
    distributorName: "Imran Sadiq (Sialkot)",
    itemsCount: 16,
    totalAmount: 39600,
    paidAmount: 0,
    status: "Cancelled",
    date: "13 Oct 2026, 11:10 AM",
  },
];

import { useTenant } from "@/context/TenantContext";

export default function CompanyOrdersPage() {
  const { activeTenant, tenantData, hasAccess, isCustomTenant } = useTenant();
  const [filterStatus, setFilterStatus] = useState<string>("all");
  const [searchQuery, setSearchQuery] = useState<string>("");

  // Rule logic:
  // Custom database tenants see only their actual orders (0 if clean).
  // Sandbox/demo fallback only when no access or sandbox.
  let effectiveOrders: OrderItem[] = mockOrders;

  if (hasAccess && isCustomTenant) {
    if (tenantData && tenantData.orders) {
      effectiveOrders = tenantData.orders.map((o) => ({
        id: o.id,
        orderNumber: o.orderNumber,
        partyName: o.partyName,
        distributorName: o.distributorName || "Field Agent",
        itemsCount: o.itemsCount || 1,
        totalAmount: Number(o.totalAmount || 0),
        paidAmount: Number(o.paidAmount || 0),
        status: (o.status as any) || "Pending",
        date: new Date(o.date).toLocaleDateString(),
      }));
    } else {
      effectiveOrders = [];
    }
  }

  const filteredOrders = effectiveOrders.filter((order) => {
    const matchesStatus =
      filterStatus === "all" || order.status.toLowerCase() === filterStatus.toLowerCase();
    const matchesSearch =
      order.orderNumber.toLowerCase().includes(searchQuery.toLowerCase()) ||
      order.partyName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      order.distributorName.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesStatus && matchesSearch;
  });

  const getStatusBadge = (status: OrderItem["status"]) => {
    switch (status) {
      case "Delivered":
        return (
          <span className="inline-flex items-center gap-1 text-[11px] font-semibold px-2 py-0.5 rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200">
            <CheckCircle className="w-3 h-3" />
            Delivered
          </span>
        );
      case "In Transit":
        return (
          <span className="inline-flex items-center gap-1 text-[11px] font-semibold px-2 py-0.5 rounded-full bg-blue-50 text-blue-700 border border-blue-200">
            <Truck className="w-3 h-3" />
            In Transit
          </span>
        );
      case "Pending":
        return (
          <span className="inline-flex items-center gap-1 text-[11px] font-semibold px-2 py-0.5 rounded-full bg-amber-50 text-amber-700 border border-amber-200">
            <Clock className="w-3 h-3" />
            Pending Dispatch
          </span>
        );
      case "Cancelled":
        return (
          <span className="inline-flex items-center gap-1 text-[11px] font-semibold px-2 py-0.5 rounded-full bg-rose-50 text-rose-700 border border-rose-200">
            <XCircle className="w-3 h-3" />
            Cancelled
          </span>
        );
    }
  };

  return (
    <div className="max-w-7xl mx-auto space-y-6">
      {/* No Access / Demo Banner */}
      {!hasAccess && (
        <div className="p-4 bg-amber-50 border border-amber-200 rounded-2xl flex items-start gap-3 text-amber-900 text-xs">
          <ShoppingBag className="w-5 h-5 text-amber-600 shrink-0 mt-0.5" />
          <div>
            <div className="font-bold text-sm">Demo / Sandbox Mode (No Active Tenant)</div>
            <p className="text-amber-700 mt-0.5">
              Your account is not linked to an active company tenant. Displaying simulated purchase orders.
            </p>
          </div>
        </div>
      )}

      {/* Top Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-extrabold text-slate-900 tracking-tight">
            B2B Orders & Fulfillment
          </h1>
          <p className="text-xs sm:text-sm text-slate-500 mt-1">
            Manage incoming purchase orders from mobile field distributors and dispatch workflows.
          </p>
        </div>

        <button
          onClick={() => alert("Open New Order Modal")}
          className="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-500 text-white rounded-xl text-xs font-semibold shadow-md shadow-blue-600/20 transition self-start sm:self-auto"
        >
          <Plus className="w-4 h-4" />
          Create B2B Order
        </button>
      </div>

      {/* Filter and Search Bar */}
      <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        {/* Search */}
        <div className="relative flex-1 max-w-md">
          <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search by order #, party, or distributor..."
            className="w-full pl-9 pr-4 py-2 text-xs bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 text-slate-800"
          />
        </div>

        {/* Status Filter Tabs */}
        <div className="flex items-center gap-1 bg-slate-100 p-1 rounded-xl self-start md:self-auto overflow-x-auto text-xs font-medium">
          {["all", "pending", "in transit", "delivered", "cancelled"].map((st) => (
            <button
              key={st}
              onClick={() => setFilterStatus(st)}
              className={`px-3 py-1.5 rounded-lg capitalize transition ${
                filterStatus === st
                  ? "bg-white text-slate-900 font-semibold shadow-sm"
                  : "text-slate-600 hover:text-slate-900"
              }`}
            >
              {st}
            </button>
          ))}
        </div>
      </div>

      {/* Orders Table */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead>
              <tr className="bg-slate-50/80 border-b border-slate-200 text-slate-500 uppercase tracking-wider text-[11px]">
                <th className="py-3 px-4 font-semibold">Order ID</th>
                <th className="py-3 px-4 font-semibold">Party Store</th>
                <th className="py-3 px-4 font-semibold">Distributor</th>
                <th className="py-3 px-4 font-semibold text-center">Items</th>
                <th className="py-3 px-4 font-semibold text-right">Order Value</th>
                <th className="py-3 px-4 font-semibold text-right">Khata Balance</th>
                <th className="py-3 px-4 font-semibold text-center">Status</th>
                <th className="py-3 px-4 font-semibold text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {filteredOrders.length === 0 ? (
                <tr>
                  <td colSpan={8} className="py-12 px-4 text-center">
                    <div className="max-w-sm mx-auto flex flex-col items-center justify-center space-y-3">
                      <div className="w-12 h-12 rounded-2xl bg-slate-100 text-slate-400 flex items-center justify-center">
                        <ShoppingBag className="w-6 h-6" />
                      </div>
                      <div className="space-y-1">
                        <div className="text-sm font-bold text-slate-800">
                          {effectiveOrders.length === 0
                            ? "No orders received yet"
                            : "No matching orders found"}
                        </div>
                        <p className="text-xs text-slate-500">
                          {effectiveOrders.length === 0
                            ? "As your registered field distributors take and sync purchase orders from stores, they will automatically appear here."
                            : "Try adjusting your search terms or status filters."}
                        </p>
                      </div>
                      {effectiveOrders.length === 0 && (
                        <button
                          onClick={() => alert("Open New Order Modal")}
                          className="mt-2 inline-flex items-center gap-1.5 px-3 py-1.5 bg-blue-50 text-blue-700 hover:bg-blue-100 rounded-lg text-xs font-semibold transition"
                        >
                          <Plus className="w-3.5 h-3.5" />
                          Record First Order
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ) : (
                filteredOrders.map((ord) => (
                  <tr key={ord.id} className="hover:bg-slate-50/80 transition group">
                    <td className="py-3 px-4">
                      <div className="font-bold text-slate-900 font-mono">
                        {ord.orderNumber}
                      </div>
                      <div className="text-[10px] text-slate-400">{ord.date}</div>
                    </td>
                    <td className="py-3 px-4">
                      <div className="font-semibold text-slate-800">{ord.partyName}</div>
                    </td>
                    <td className="py-3 px-4 text-slate-600">
                      {ord.distributorName}
                    </td>
                    <td className="py-3 px-4 text-center font-medium text-slate-700">
                      {ord.itemsCount} SKUs
                    </td>
                    <td className="py-3 px-4 text-right font-bold text-slate-900">
                      Rs. {ord.totalAmount.toLocaleString()}
                    </td>
                    <td className="py-3 px-4 text-right">
                      {ord.totalAmount - ord.paidAmount > 0 ? (
                        <span className="text-amber-700 font-semibold text-[11px] bg-amber-50 px-2 py-0.5 rounded border border-amber-200">
                          Due: Rs. {(ord.totalAmount - ord.paidAmount).toLocaleString()}
                        </span>
                      ) : (
                        <span className="text-emerald-700 font-semibold text-[11px] bg-emerald-50 px-2 py-0.5 rounded border border-emerald-200">
                          Paid Full
                        </span>
                      )}
                    </td>
                    <td className="py-3 px-4 text-center">
                      {getStatusBadge(ord.status)}
                    </td>
                    <td className="py-3 px-4 text-right">
                      <button
                        onClick={() => alert(`View details for ${ord.orderNumber}`)}
                        className="p-1.5 rounded-lg text-slate-400 hover:text-blue-600 hover:bg-blue-50 transition"
                        title="View Invoice"
                      >
                        <Eye className="w-4 h-4" />
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
