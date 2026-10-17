"use client";

import React, { useState } from "react";
import {
  Package,
  Plus,
  Search,
  Filter,
  CheckCircle,
  Eye,
  AlertCircle,
  Tag,
} from "lucide-react";
import { useTenant } from "@/context/TenantContext";
import { AddProductModal } from "@/components/dashboard/DashboardModals";

interface ProductCatalogItem {
  id: string;
  name: string;
  sku: string;
  category: string;
  unitPrice: number;
  stockQuantity: number;
  isActive: boolean;
}

export default function CompanyProductsPage() {
  const { activeTenant, tenantData } = useTenant();
  const [search, setSearch] = useState("");
  const [isModalOpen, setIsModalOpen] = useState(false);

  // Map real database products from Neon
  const effectiveProducts: ProductCatalogItem[] = (tenantData?.products || []).map((p) => ({
    id: p.id,
    name: p.name,
    sku: p.sku || "SKU-GEN",
    category: p.category || "General",
    unitPrice: Number(p.unitPrice || 0),
    stockQuantity: Number(p.stockQuantity || 0),
    isActive: p.isActive ?? true,
  }));

  const filteredProducts = effectiveProducts.filter(
    (p) =>
      p.name.toLowerCase().includes(search.toLowerCase()) ||
      p.sku.toLowerCase().includes(search.toLowerCase()) ||
      p.category.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="max-w-7xl mx-auto space-y-6">
      {/* Top Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-extrabold text-slate-900 tracking-tight">
            Master Product Catalog
          </h1>
          <p className="text-xs sm:text-sm text-slate-500 mt-1">
            Define SKU codes, wholesale trade prices, packaging units, and auto-sync to field distributor devices for {activeTenant?.name || "your organization"}.
          </p>
        </div>

        <button
          onClick={() => setIsModalOpen(true)}
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
              <tr className="bg-slate-50 border-b border-slate-200 text-slate-500 font-semibold uppercase tracking-wider text-[11px]">
                <th className="py-3.5 px-4">Product Name</th>
                <th className="py-3.5 px-4">SKU Code</th>
                <th className="py-3.5 px-4">Category</th>
                <th className="py-3.5 px-4 text-right">Wholesale Price</th>
                <th className="py-3.5 px-4 text-right">Stock Quantity</th>
                <th className="py-3.5 px-4">Status</th>
                <th className="py-3.5 px-4 text-center">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {filteredProducts.length > 0 ? (
                filteredProducts.map((p) => (
                  <tr key={p.id} className="hover:bg-slate-50/70 transition">
                    <td className="py-3 px-4 font-semibold text-slate-900">
                      {p.name}
                    </td>
                    <td className="py-3 px-4 font-mono text-slate-500">
                      {p.sku}
                    </td>
                    <td className="py-3 px-4">
                      <span className="inline-flex items-center gap-1 text-[11px] font-semibold px-2 py-0.5 rounded-full bg-slate-100 text-slate-700">
                        <Tag className="w-3 h-3 text-slate-400" />
                        {p.category}
                      </span>
                    </td>
                    <td className="py-3 px-4 text-right font-extrabold text-slate-900">
                      Rs. {p.unitPrice.toLocaleString()}
                    </td>
                    <td className="py-3 px-4 text-right font-medium text-slate-600">
                      {p.stockQuantity} units
                    </td>
                    <td className="py-3 px-4">
                      <span className="inline-flex items-center gap-1 text-[11px] font-semibold px-2 py-0.5 rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200">
                        <CheckCircle className="w-3 h-3" />
                        Active Catalog
                      </span>
                    </td>
                    <td className="py-3 px-4 text-center">
                      <button
                        onClick={() => alert(`Product details: ${p.name}`)}
                        className="p-1.5 rounded-lg hover:bg-slate-100 text-slate-500 hover:text-slate-800 transition"
                      >
                        <Eye className="w-4 h-4" />
                      </button>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={7} className="py-12 text-center text-slate-400">
                    <Package className="w-10 h-10 mx-auto text-slate-300 mb-2" />
                    <p className="font-semibold text-slate-600">No products in catalog</p>
                    <p className="text-xs text-slate-400 mt-1">
                      Add SKU items to start issuing dispatch orders and stock pricing.
                    </p>
                    <button
                      onClick={() => setIsModalOpen(true)}
                      className="mt-3 px-3.5 py-1.5 bg-blue-600 hover:bg-blue-500 text-white rounded-xl text-xs font-semibold shadow-sm transition"
                    >
                      Add First SKU
                    </button>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      <AddProductModal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} />
    </div>
  );
}
