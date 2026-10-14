"use client";

import React from "react";
import { CheckCircle2, Truck, Clock, XCircle, ArrowUpRight } from "lucide-react";
import Link from "next/link";
import { OrderStatusStat } from "./types";

interface OrdersBreakdownProps {
  statuses: OrderStatusStat[];
  totalOrders: number;
}

const statusIcons = {
  Delivered: CheckCircle2,
  "In Transit": Truck,
  Pending: Clock,
  Cancelled: XCircle,
};

const statusStyles = {
  Delivered: "text-emerald-700 bg-emerald-50 border-emerald-200",
  "In Transit": "text-blue-700 bg-blue-50 border-blue-200",
  Pending: "text-amber-700 bg-amber-50 border-amber-200",
  Cancelled: "text-rose-700 bg-rose-50 border-rose-200",
};

export function OrdersBreakdown({ statuses, totalOrders }: OrdersBreakdownProps) {
  return (
    <div className="bg-white rounded-2xl border border-slate-200 p-5 shadow-sm flex flex-col justify-between">
      {/* Header */}
      <div className="flex items-center justify-between pb-3 border-b border-slate-100">
        <div>
          <h2 className="text-base font-bold text-slate-900">
            Order Fulfillment Pipeline
          </h2>
          <p className="text-xs text-slate-500 mt-0.5">
            Real-time status of {totalOrders} total B2B order dispatches
          </p>
        </div>
        <Link
          href="/orders"
          className="text-xs font-semibold text-blue-600 hover:text-blue-700 flex items-center gap-1 group"
        >
          Manage Orders
          <ArrowUpRight className="w-3.5 h-3.5 group-hover:translate-x-0.5 group-hover:-translate-y-0.5 transition-transform" />
        </Link>
      </div>

      {/* Visual Pipeline Bar */}
      <div className="my-4">
        <div className="w-full h-3 bg-slate-100 rounded-full overflow-hidden flex">
          {statuses.map((stat) => (
            <div
              key={stat.status}
              style={{ width: `${stat.percentage}%` }}
              title={`${stat.status}: ${stat.count} (${stat.percentage}%)`}
              className={`h-full ${stat.color} transition-all duration-500`}
            />
          ))}
        </div>
      </div>

      {/* Grid of Status Cards */}
      <div className="grid grid-cols-2 gap-3">
        {statuses.map((stat) => {
          const Icon = statusIcons[stat.status];
          const badgeClass = statusStyles[stat.status];

          return (
            <div
              key={stat.status}
              className="p-3 rounded-xl border border-slate-200/80 bg-slate-50/50 hover:bg-slate-50 transition"
            >
              <div className="flex items-center justify-between">
                <span className="text-xs font-medium text-slate-600 flex items-center gap-1.5">
                  <Icon className="w-3.5 h-3.5" />
                  {stat.status}
                </span>
                <span
                  className={`text-[10px] font-bold px-1.5 py-0.5 rounded border ${badgeClass}`}
                >
                  {stat.percentage}%
                </span>
              </div>
              <div className="mt-2 text-xl font-extrabold text-slate-900">
                {stat.count}{" "}
                <span className="text-xs font-normal text-slate-500">
                  orders
                </span>
              </div>
            </div>
          );
        })}
      </div>

      {/* Bottom Dispatch Rate Footer */}
      <div className="mt-4 pt-3 border-t border-slate-100 flex items-center justify-between text-xs text-slate-500">
        <span>Fulfillment Velocity</span>
        <span className="font-semibold text-emerald-600">
          98.2% on-time dispatch rate
        </span>
      </div>
    </div>
  );
}

