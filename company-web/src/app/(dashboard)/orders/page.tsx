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
import { useTenant } from "@/context/TenantContext";
import { NewOrderModal } from "@/components/dashboard/DashboardModals";

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

export default function CompanyOrdersPage() {
  const { activeTenant, tenantData } = useTenant();
  const [filterStatus, setFilterStatus] = useState<string>("all");
  const [searchQuery, setSearchQuery] = useState<string>("");
  const [isModalOpen, setIsModalOpen] = useState(false);

  // Map real database orders from Neon
  const effectiveOrders: OrderItem[] = (tenantData?.orders || []).map((o) => ({
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
      {/* Top Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-extrabold text-slate-900 tracking-tight">
            B2B Orders & Fulfillment
          </h1>
          <p className="text-xs sm:text-sm text-slate-500 mt-1">
            Manage incoming purchase orders from mobile field distributors and dispatch workflows for {activeTenant?.name || "your organization"}.
          </p>
        </div>

        <button
          onClick={() => setIsModalOpen(true)}
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
        <div className="flex items-center gap-1.5 overflow-x-auto pb-1 md:pb-0 text-xs font-medium">
          {["all", "delivered", "in transit", "pending", "cancelled"].map((tab) => (
            <button
              key={tab}
              onClick={() => setFilterStatus(tab)}
              className={`px-3 py-1.5 rounded-xl capitalize whitespace-nowrap transition-colors ${
                filterStatus === tab
                  ? "bg-slate-900 text-white font-semibold"
                  : "text-slate-600 hover:bg-slate-100"
              }`}
            >
              {tab}
            </button>
          ))}
        </div>
      </div>

      {/* Orders Table Container */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse text-xs">
            <thead>
              <tr className="bg-slate-50 border-b border-slate-200 text-slate-500 font-semibold uppercase tracking-wider text-[11px]">
                <th className="py-3.5 px-4">Order ID</th>
                <th className="py-3.5 px-4">Customer Party</th>
                <th className="py-3.5 px-4">Distributor Agent</th>
                <th className="py-3.5 px-4">Date</th>
                <th className="py-3.5 px-4">Status</th>
                <th className="py-3.5 px-4 text-right">Order Amount</th>
                <th className="py-3.5 px-4 text-right">Paid Amount</th>
                <th className="py-3.5 px-4 text-center">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {filteredOrders.length > 0 ? (
                filteredOrders.map((order) => (
                  <tr key={order.id} className="hover:bg-slate-50/70 transition">
                    <td className="py-3 px-4 font-mono font-bold text-blue-600">
                      {order.orderNumber}
                    </td>
                    <td className="py-3 px-4 font-semibold text-slate-900">
                      {order.partyName}
                    </td>
                    <td className="py-3 px-4 text-slate-600">
                      {order.distributorName}
                    </td>
                    <td className="py-3 px-4 text-slate-500">
                      {order.date}
                    </td>
                    <td className="py-3 px-4">
                      {getStatusBadge(order.status)}
                    </td>
                    <td className="py-3 px-4 text-right font-extrabold text-slate-900">
                      Rs. {order.totalAmount.toLocaleString()}
                    </td>
                    <td className="py-3 px-4 text-right font-semibold text-emerald-600">
                      Rs. {order.paidAmount.toLocaleString()}
                    </td>
                    <td className="py-3 px-4 text-center">
                      <button
                        onClick={() => alert(`Order details: ${order.orderNumber}`)}
                        className="p-1.5 rounded-lg hover:bg-slate-100 text-slate-500 hover:text-slate-800 transition"
                        title="View Details"
                      >
                        <Eye className="w-4 h-4" />
                      </button>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={8} className="py-12 text-center text-slate-400">
                    <ShoppingBag className="w-10 h-10 mx-auto text-slate-300 mb-2" />
                    <p className="font-semibold text-slate-600">No orders found in database</p>
                    <p className="text-xs text-slate-400 mt-1">
                      Click &quot;Create B2B Order&quot; to record your first company dispatch.
                    </p>
                    <button
                      onClick={() => setIsModalOpen(true)}
                      className="mt-3 px-3.5 py-1.5 bg-blue-600 hover:bg-blue-500 text-white rounded-xl text-xs font-semibold shadow-sm transition"
                    >
                      Create First Order
                    </button>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      <NewOrderModal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} />
    </div>
  );
}
