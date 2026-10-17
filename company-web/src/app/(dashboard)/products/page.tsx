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
  Layers,
  Percent,
} from "lucide-react";
import { useTenant, ProductItem } from "@/context/TenantContext";
import { AddProductModal, ProductDetailModal } from "@/components/dashboard/DashboardModals";

export default function CompanyProductsPage() {
  const { activeTenant, tenantData } = useTenant();
  const [search, setSearch] = useState("");
  const [selectedCategory, setSelectedCategory] = useState("all");
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [inspectedProduct, setInspectedProduct] = useState<ProductItem | null>(null);

  const products: ProductItem[] = tenantData?.products || [];

  // Extract unique categories for filter
  const categories = ["all", ...Array.from(new Set(products.map((p) => p.category).filter(Boolean)))];

  const filteredProducts = products.filter((p) => {
    const matchesSearch =
      p.name.toLowerCase().includes(search.toLowerCase()) ||
      p.sku.toLowerCase().includes(search.toLowerCase()) ||
      p.category.toLowerCase().includes(search.toLowerCase());
    const matchesCategory =
      selectedCategory === "all" || p.category.toLowerCase() === selectedCategory.toLowerCase();
    return matchesSearch && matchesCategory;
  });

  return (
    <div className="max-w-7xl mx-auto space-y-6 pb-12">
      {/* Top Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-extrabold text-slate-900 tracking-tight">
            Master Product Catalog
          </h1>
          <p className="text-xs sm:text-sm text-slate-500 mt-1">
            Define SKU lines, packaging size variants, wholesale prices, and auto-sync to field distributor terminals for {activeTenant?.name || "your organization"}.
          </p>
        </div>

        <button
          onClick={() => setIsAddModalOpen(true)}
          className="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-500 text-white rounded-xl text-xs font-semibold shadow-md shadow-blue-600/20 transition self-start sm:self-auto"
        >
          <Plus className="w-4 h-4" />
          Add Product SKU
        </button>
      </div>

      {/* Filter and Search Bar */}
      <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        {/* Search */}
        <div className="relative flex-1 max-w-md">
          <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search product name, SKU, or category..."
            className="w-full pl-9 pr-4 py-2 text-xs bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 text-slate-800"
          />
        </div>

        {/* Categories Tabs */}
        {categories.length > 1 && (
          <div className="flex items-center gap-1.5 overflow-x-auto pb-1 md:pb-0 text-xs">
            {categories.map((cat) => (
              <button
                key={cat}
                onClick={() => setSelectedCategory(cat)}
                className={`px-3 py-1.5 rounded-xl capitalize whitespace-nowrap transition-colors ${
                  selectedCategory === cat
                    ? "bg-slate-900 text-white font-semibold"
                    : "text-slate-600 hover:bg-slate-100"
                }`}
              >
                {cat}
              </button>
            ))}
          </div>
        )}
      </div>

      {/* Products Table */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead>
              <tr className="bg-slate-50 border-b border-slate-200 text-slate-500 font-semibold uppercase tracking-wider text-[11px]">
                <th className="py-3.5 px-4">Product Name & SKU</th>
                <th className="py-3.5 px-4">Category</th>
                <th className="py-3.5 px-4">Base Unit</th>
                <th className="py-3.5 px-4">Packaging Sizes</th>
                <th className="py-3.5 px-4 text-right">Selling Price</th>
                <th className="py-3.5 px-4 text-right">Stock</th>
                <th className="py-3.5 px-4">Status</th>
                <th className="py-3.5 px-4 text-center">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {filteredProducts.length > 0 ? (
                filteredProducts.map((p) => {
                  const sizesCount = p.sizes?.length || 0;
                  const finalSellingPrice = Number(p.finalPrice || p.unitPrice || p.retailPrice || 0);
                  const retailStickerPrice = Number(p.retailPrice || p.unitPrice || 0);

                  return (
                    <tr
                      key={p.id}
                      className="hover:bg-slate-50/70 transition cursor-pointer"
                      onClick={() => setInspectedProduct(p)}
                    >
                      <td className="py-3.5 px-4">
                        <div className="font-bold text-slate-900 text-sm">{p.name}</div>
                        <div className="text-[11px] font-mono text-slate-400 mt-0.5">{p.sku}</div>
                      </td>

                      <td className="py-3.5 px-4">
                        <span className="inline-flex items-center gap-1 text-[11px] font-semibold px-2 py-0.5 rounded-full bg-slate-100 text-slate-700">
                          <Tag className="w-3 h-3 text-slate-400" />
                          {p.category}
                        </span>
                      </td>

                      <td className="py-3.5 px-4 font-medium text-slate-600">
                        {p.unit || "unit"}
                      </td>

                      <td className="py-3.5 px-4">
                        {sizesCount > 0 ? (
                          <div className="flex flex-wrap items-center gap-1.5 max-w-xs">
                            <span className="inline-flex items-center gap-1 text-[10px] font-bold px-2 py-0.5 rounded-full bg-indigo-50 text-indigo-700 border border-indigo-200">
                              <Layers className="w-3 h-3 text-indigo-600" />
                              {sizesCount} Sizes
                            </span>
                            {p.sizes?.slice(0, 2).map((s, idx) => (
                              <span
                                key={idx}
                                className="text-[10px] text-slate-600 bg-slate-100 px-1.5 py-0.5 rounded"
                              >
                                {s.label}
                              </span>
                            ))}
                            {sizesCount > 2 && (
                              <span className="text-[10px] text-slate-400 font-semibold">
                                +{sizesCount - 2} more
                              </span>
                            )}
                          </div>
                        ) : (
                          <span className="text-slate-400 text-[11px] italic">Standard single unit</span>
                        )}
                      </td>

                      <td className="py-3.5 px-4 text-right">
                        <div className="font-extrabold text-slate-900 text-sm">
                          Rs. {finalSellingPrice.toLocaleString()}
                        </div>
                        {p.discountPercentage > 0 && (
                          <div className="text-[10px] text-slate-400 line-through">
                            Rs. {retailStickerPrice.toLocaleString()} (-{p.discountPercentage}%)
                          </div>
                        )}
                      </td>

                      <td className="py-3.5 px-4 text-right font-semibold text-slate-700">
                        {p.stockQuantity} {p.unit || "units"}
                      </td>

                      <td className="py-3.5 px-4">
                        {p.status === "outOfStock" ? (
                          <span className="inline-flex items-center gap-1 text-[11px] font-semibold px-2 py-0.5 rounded-full bg-rose-50 text-rose-700 border border-rose-200">
                            Out of Stock
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1 text-[11px] font-semibold px-2 py-0.5 rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200">
                            <CheckCircle className="w-3 h-3" />
                            In Stock
                          </span>
                        )}
                      </td>

                      <td className="py-3.5 px-4 text-center">
                        <button
                          onClick={(e) => {
                            e.stopPropagation();
                            setInspectedProduct(p);
                          }}
                          className="p-1.5 rounded-lg hover:bg-slate-200 text-slate-500 hover:text-slate-900 transition"
                          title="View Product Sheet & Size Tiers"
                        >
                          <Eye className="w-4 h-4" />
                        </button>
                      </td>
                    </tr>
                  );
                })
              ) : (
                <tr>
                  <td colSpan={8} className="py-12 text-center text-slate-400">
                    <Package className="w-10 h-10 mx-auto text-slate-300 mb-2" />
                    <p className="font-semibold text-slate-600">No products found in catalog</p>
                    <p className="text-xs text-slate-400 mt-1">
                      Add products with optional size variants to begin issuing dispatch orders.
                    </p>
                    <button
                      onClick={() => setIsAddModalOpen(true)}
                      className="mt-3 px-4 py-2 bg-blue-600 hover:bg-blue-500 text-white rounded-xl text-xs font-semibold shadow-sm transition inline-flex items-center gap-1.5"
                    >
                      <Plus className="w-3.5 h-3.5" />
                      Add First Product
                    </button>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Add Product Modal with Sizes */}
      <AddProductModal isOpen={isAddModalOpen} onClose={() => setIsAddModalOpen(false)} />

      {/* Product Detail Inspector Modal */}
      <ProductDetailModal
        product={inspectedProduct}
        isOpen={Boolean(inspectedProduct)}
        onClose={() => setInspectedProduct(null)}
      />
    </div>
  );
}
