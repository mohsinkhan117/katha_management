"use client";

import React from "react";
import { ShoppingCart, Wallet, ArrowUpRight, CheckCircle2, Clock } from "lucide-react";
import Link from "next/link";
import { RecentTransaction } from "./types";

interface RecentTransactionsProps {
  transactions: RecentTransaction[];
}

export function RecentTransactions({ transactions }: RecentTransactionsProps) {
  const formatCurrency = (val: number) => `Rs. ${val.toLocaleString()}`;

  return (
    <div className="bg-white rounded-2xl border border-slate-200 p-5 shadow-sm">
      <div className="flex items-center justify-between pb-3 border-b border-slate-100 mb-4">
        <div>
          <h2 className="text-base font-bold text-slate-900">
            Live Field Activity Feed
          </h2>
          <p className="text-xs text-slate-500 mt-0.5">
            Realtime orders & payments synced via PowerSync
          </p>
        </div>
        <Link
          href="/orders"
          className="text-xs font-semibold text-blue-600 hover:text-blue-700 flex items-center gap-1 group"
        >
          View All Feed
          <ArrowUpRight className="w-3.5 h-3.5 group-hover:translate-x-0.5 group-hover:-translate-y-0.5 transition-transform" />
        </Link>
      </div>

      <div className="space-y-3">
        {transactions.map((tx) => {
          const isOrder = tx.type === "Order";

          return (
            <div
              key={tx.id}
              className="flex items-center justify-between p-3 rounded-xl border border-slate-100 hover:border-slate-200 hover:bg-slate-50/70 transition"
            >
              <div className="flex items-center gap-3 min-w-0">
                <div
                  className={`w-9 h-9 rounded-xl flex items-center justify-center shrink-0 ${
                    isOrder
                      ? "bg-blue-50 text-blue-600 border border-blue-200"
                      : "bg-emerald-50 text-emerald-600 border border-emerald-200"
                  }`}
                >
                  {isOrder ? (
                    <ShoppingCart className="w-4 h-4" />
                  ) : (
                    <Wallet className="w-4 h-4" />
                  )}
                </div>

                <div className="min-w-0">
                  <div className="flex items-center gap-2">
                    <span className="text-xs font-bold text-slate-900 truncate">
                      {tx.partyName}
                    </span>
                    <span className="text-[10px] text-slate-400 font-mono bg-slate-100 px-1.5 py-0.5 rounded">
                      {tx.orderNumber}
                    </span>
                  </div>
                  <div className="text-[11px] text-slate-500 truncate mt-0.5">
                    Distributor: {tx.distributorName}
                  </div>
                </div>
              </div>

              <div className="text-right shrink-0 ml-3">
                <div
                  className={`text-xs font-bold ${
                    isOrder ? "text-slate-900" : "text-emerald-600"
                  }`}
                >
                  {isOrder ? "" : "+"}{formatCurrency(tx.amount)}
                </div>
                <div className="flex items-center justify-end gap-1.5 mt-0.5">
                  <span
                    className={`text-[10px] font-medium px-1.5 py-0.2 rounded ${
                      tx.status === "Completed"
                        ? "text-emerald-700 bg-emerald-50"
                        : tx.status === "Credit Ledger"
                        ? "text-violet-700 bg-violet-50"
                        : "text-amber-700 bg-amber-50"
                    }`}
                  >
                    {tx.status}
                  </span>
                  <span className="text-[10px] text-slate-400">{tx.time}</span>
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

