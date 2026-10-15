"use client";

import React, { useState } from "react";
import { Package, Plus, Search, Tag, CheckCircle2, AlertCircle } from "lucide-react";

interface ProductCatalogItem {
  id: string;
  name: string;
  sku: string;
  category: string;
  unit: string;
  tradePrice: number;
  retailPrice: number;
  stockAvailable: number;
  inStock: boolean;
}

const mockProducts: ProductCatalogItem[] = [
  {
    id: "prd-1",
    name: "Supreme Super Basmati Rice 25kg",
    sku: "BAS-SUP-025",
    category: "Grains & Rice",
    unit: "25kg Bag",
    tradePrice: 2150,
    retailPrice: 2300,
    stockAvailable: 450,
    inStock: true,
  },
  {
    id: "prd-2",
    name: "Pure Mustard Cooking Oil 5L Tin",
    sku: "OIL-MST-005",
    category: "Edible Oils",
    unit: "5L Tin",
    tradePrice: 2100,
    retailPrice: 2300,
    stockAvailable: 280,
    inStock: true,
  },
  {
    id: "prd-3",
    name: "Premium Chai Dust Blend 1kg",
    sku: "TEA-PRM-001",
    category: "Beverages",
    unit: "1kg Pouch",
    tradePrice: 1150,
    retailPrice: 1300,
    stockAvailable: 600,
    inStock: true,
  },
  {
    id: "prd-4",
    name: "Refined White Sugar 50kg Sack",
    sku: "SGR-WHT-050",
    category: "Commodities",
    unit: "50kg Sack",
    tradePrice: 3200,
    retailPrice: 3500,
    stockAvailable: 12,
    inStock: false,
  },
];

import { useTenant } from "@/context/TenantContext";

export default function CompanyProductsPage() {
  const { activeTenant, hasAccess, isCustomTenant } = useTenant();
  const [search, setSearch] = useState("");

  // Rule logic:
  // Custom tenants with access see only their real products (0 / clean initially).
  // Sandbox demo fallback when no access.
  let effectiveProducts: ProductCatalogItem[] = mockProducts;

  if (hasAccess && isCustomTenant) {
    effectiveProducts = [];
  }

  const filteredProducts = effectiveProducts.filter(
    (p) =>
      p.name.toLowerCase().includes(search.toLowerCase()) ||
      p.sku.toLowerCase().includes(search.toLowerCase()) ||
      p.category.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="max-w-7xl mx-auto space-y-6">
      {/* No Access / Demo Banner */}
      {!hasAccess && (
        <div className="p-4 bg-amber-50 border border-amber-200 rounded-2xl flex items-start gap-3 text-amber-900 text-xs">
          <AlertCircle className="w-5 h-5 text-amber-600 shrink-0 mt-0.5" />
          <div>
            <div className="font-bold text-sm">Demo / Sandbox Mode (No Active Tenant)</div>
            <p className="text-amber-700 mt-0.5">
              Your account is not linked to an active company tenant. Displaying simulated SKU items.
            </p>
          </div>
        </div>
      )}

      {/* Top Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-extrabold text-slate-900 tracking-tight">
            Master Product Catalog
          </h1>
          <p className="text-xs sm:text-sm text-slate-500 mt-1">
            Define SKU codes, wholesale trade prices, packaging units, and auto-sync to field distributor devices.
          </p>
        </div>

        <button
          onClick={() => alert("Open Add Product Modal")}
          className="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-500 text-white rounded-xl text-xs font-semibold shadow-md shadow-blue-600/20 transition self-start sm:self-auto"
        >
          <Plus className="w-4 h-4" />
          Add New SKU
        </button>
      </div>

      {/* Search Bar */}
      <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm">
        <div className="relative max-w-md">
          <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search product name, SKU, or category..."
            className="w-full pl-9 pr-4 py-2 text-xs bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 text-slate-800"
          />
        </div>
      </div>

      {/* Products Table */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead>
              <tr className="bg-slate-50/80 border-b border-slate-200 text-slate-500 uppercase tracking-wider text-[11px]">
                <th className="py-3 px-4 font-semibold">SKU / Item</th>
                <th className="py-3 px-4 font-semibold">Category</th>
                <th className="py-3 px-4 font-semibold">Packaging Unit</th>
                <th className="py-3 px-4 font-semibold text-right">Trade Price (B2B)</th>
                <th className="py-3 px-4 font-semibold text-right">Retail MRP</th>
                <th className="py-3 px-4 font-semibold text-center">Stock</th>
                <th className="py-3 px-4 font-semibold text-right">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {filteredProducts.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-12 px-4 text-center">
                    <div className="max-w-sm mx-auto flex flex-col items-center justify-center space-y-3">
                      <div className="w-12 h-12 rounded-2xl bg-slate-100 text-slate-400 flex items-center justify-center">
                        <Package className="w-6 h-6" />
                      </div>
                      <div className="space-y-1">
                        <div className="text-sm font-bold text-slate-800">
                          {effectiveProducts.length === 0
                            ? "No products in master catalog yet"
                            : "No matching products found"}
                        </div>
                        <p className="text-xs text-slate-500">
                          {effectiveProducts.length === 0
                            ? "Add SKU lines to your master catalog so field distributors can view trade rates and take orders."
                            : "Try adjusting your search query."}
                        </p>
                      </div>
                      {effectiveProducts.length === 0 && (
                        <button
                          onClick={() => alert("Open Add Product Modal")}
                          className="mt-2 inline-flex items-center gap-1.5 px-3 py-1.5 bg-blue-50 text-blue-700 hover:bg-blue-100 rounded-lg text-xs font-semibold transition"
                        >
                          <Plus className="w-3.5 h-3.5" />
                          Add First SKU
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ) : (
                filteredProducts.map((p) => (
                  <tr key={p.id} className="hover:bg-slate-50/80 transition">
                    <td className="py-3 px-4">
                      <div className="font-bold text-slate-900">{p.name}</div>
                      <div className="text-[10px] text-slate-400 font-mono">{p.sku}</div>
                    </td>
                    <td className="py-3 px-4">
                      <span className="px-2 py-0.5 bg-slate-100 text-slate-600 rounded-md text-[11px] font-medium">
                        {p.category}
                      </span>
                    </td>
                    <td className="py-3 px-4 text-slate-600 font-medium">{p.unit}</td>
                    <td className="py-3 px-4 text-right font-bold text-slate-900">
                      Rs. {p.tradePrice.toLocaleString()}
                    </td>
                    <td className="py-3 px-4 text-right text-slate-600">
                      Rs. {p.retailPrice.toLocaleString()}
                    </td>
                    <td className="py-3 px-4 text-center font-semibold text-slate-800">
                      {p.stockAvailable} units
                    </td>
                    <td className="py-3 px-4 text-right">
                      {p.inStock ? (
                        <span className="inline-flex items-center gap-1 text-[11px] font-semibold px-2 py-0.5 rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200">
                          <CheckCircle2 className="w-3 h-3" />
                          In Stock
                        </span>
                      ) : (
                        <span className="inline-flex items-center gap-1 text-[11px] font-semibold px-2 py-0.5 rounded-full bg-rose-50 text-rose-700 border border-rose-200">
                          <AlertCircle className="w-3 h-3" />
                          Low Stock
                        </span>
                      )}
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
