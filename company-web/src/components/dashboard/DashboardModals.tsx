"use client";

import React, { useState } from "react";
import { X, Check, Copy, ShoppingBag, Receipt, PackagePlus, KeyRound, Loader2 } from "lucide-react";
import { useTenant } from "@/context/TenantContext";

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

// 3. Add Product SKU Modal
export function AddProductModal({ isOpen, onClose }: ModalProps) {
  const { createProduct } = useTenant();
  const [name, setName] = useState("");
  const [sku, setSku] = useState("");
  const [category, setCategory] = useState("General");
  const [unitPrice, setUnitPrice] = useState("");
  const [stockQuantity, setStockQuantity] = useState("100");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name || !unitPrice) {
      setError("Please provide product name and price.");
      return;
    }

    try {
      setIsSubmitting(true);
      setError(null);
      const res = await createProduct({
        name,
        sku: sku || undefined,
        category,
        unitPrice: Number(unitPrice),
        stockQuantity: Number(stockQuantity) || 0,
      });

      if (res.success) {
        onClose();
        setName("");
        setSku("");
        setUnitPrice("");
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
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm animate-in fade-in duration-200">
      <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl border border-slate-100 relative">
        <button onClick={onClose} className="absolute top-4 right-4 text-slate-400 hover:text-slate-600 p-1 rounded-lg">
          <X className="w-5 h-5" />
        </button>

        <div className="flex items-center gap-3 mb-5">
          <div className="w-10 h-10 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center">
            <PackagePlus className="w-5 h-5" />
          </div>
          <div>
            <h2 className="text-lg font-bold text-slate-900">Add Product SKU</h2>
            <p className="text-xs text-slate-500">Save commercial catalog item to Neon PostgreSQL</p>
          </div>
        </div>

        {error && (
          <div className="mb-4 p-3 bg-rose-50 border border-rose-200 rounded-xl text-rose-700 text-xs">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-3.5 text-xs">
          <div>
            <label className="font-semibold text-slate-700 block mb-1">Product Title *</label>
            <input
              type="text"
              required
              placeholder="e.g. Supreme Super Basmati Rice 25kg"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 focus:outline-none focus:ring-2 focus:ring-emerald-500/20"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="font-semibold text-slate-700 block mb-1">SKU Code</label>
              <input
                type="text"
                placeholder="e.g. BAS-SUP-025"
                value={sku}
                onChange={(e) => setSku(e.target.value)}
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 focus:outline-none font-mono"
              />
            </div>
            <div>
              <label className="font-semibold text-slate-700 block mb-1">Category</label>
              <input
                type="text"
                placeholder="e.g. Grains & Crops"
                value={category}
                onChange={(e) => setCategory(e.target.value)}
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 focus:outline-none"
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="font-semibold text-slate-700 block mb-1">Unit Trade Price (PKR) *</label>
              <input
                type="number"
                required
                placeholder="e.g. 2300"
                value={unitPrice}
                onChange={(e) => setUnitPrice(e.target.value)}
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 focus:outline-none focus:ring-2 focus:ring-emerald-500/20"
              />
            </div>
            <div>
              <label className="font-semibold text-slate-700 block mb-1">Initial Stock Units</label>
              <input
                type="number"
                placeholder="e.g. 150"
                value={stockQuantity}
                onChange={(e) => setStockQuantity(e.target.value)}
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 focus:outline-none"
              />
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
              className="px-5 py-2 bg-emerald-600 hover:bg-emerald-500 text-white font-semibold rounded-xl shadow-md shadow-emerald-600/20 flex items-center gap-1.5 transition disabled:opacity-60"
            >
              {isSubmitting && <Loader2 className="w-3.5 h-3.5 animate-spin" />}
              Save SKU
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

// 4. Issue Distributor Token Modal
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

