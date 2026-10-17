"use client";

import React, { useState } from "react";
import {
  X,
  Check,
  Copy,
  ShoppingBag,
  Receipt,
  PackagePlus,
  KeyRound,
  Loader2,
  Plus,
  Trash2,
  Tag,
  Percent,
  Layers,
  Info,
  CheckCircle,
  Eye,
} from "lucide-react";
import { useTenant, ProductItem, ProductSize } from "@/context/TenantContext";

interface ModalProps {
  isOpen: boolean;
  onClose: () => void;
}

// 1. Create B2B Order Modal
export function NewOrderModal({ isOpen, onClose }: ModalProps) {
  const { createOrder } = useTenant();
  const [partyName, setPartyName] = useState("");
  const [distributorName, setDistributorName] = useState("");
  const [itemsCount, setItemsCount] = useState(1);
  const [totalAmount, setTotalAmount] = useState("");
  const [paidAmount, setPaidAmount] = useState("");
  const [status, setStatus] = useState("Delivered");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!partyName || !totalAmount) {
      setError("Please enter customer name and total order amount.");
      return;
    }

    try {
      setIsSubmitting(true);
      setError(null);
      const res = await createOrder({
        partyName,
        distributorName: distributorName || "Field Agent",
        itemsCount: Number(itemsCount) || 1,
        totalAmount: Number(totalAmount),
        paidAmount: Number(paidAmount || 0),
        status,
      });

      if (res.success) {
        onClose();
        setPartyName("");
        setTotalAmount("");
        setPaidAmount("");
      } else {
        setError(res.error || "Failed to create order");
      }
    } catch (err: any) {
      setError(err.message);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm animate-in fade-in duration-200">
      <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl border border-slate-100 relative">
        <button
          onClick={onClose}
          className="absolute top-4 right-4 text-slate-400 hover:text-slate-600 p-1 rounded-lg"
        >
          <X className="w-5 h-5" />
        </button>

        <div className="flex items-center gap-3 mb-5">
          <div className="w-10 h-10 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center">
            <ShoppingBag className="w-5 h-5" />
          </div>
          <div>
            <h2 className="text-lg font-bold text-slate-900">New B2B Order</h2>
            <p className="text-xs text-slate-500">Record a real order in your Neon PostgreSQL database</p>
          </div>
        </div>

        {error && (
          <div className="mb-4 p-3 bg-rose-50 border border-rose-200 rounded-xl text-rose-700 text-xs">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-3.5 text-xs">
          <div>
            <label className="font-semibold text-slate-700 block mb-1">Customer / Party Name *</label>
            <input
              type="text"
              required
              placeholder="e.g. Madina Kiryana Store"
              value={partyName}
              onChange={(e) => setPartyName(e.target.value)}
              className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="font-semibold text-slate-700 block mb-1">Total Amount (PKR) *</label>
              <input
                type="number"
                required
                placeholder="e.g. 45000"
                value={totalAmount}
                onChange={(e) => setTotalAmount(e.target.value)}
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
              />
            </div>
            <div>
              <label className="font-semibold text-slate-700 block mb-1">Paid / Collection (PKR)</label>
              <input
                type="number"
                placeholder="e.g. 45000"
                value={paidAmount}
                onChange={(e) => setPaidAmount(e.target.value)}
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="font-semibold text-slate-700 block mb-1">Field Distributor</label>
              <input
                type="text"
                placeholder="e.g. Tariq Mehmood"
                value={distributorName}
                onChange={(e) => setDistributorName(e.target.value)}
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
              />
            </div>
            <div>
              <label className="font-semibold text-slate-700 block mb-1">Status</label>
              <select
                value={status}
                onChange={(e) => setStatus(e.target.value)}
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
              >
                <option value="Delivered">Delivered</option>
                <option value="In Transit">In Transit</option>
                <option value="Pending">Pending</option>
              </select>
            </div>
          </div>

          <div className="pt-3 flex justify-end gap-2">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 border border-slate-200 text-slate-600 rounded-xl hover:bg-slate-50 transition"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isSubmitting}
              className="px-5 py-2 bg-blue-600 hover:bg-blue-500 text-white font-semibold rounded-xl shadow-md shadow-blue-600/20 flex items-center gap-1.5 transition disabled:opacity-60"
            >
              {isSubmitting && <Loader2 className="w-3.5 h-3.5 animate-spin" />}
              Save Real Order
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

// 2. Record Collection Modal
export function RecordCollectionModal({ isOpen, onClose }: ModalProps) {
  const { recordCollection } = useTenant();
  const [partyName, setPartyName] = useState("");
  const [amount, setAmount] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!amount) {
      setError("Please specify the collection amount.");
      return;
    }

    try {
      setIsSubmitting(true);
      setError(null);
      const res = await recordCollection({
        partyName: partyName || "Counter Khata Collection",
        amount: Number(amount),
      });

      if (res.success) {
        onClose();
        setPartyName("");
        setAmount("");
      } else {
        setError(res.error || "Failed to record collection");
      }
    } catch (err: any) {
      setError(err.message);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm animate-in fade-in duration-200">
      <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl border border-slate-100 relative">
        <button onClick={onClose} className="absolute top-4 right-4 text-slate-400 hover:text-slate-600 p-1 rounded-lg">
          <X className="w-5 h-5" />
        </button>

        <div className="flex items-center gap-3 mb-5">
          <div className="w-10 h-10 rounded-xl bg-violet-50 text-violet-600 flex items-center justify-center">
            <Receipt className="w-5 h-5" />
          </div>
          <div>
            <h2 className="text-lg font-bold text-slate-900">Record Khata Collection</h2>
            <p className="text-xs text-slate-500">Credit ledger payment settlement into Neon DB</p>
          </div>
        </div>

        {error && (
          <div className="mb-4 p-3 bg-rose-50 border border-rose-200 rounded-xl text-rose-700 text-xs">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-3.5 text-xs">
          <div>
            <label className="font-semibold text-slate-700 block mb-1">Customer / Party Name</label>
            <input
              type="text"
              placeholder="e.g. Al-Rehman Traders"
              value={partyName}
              onChange={(e) => setPartyName(e.target.value)}
              className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 focus:outline-none focus:ring-2 focus:ring-violet-500/20"
            />
          </div>

          <div>
            <label className="font-semibold text-slate-700 block mb-1">Collection Amount (PKR) *</label>
            <input
              type="number"
              required
              placeholder="e.g. 25000"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 focus:outline-none focus:ring-2 focus:ring-violet-500/20"
            />
          </div>

          <div className="pt-3 flex justify-end gap-2">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 border border-slate-200 text-slate-600 rounded-xl hover:bg-slate-50 transition"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isSubmitting}
              className="px-5 py-2 bg-violet-600 hover:bg-violet-500 text-white font-semibold rounded-xl shadow-md shadow-violet-600/20 flex items-center gap-1.5 transition disabled:opacity-60"
            >
              {isSubmitting && <Loader2 className="w-3.5 h-3.5 animate-spin" />}
              Save Collection
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

interface SizeInputRow {
  id: string;
  label: string;
  price: string;
  discountPercentage: string;
  costPrice: string;
}

// 3. Add Product SKU Modal with Optional Sizes & Packaging Variants (Matches Mobile App)
export function AddProductModal({ isOpen, onClose }: ModalProps) {
  const { createProduct } = useTenant();

  // Basic Info
  const [name, setName] = useState("");
  const [sku, setSku] = useState("");
  const [category, setCategory] = useState("Agrochemicals");
  const [unit, setUnit] = useState("Liter");
  const [description, setDescription] = useState("");
  const [imageUrl, setImageUrl] = useState("");

  // Base Pricing & Stock
  const [retailPrice, setRetailPrice] = useState("");
  const [discountPercentage, setDiscountPercentage] = useState("0");
  const [costPrice, setCostPrice] = useState("");
  const [stockQuantity, setStockQuantity] = useState("100");
  const [status, setStatus] = useState<"inStock" | "outOfStock">("inStock");

  // Optional Sizes
  const [sizes, setSizes] = useState<SizeInputRow[]>([]);

  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  if (!isOpen) return null;

  // Calculate live base final price
  const baseRetailNum = Number(retailPrice) || 0;
  const baseDiscountNum = Number(discountPercentage) || 0;
  const baseFinalPrice = baseRetailNum > 0
    ? Number((baseRetailNum * (1 - Math.min(100, Math.max(0, baseDiscountNum)) / 100)).toFixed(2))
    : 0;

  // Add Size variant row
  const addSizeRow = () => {
    setSizes((prev) => [
      ...prev,
      {
        id: `row_${Date.now()}_${prev.length}`,
        label: "",
        price: "",
        discountPercentage: "0",
        costPrice: "",
      },
    ]);
  };

  const removeSizeRow = (id: string) => {
    setSizes((prev) => prev.filter((s) => s.id !== id));
  };

  const updateSizeField = (id: string, field: keyof SizeInputRow, value: string) => {
    setSizes((prev) =>
      prev.map((s) => (s.id === id ? { ...s, [field]: value } : s))
    );
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) {
      setError("Please provide a product title.");
      return;
    }

    try {
      setIsSubmitting(true);
      setError(null);

      // Validate and map sizes
      const formattedSizes = sizes
        .filter((s) => s.label.trim().length > 0 && Number(s.price) > 0)
        .map((s) => {
          const sPrice = Number(s.price);
          const sDiscount = Math.min(100, Math.max(0, Number(s.discountPercentage) || 0));
          const sFinal = Number((sPrice * (1 - sDiscount / 100)).toFixed(2));
          return {
            label: s.label.trim(),
            price: sPrice,
            discountPercentage: sDiscount,
            finalPrice: sFinal,
            costPrice: s.costPrice ? Number(s.costPrice) : undefined,
          };
        });

      const res = await createProduct({
        name: name.trim(),
        sku: sku.trim() || undefined,
        category,
        unit,
        description: description.trim() || undefined,
        imageUrl: imageUrl.trim() || undefined,
        retailPrice: baseRetailNum,
        unitPrice: baseRetailNum,
        discountPercentage: baseDiscountNum,
        finalPrice: baseFinalPrice,
        costPrice: costPrice ? Number(costPrice) : undefined,
        stockQuantity: Number(stockQuantity) || 0,
        status,
        sizes: formattedSizes,
      });

      if (res.success) {
        onClose();
        setName("");
        setSku("");
        setRetailPrice("");
        setDiscountPercentage("0");
        setCostPrice("");
        setDescription("");
        setSizes([]);
      } else {
        setError(res.error || "Failed to add product");
      }
    } catch (err: any) {
      setError(err.message);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm animate-in fade-in duration-200 overflow-y-auto">
      <div className="bg-white rounded-2xl max-w-2xl w-full p-6 shadow-2xl border border-slate-100 relative my-8 max-h-[90vh] flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between pb-4 border-b border-slate-100 shrink-0">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center">
              <PackagePlus className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-lg font-bold text-slate-900">Add Product & Packaging Sizes</h2>
              <p className="text-xs text-slate-500">
                Master catalog item with size variants synced to mobile field distributors
              </p>
            </div>
          </div>
          <button onClick={onClose} className="text-slate-400 hover:text-slate-600 p-1 rounded-lg">
            <X className="w-5 h-5" />
          </button>
        </div>

        {error && (
          <div className="mt-4 p-3 bg-rose-50 border border-rose-200 rounded-xl text-rose-700 text-xs shrink-0">
            {error}
          </div>
        )}

        {/* Scrollable Form Body */}
        <form onSubmit={handleSubmit} className="space-y-5 overflow-y-auto pr-1 py-4 text-xs flex-1">
          {/* Section 1: Product Overview */}
          <div className="space-y-3">
            <div className="font-bold text-slate-900 text-xs uppercase tracking-wider flex items-center gap-1.5 text-blue-700">
              <Tag className="w-3.5 h-3.5" />
              1. Product Identification
            </div>

            <div>
              <label className="font-semibold text-slate-700 block mb-1">Product Title *</label>
              <input
                type="text"
                required
                placeholder="e.g. Apex Super Weedicide 48% SL"
                value={name}
                onChange={(e) => setName(e.target.value)}
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 focus:outline-none focus:ring-2 focus:ring-emerald-500/20"
              />
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              <div>
                <label className="font-semibold text-slate-700 block mb-1">Master SKU Code</label>
                <input
                  type="text"
                  placeholder="e.g. APX-WD-48"
                  value={sku}
                  onChange={(e) => setSku(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 focus:outline-none font-mono"
                />
              </div>

              <div>
                <label className="font-semibold text-slate-700 block mb-1">Category</label>
                <input
                  type="text"
                  placeholder="e.g. Agrochemicals, Grains"
                  value={category}
                  onChange={(e) => setCategory(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 focus:outline-none"
                />
              </div>

              <div>
                <label className="font-semibold text-slate-700 block mb-1">Base Unit</label>
                <select
                  value={unit}
                  onChange={(e) => setUnit(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 focus:outline-none"
                >
                  <option value="Liter">Liter (L)</option>
                  <option value="Kg">Kilogram (Kg)</option>
                  <option value="Gram">Gram (g)</option>
                  <option value="Bottle">Bottle</option>
                  <option value="Bag">Bag / Sack</option>
                  <option value="Box">Box / Carton</option>
                  <option value="Piece">Piece</option>
                  <option value="Pack">Pack</option>
                </select>
              </div>
            </div>

            <div>
              <label className="font-semibold text-slate-700 block mb-1">Description / Application Notes (Optional)</label>
              <textarea
                rows={2}
                placeholder="Dosage, formula, composition, or application directions for field dealers..."
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 focus:outline-none resize-none"
              />
            </div>
          </div>

          {/* Section 2: Standard Base Pricing & Inventory */}
          <div className="space-y-3 pt-2 border-t border-slate-100">
            <div className="font-bold text-slate-900 text-xs uppercase tracking-wider flex items-center gap-1.5 text-emerald-700">
              <Percent className="w-3.5 h-3.5" />
              2. Base Pricing & Inventory Stock
            </div>

            <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
              <div>
                <label className="font-semibold text-slate-700 block mb-1">Retail Price (PKR) *</label>
                <input
                  type="number"
                  placeholder="e.g. 1500"
                  value={retailPrice}
                  onChange={(e) => setRetailPrice(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 focus:outline-none focus:ring-2 focus:ring-emerald-500/20 font-semibold"
                />
              </div>

              <div>
                <label className="font-semibold text-slate-700 block mb-1">Discount %</label>
                <input
                  type="number"
                  min="0"
                  max="100"
                  placeholder="0"
                  value={discountPercentage}
                  onChange={(e) => setDiscountPercentage(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 focus:outline-none"
                />
              </div>

              <div>
                <label className="font-semibold text-slate-700 block mb-1">Final Selling Price</label>
                <div className="px-3 py-2 bg-emerald-50/70 border border-emerald-200/80 rounded-xl text-emerald-800 font-extrabold flex items-center justify-between">
                  <span>Rs. {baseFinalPrice.toLocaleString()}</span>
                  {baseDiscountNum > 0 && (
                    <span className="text-[10px] bg-emerald-200 text-emerald-900 px-1.5 py-0.2 rounded font-semibold">
                      -{baseDiscountNum}%
                    </span>
                  )}
                </div>
              </div>

              <div>
                <label className="font-semibold text-slate-700 block mb-1">Cost Price (Optional)</label>
                <input
                  type="number"
                  placeholder="e.g. 1100"
                  value={costPrice}
                  onChange={(e) => setCostPrice(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 focus:outline-none"
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="font-semibold text-slate-700 block mb-1">Initial Stock Units</label>
                <input
                  type="number"
                  placeholder="e.g. 250"
                  value={stockQuantity}
                  onChange={(e) => setStockQuantity(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 focus:outline-none"
                />
              </div>

              <div>
                <label className="font-semibold text-slate-700 block mb-1">Availability Status</label>
                <select
                  value={status}
                  onChange={(e) => setStatus(e.target.value as any)}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 focus:outline-none font-semibold"
                >
                  <option value="inStock">In Stock (Available for field dispatch)</option>
                  <option value="outOfStock">Out of Stock</option>
                </select>
              </div>
            </div>
          </div>

          {/* Section 3: Optional Product Sizes / Packaging Variants */}
          <div className="space-y-3 pt-2 border-t border-slate-100">
            <div className="flex items-center justify-between">
              <div>
                <div className="font-bold text-slate-900 text-xs uppercase tracking-wider flex items-center gap-1.5 text-indigo-700">
                  <Layers className="w-3.5 h-3.5" />
                  3. Optional Size Tiers & Packaging Variants
                </div>
                <p className="text-[11px] text-slate-500 mt-0.5">
                  Define custom packaging sizes (e.g. 500ml, 1L, 5L, 25kg) with individual prices like in the mobile app.
                </p>
              </div>

              <button
                type="button"
                onClick={addSizeRow}
                className="px-3 py-1.5 bg-indigo-50 hover:bg-indigo-100 text-indigo-700 border border-indigo-200 rounded-xl text-xs font-semibold flex items-center gap-1 transition"
              >
                <Plus className="w-3.5 h-3.5" />
                Add Size Variant
              </button>
            </div>

            {sizes.length === 0 ? (
              <div className="p-4 bg-slate-50 border border-dashed border-slate-200 rounded-xl text-center text-slate-500">
                <p className="font-semibold text-xs text-slate-600">No optional size variants added</p>
                <p className="text-[11px] text-slate-400 mt-0.5">
                  Orders will use the default base price above. Click &quot;Add Size Variant&quot; if this item comes in multiple sizes.
                </p>
              </div>
            ) : (
              <div className="space-y-2.5">
                {sizes.map((s, idx) => {
                  const sPriceNum = Number(s.price) || 0;
                  const sDiscNum = Math.min(100, Math.max(0, Number(s.discountPercentage) || 0));
                  const sFinalNum = sPriceNum > 0 ? Number((sPriceNum * (1 - sDiscNum / 100)).toFixed(2)) : 0;

                  return (
                    <div
                      key={s.id}
                      className="p-3 bg-slate-50 border border-slate-200 rounded-xl flex flex-col sm:flex-row sm:items-center gap-2.5"
                    >
                      <div className="w-6 h-6 rounded-full bg-indigo-100 text-indigo-700 font-bold flex items-center justify-center text-[10px] shrink-0">
                        {idx + 1}
                      </div>

                      <div className="flex-1 min-w-[120px]">
                        <label className="text-[10px] font-semibold text-slate-500 block mb-0.5">Size Label *</label>
                        <input
                          type="text"
                          required
                          placeholder="e.g. 500ml, 1 Liter, 5L Can"
                          value={s.label}
                          onChange={(e) => updateSizeField(s.id, "label", e.target.value)}
                          className="w-full px-2.5 py-1.5 bg-white border border-slate-200 rounded-lg text-slate-900 focus:outline-none"
                        />
                      </div>

                      <div className="w-28">
                        <label className="text-[10px] font-semibold text-slate-500 block mb-0.5">Price (PKR) *</label>
                        <input
                          type="number"
                          required
                          placeholder="e.g. 550"
                          value={s.price}
                          onChange={(e) => updateSizeField(s.id, "price", e.target.value)}
                          className="w-full px-2.5 py-1.5 bg-white border border-slate-200 rounded-lg text-slate-900 focus:outline-none font-semibold"
                        />
                      </div>

                      <div className="w-20">
                        <label className="text-[10px] font-semibold text-slate-500 block mb-0.5">Disc %</label>
                        <input
                          type="number"
                          min="0"
                          max="100"
                          placeholder="0"
                          value={s.discountPercentage}
                          onChange={(e) => updateSizeField(s.id, "discountPercentage", e.target.value)}
                          className="w-full px-2.5 py-1.5 bg-white border border-slate-200 rounded-lg text-slate-900 focus:outline-none"
                        />
                      </div>

                      <div className="w-28">
                        <label className="text-[10px] font-semibold text-slate-500 block mb-0.5">Final Selling</label>
                        <div className="px-2.5 py-1.5 bg-indigo-50 border border-indigo-200/70 rounded-lg text-indigo-800 font-bold truncate">
                          Rs. {sFinalNum.toLocaleString()}
                        </div>
                      </div>

                      <div className="w-24">
                        <label className="text-[10px] font-semibold text-slate-500 block mb-0.5">Cost Price</label>
                        <input
                          type="number"
                          placeholder="Cost"
                          value={s.costPrice}
                          onChange={(e) => updateSizeField(s.id, "costPrice", e.target.value)}
                          className="w-full px-2.5 py-1.5 bg-white border border-slate-200 rounded-lg text-slate-900 focus:outline-none"
                        />
                      </div>

                      <button
                        type="button"
                        onClick={() => removeSizeRow(s.id)}
                        className="p-2 text-slate-400 hover:text-rose-600 rounded-lg transition self-end sm:self-center mt-1 sm:mt-4"
                        title="Remove Variant"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  );
                })}
              </div>
            )}
          </div>

          {/* Form Actions */}
          <div className="pt-4 border-t border-slate-100 flex items-center justify-end gap-2 shrink-0">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 border border-slate-200 text-slate-600 rounded-xl hover:bg-slate-50 transition"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isSubmitting}
              className="px-6 py-2 bg-emerald-600 hover:bg-emerald-500 text-white font-semibold rounded-xl shadow-md shadow-emerald-600/20 flex items-center gap-1.5 transition disabled:opacity-60"
            >
              {isSubmitting && <Loader2 className="w-3.5 h-3.5 animate-spin" />}
              Save Product & Variants
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

// 4. Product Details Modal (Inspect All Size Tiers & Profit Margins)
export function ProductDetailModal({
  product,
  isOpen,
  onClose,
}: {
  product: ProductItem | null;
  isOpen: boolean;
  onClose: () => void;
}) {
  const { deleteProduct } = useTenant();
  const [isDeleting, setIsDeleting] = useState(false);

  if (!isOpen || !product) return null;

  const handleDelete = async () => {
    if (confirm(`Are you sure you want to delete "${product.name}" from your catalog?`)) {
      try {
        setIsDeleting(true);
        await deleteProduct(product.id);
        onClose();
      } catch (err: any) {
        alert(err.message || "Failed to delete product");
      } finally {
        setIsDeleting(false);
      }
    }
  };

  const margin = product.costPrice && product.finalPrice > 0
    ? (((product.finalPrice - product.costPrice) / product.finalPrice) * 100).toFixed(1)
    : null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm animate-in fade-in duration-200">
      <div className="bg-white rounded-2xl max-w-lg w-full p-6 shadow-2xl border border-slate-100 relative max-h-[90vh] overflow-y-auto">
        <button onClick={onClose} className="absolute top-4 right-4 text-slate-400 hover:text-slate-600 p-1 rounded-lg">
          <X className="w-5 h-5" />
        </button>

        <div className="flex items-center gap-3 mb-4">
          <div className="w-10 h-10 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center shrink-0">
            <Eye className="w-5 h-5" />
          </div>
          <div>
            <span className="text-[11px] font-semibold text-blue-600 uppercase tracking-wider">{product.category}</span>
            <h2 className="text-lg font-bold text-slate-900 leading-snug">{product.name}</h2>
          </div>
        </div>

        {product.description && (
          <p className="text-xs text-slate-600 bg-slate-50 p-3 rounded-xl mb-4 border border-slate-100">
            {product.description}
          </p>
        )}

        {/* Pricing & Stock Card */}
        <div className="grid grid-cols-2 sm:grid-cols-3 gap-3 mb-4 text-xs">
          <div className="p-3 bg-slate-50 border border-slate-200 rounded-xl">
            <span className="text-slate-400 block text-[10px]">Master SKU</span>
            <span className="font-mono font-bold text-slate-900">{product.sku}</span>
          </div>

          <div className="p-3 bg-slate-50 border border-slate-200 rounded-xl">
            <span className="text-slate-400 block text-[10px]">Base Final Price</span>
            <span className="font-extrabold text-emerald-600 text-sm">
              Rs. {Number(product.finalPrice || product.unitPrice || 0).toLocaleString()}
            </span>
            {product.discountPercentage > 0 && (
              <span className="text-[10px] text-slate-400 block">
                Sticker: Rs. {Number(product.retailPrice || product.unitPrice || 0).toLocaleString()} (-{product.discountPercentage}%)
              </span>
            )}
          </div>

          <div className="p-3 bg-slate-50 border border-slate-200 rounded-xl">
            <span className="text-slate-400 block text-[10px]">Stock Availability</span>
            <span className="font-bold text-slate-900">{product.stockQuantity} {product.unit || "units"}</span>
            <span className="inline-block w-2 h-2 rounded-full bg-emerald-500 ml-1.5" />
          </div>

          {product.costPrice && (
            <div className="p-3 bg-slate-50 border border-slate-200 rounded-xl">
              <span className="text-slate-400 block text-[10px]">Cost Price</span>
              <span className="font-bold text-slate-700">Rs. {Number(product.costPrice).toLocaleString()}</span>
            </div>
          )}

          {margin && (
            <div className="p-3 bg-emerald-50/60 border border-emerald-200 rounded-xl">
              <span className="text-emerald-700 block text-[10px]">Gross Profit Margin</span>
              <span className="font-extrabold text-emerald-800">{margin}%</span>
            </div>
          )}
        </div>

        {/* Size Tiers Breakdown */}
        <div className="space-y-2 mb-6">
          <div className="font-bold text-slate-900 text-xs flex items-center justify-between">
            <span className="flex items-center gap-1.5 text-indigo-700">
              <Layers className="w-3.5 h-3.5" />
              Packaging Sizes & Price Tiers ({product.sizes?.length || 0})
            </span>
          </div>

          {product.sizes && product.sizes.length > 0 ? (
            <div className="divide-y divide-slate-100 border border-slate-200 rounded-xl overflow-hidden">
              {product.sizes.map((s, idx) => (
                <div key={s.id || idx} className="p-2.5 bg-white flex items-center justify-between text-xs hover:bg-slate-50">
                  <div className="flex items-center gap-2">
                    <span className="w-5 h-5 rounded-full bg-indigo-50 text-indigo-600 font-bold text-[10px] flex items-center justify-center">
                      {idx + 1}
                    </span>
                    <span className="font-semibold text-slate-900">{s.label}</span>
                  </div>
                  <div className="flex items-center gap-3">
                    {s.discountPercentage ? (
                      <span className="text-[10px] text-slate-400 line-through">
                        Rs. {Number(s.price).toLocaleString()}
                      </span>
                    ) : null}
                    <span className="font-extrabold text-emerald-700">
                      Rs. {Number(s.finalPrice || s.price).toLocaleString()}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="p-3 bg-slate-50 border border-slate-100 rounded-xl text-center text-slate-400 text-xs">
              This product is sold under a single standard {product.unit || "unit"} packaging.
            </div>
          )}
        </div>

        {/* Footer Actions */}
        <div className="pt-3 border-t border-slate-100 flex items-center justify-between">
          <button
            onClick={handleDelete}
            disabled={isDeleting}
            className="px-3.5 py-1.5 text-rose-600 hover:bg-rose-50 border border-rose-200 rounded-xl text-xs font-semibold flex items-center gap-1.5 transition disabled:opacity-60"
          >
            {isDeleting ? <Loader2 className="w-3.5 h-3.5 animate-spin" /> : <Trash2 className="w-3.5 h-3.5" />}
            Delete SKU
          </button>
          <button
            onClick={onClose}
            className="px-5 py-1.5 bg-slate-900 hover:bg-slate-800 text-white rounded-xl text-xs font-semibold transition"
          >
            Close
          </button>
        </div>
      </div>
    </div>
  );
}

// 5. Issue Distributor Token Modal
export function IssueTokenModal({ isOpen, onClose }: ModalProps) {
  const { issueToken } = useTenant();
  const [distributorName, setDistributorName] = useState("");
  const [phone, setPhone] = useState("");
  const [territoryName, setTerritoryName] = useState("Central Zone");
  const [generatedToken, setGeneratedToken] = useState<string | null>(null);
  const [isCopied, setIsCopied] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    try {
      setIsSubmitting(true);
      setError(null);
      const res = await issueToken({
        territoryName,
        distributorName: distributorName || undefined,
        phone: phone || undefined,
      });

      if (res.success && res.token) {
        setGeneratedToken(res.token.token);
      } else {
        setError(res.error || "Failed to generate token");
      }
    } catch (err: any) {
      setError(err.message);
    } finally {
      setIsSubmitting(false);
    }
  };

  const copyToClipboard = () => {
    if (generatedToken) {
      navigator.clipboard.writeText(generatedToken);
      setIsCopied(true);
      setTimeout(() => setIsCopied(false), 2000);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm animate-in fade-in duration-200">
      <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl border border-slate-100 relative">
        <button
          onClick={() => {
            setGeneratedToken(null);
            onClose();
          }}
          className="absolute top-4 right-4 text-slate-400 hover:text-slate-600 p-1 rounded-lg"
        >
          <X className="w-5 h-5" />
        </button>

        <div className="flex items-center gap-3 mb-5">
          <div className="w-10 h-10 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center">
            <KeyRound className="w-5 h-5" />
          </div>
          <div>
            <h2 className="text-lg font-bold text-slate-900">Issue Distributor Token</h2>
            <p className="text-xs text-slate-500">12-character cryptographic token for field agent terminal</p>
          </div>
        </div>

        {error && (
          <div className="mb-4 p-3 bg-rose-50 border border-rose-200 rounded-xl text-rose-700 text-xs">
            {error}
          </div>
        )}

        {generatedToken ? (
          <div className="space-y-4 text-center py-4">
            <div className="p-4 bg-slate-900 rounded-2xl text-white">
              <span className="text-[11px] text-slate-400 uppercase tracking-widest block mb-1">
                Active Distributor Token
              </span>
              <div className="text-2xl font-mono font-extrabold tracking-wider text-blue-400">
                {generatedToken}
              </div>
            </div>
            <p className="text-xs text-slate-500">
              Provide this code to the distributor. They can enter or scan it in their mobile app to link and sync with your organization.
            </p>
            <div className="flex items-center justify-center gap-2 pt-2">
              <button
                onClick={copyToClipboard}
                className="px-4 py-2 bg-blue-600 hover:bg-blue-500 text-white rounded-xl text-xs font-semibold flex items-center gap-1.5 shadow-md shadow-blue-600/20 transition"
              >
                {isCopied ? <Check className="w-4 h-4" /> : <Copy className="w-4 h-4" />}
                {isCopied ? "Copied!" : "Copy Token"}
              </button>
              <button
                onClick={() => {
                  setGeneratedToken(null);
                  onClose();
                }}
                className="px-4 py-2 border border-slate-200 text-slate-600 rounded-xl text-xs hover:bg-slate-50 transition"
              >
                Done
              </button>
            </div>
          </div>
        ) : (
          <form onSubmit={handleSubmit} className="space-y-3.5 text-xs">
            <div>
              <label className="font-semibold text-slate-700 block mb-1">Field Distributor Name</label>
              <input
                type="text"
                placeholder="e.g. Asad Ullah"
                value={distributorName}
                onChange={(e) => setDistributorName(e.target.value)}
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
              />
            </div>

            <div>
              <label className="font-semibold text-slate-700 block mb-1">Phone Number</label>
              <input
                type="text"
                placeholder="e.g. +92 300 1234567"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
              />
            </div>

            <div>
              <label className="font-semibold text-slate-700 block mb-1">Territory / Zone</label>
              <input
                type="text"
                placeholder="e.g. Lahore South (Zone B)"
                value={territoryName}
                onChange={(e) => setTerritoryName(e.target.value)}
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
              />
            </div>

            <div className="pt-3 flex justify-end gap-2">
              <button
                type="button"
                onClick={onClose}
                className="px-4 py-2 border border-slate-200 text-slate-600 rounded-xl hover:bg-slate-50 transition"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={isSubmitting}
                className="px-5 py-2 bg-blue-600 hover:bg-blue-500 text-white font-semibold rounded-xl shadow-md shadow-blue-600/20 flex items-center gap-1.5 transition disabled:opacity-60"
              >
                {isSubmitting && <Loader2 className="w-3.5 h-3.5 animate-spin" />}
                Generate Token
              </button>
            </div>
          </form>
        )}
      </div>
    </div>
  );
}
