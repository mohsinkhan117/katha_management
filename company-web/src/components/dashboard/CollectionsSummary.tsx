"use client";

import React from "react";
import { Wallet, Landmark, CreditCard, AlertCircle, ArrowUpRight } from "lucide-react";
import Link from "next/link";

interface CollectionsSummaryProps {
  data: {
    cash: number;
    bankTransfer: number;
    cheque: number;
    outstandingReceivables: number;
    collectionEfficiency: number;
  };
}

export function CollectionsSummary({ data }: CollectionsSummaryProps) {
  const totalRealized = data.cash + data.bankTransfer + data.cheque;
  const grandTotal = totalRealized + data.outstandingReceivables;

  const cashPercent = Math.round((data.cash / grandTotal) * 100);
  const bankPercent = Math.round((data.bankTransfer / grandTotal) * 100);
  const chequePercent = Math.round((data.cheque / grandTotal) * 100);
  const duesPercent = Math.round((data.outstandingReceivables / grandTotal) * 100);

  const formatCurrency = (val: number) => `Rs. ${val.toLocaleString()}`;

  return (
    <div className="bg-white rounded-2xl border border-slate-200 p-5 shadow-sm flex flex-col justify-between">
      {/* Header */}
      <div className="flex items-center justify-between pb-3 border-b border-slate-100">
        <div>
          <h2 className="text-base font-bold text-slate-900">
            Collections & Khata Receivables
          </h2>
          <p className="text-xs text-slate-500 mt-0.5">
            Cash in hand vs. bank settlements & market ledger balance
          </p>
        </div>
        <Link
          href="/parties"
          className="text-xs font-semibold text-blue-600 hover:text-blue-700 flex items-center gap-1 group"
        >
          View Khata
          <ArrowUpRight className="w-3.5 h-3.5 group-hover:translate-x-0.5 group-hover:-translate-y-0.5 transition-transform" />
        </Link>
      </div>

      {/* Recovery Rate Gauge Bar */}
      <div className="my-4 p-4 bg-slate-50 rounded-xl border border-slate-200/60">
        <div className="flex items-center justify-between text-xs mb-2">
          <span className="font-semibold text-slate-700">
            Collection Recovery Efficiency
          </span>
          <span className="font-bold text-emerald-600 bg-emerald-50 px-2 py-0.5 rounded border border-emerald-200">
            {data.collectionEfficiency}% Recovered
          </span>
        </div>

        {/* Multi-segmented Progress Bar */}
        <div className="w-full h-3 bg-slate-200 rounded-full overflow-hidden flex">
          <div
            style={{ width: `${cashPercent}%` }}
            title={`Cash: ${cashPercent}%`}
            className="h-full bg-emerald-500 transition-all duration-500"
          />
          <div
            style={{ width: `${bankPercent}%` }}
            title={`Bank Transfer: ${bankPercent}%`}
            className="h-full bg-blue-500 transition-all duration-500"
          />
          <div
            style={{ width: `${chequePercent}%` }}
            title={`Cheque: ${chequePercent}%`}
            className="h-full bg-violet-500 transition-all duration-500"
          />
          <div
            style={{ width: `${duesPercent}%` }}
            title={`Pending Receivables: ${duesPercent}%`}
            className="h-full bg-amber-400 transition-all duration-500"
          />
        </div>

        <div className="flex items-center justify-between text-[11px] text-slate-500 mt-2">
          <span>Realized: {formatCurrency(totalRealized)}</span>
          <span className="text-amber-700 font-semibold">
            Market Khata Dues: {formatCurrency(data.outstandingReceivables)}
          </span>
        </div>
      </div>

      {/* Breakdown Items */}
      <div className="space-y-2.5">
        <div className="flex items-center justify-between p-2.5 rounded-xl hover:bg-slate-50 transition border border-transparent hover:border-slate-100">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-lg bg-emerald-50 text-emerald-600 flex items-center justify-center">
              <Wallet className="w-4 h-4" />
            </div>
            <div>
              <div className="text-xs font-semibold text-slate-800">
                Cash in Hand / Field Deposit
              </div>
              <div className="text-[11px] text-slate-400">{cashPercent}% of total volume</div>
            </div>
          </div>
          <div className="text-xs font-bold text-slate-900">
            {formatCurrency(data.cash)}
          </div>
        </div>

        <div className="flex items-center justify-between p-2.5 rounded-xl hover:bg-slate-50 transition border border-transparent hover:border-slate-100">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-lg bg-blue-50 text-blue-600 flex items-center justify-center">
              <Landmark className="w-4 h-4" />
            </div>
            <div>
              <div className="text-xs font-semibold text-slate-800">
                Direct Bank Transfer / IBFT
              </div>
              <div className="text-[11px] text-slate-400">{bankPercent}% of total volume</div>
            </div>
          </div>
          <div className="text-xs font-bold text-slate-900">
            {formatCurrency(data.bankTransfer)}
          </div>
        </div>

        <div className="flex items-center justify-between p-2.5 rounded-xl hover:bg-slate-50 transition border border-transparent hover:border-slate-100">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-lg bg-violet-50 text-violet-600 flex items-center justify-center">
              <CreditCard className="w-4 h-4" />
            </div>
            <div>
              <div className="text-xs font-semibold text-slate-800">
                Post-Dated Cheques Clearing
              </div>
              <div className="text-[11px] text-slate-400">{chequePercent}% of total volume</div>
            </div>
          </div>
          <div className="text-xs font-bold text-slate-900">
            {formatCurrency(data.cheque)}
          </div>
        </div>

        <div className="flex items-center justify-between p-2.5 rounded-xl bg-amber-50/60 border border-amber-200/60">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-lg bg-amber-100 text-amber-700 flex items-center justify-center">
              <AlertCircle className="w-4 h-4" />
            </div>
            <div>
              <div className="text-xs font-semibold text-amber-900">
                Pending Ledger Receivables
              </div>
              <div className="text-[11px] text-amber-700">Awaiting party settlement</div>
            </div>
          </div>
          <div className="text-xs font-bold text-amber-900">
            {formatCurrency(data.outstandingReceivables)}
          </div>
        </div>
      </div>
    </div>
  );
}

