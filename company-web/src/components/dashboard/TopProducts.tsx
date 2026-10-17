"use client";

import React from "react";
import { Package, ArrowUpRight } from "lucide-react";
import Link from "next/link";
import { TopProduct } from "./types";

interface TopProductsProps {
  products: TopProduct[];
}

export function TopProducts({ products }: TopProductsProps) {
  const formatCurrency = (val: number) => `Rs. ${val.toLocaleString()}`;

  return (
    <div className="bg-white rounded-2xl border border-slate-200 p-5 shadow-sm">
      <div className="flex items-center justify-between pb-3 border-b border-slate-100 mb-4">
        <div>
          <h2 className="text-base font-bold text-slate-900">
            Top Performing SKUs
          </h2>
          <p className="text-xs text-slate-500 mt-0.5">
            Highest revenue-generating catalog items across territories
          </p>
        </div>
        <Link
          href="/products"
          className="text-xs font-semibold text-blue-600 hover:text-blue-700 flex items-center gap-1 group"
        >
          Catalog
          <ArrowUpRight className="w-3.5 h-3.5 group-hover:translate-x-0.5 group-hover:-translate-y-0.5 transition-transform" />
        </Link>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full text-left text-xs">
          <thead>
            <tr className="border-b border-slate-100 text-slate-400 uppercase tracking-wider text-[10px]">
              <th className="pb-2 font-semibold">Product & SKU</th>
              <th className="pb-2 font-semibold text-center">Category</th>
              <th className="pb-2 font-semibold text-right">Units</th>
              <th className="pb-2 font-semibold text-right">Revenue</th>
              <th className="pb-2 font-semibold text-right">Margin</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100">
            {products.length > 0 ? (
              products.map((p) => (
                <tr key={p.id} className="hover:bg-slate-50 transition group">
                  <td className="py-2.5">
                    <div className="flex items-center gap-2">
                      <div className="w-7 h-7 rounded-lg bg-slate-100 text-slate-600 flex items-center justify-center shrink-0">
                        <Package className="w-3.5 h-3.5" />
                      </div>
                      <div className="min-w-0">
                        <div className="font-semibold text-slate-900 truncate max-w-[170px] sm:max-w-[220px]">
                          {p.name}
                        </div>
                        <div className="text-[10px] text-slate-400 font-mono">
                          {p.sku}
                        </div>
                      </div>
                    </div>
                  </td>
                  <td className="py-2.5 text-center">
                    <span className="px-2 py-0.5 bg-slate-100 text-slate-600 rounded-md text-[11px] font-medium">
                      {p.category}
                    </span>
                  </td>
                  <td className="py-2.5 text-right font-medium text-slate-700">
                    {p.unitsSold}
                  </td>
                  <td className="py-2.5 text-right font-bold text-slate-900">
                    {formatCurrency(p.revenue)}
                  </td>
                  <td className="py-2.5 text-right font-semibold text-emerald-600">
                    {p.marginPercent}%
                  </td>
                </tr>
              ))
            ) : (
              <tr>
                <td colSpan={5} className="py-6 text-center text-slate-400 text-xs">
                  No catalog products recorded yet
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}

