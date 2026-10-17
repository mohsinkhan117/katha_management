"use client";

import React, { useState, useEffect, useRef } from "react";
import {
  X,
  Plus,
  Loader2,
  ShoppingBag,
  CreditCard,
  Banknote,
  Globe,
  HelpCircle,
  Calendar,
  User,
  CheckCircle2,
  Package,
  Store,
  Calculator,
} from "lucide-react";
import { useUser } from "@stackframe/stack";
import { useTenant } from "@/context/TenantContext";
import { LedgerCategory } from "@/lib/ledger/service";

interface AddLedgerItemModalProps {
  isOpen: boolean;
  onClose: () => void;
  categories: LedgerCategory[];
  currentUserName: string;
  defaultDate?: string;
  onSuccess: () => void;
  onCategoryCreated: (category: LedgerCategory) => void;
}

const COMMON_UNITS = [
  { value: "pcs", label: "Pieces / Nos (pcs)" },
  { value: "kg", label: "Kilograms (kg)" },
  { value: "g", label: "Grams (g)" },
  { value: "ltr", label: "Liters (ltr)" },
  { value: "dozen", label: "Dozen (12 pcs)" },
  { value: "bags", label: "Bags / Sacks" },
  { value: "crates", label: "Crates / Peti" },
  { value: "packs", label: "Packs / Cartons" },
  { value: "bill", label: "Bill / Fixed Expense" },
];

const QUICK_ITEMS = [
  { title: "Chicken", unit: "pcs", categoryHint: "Meat & Poultry" },
  { title: "Chicken Meat", unit: "kg", categoryHint: "Meat & Poultry" },
  { title: "Beef / Mutton", unit: "kg", categoryHint: "Meat & Poultry" },
  { title: "Basmati Rice", unit: "kg", categoryHint: "Groceries & Spices" },
  { title: "Cooking Oil / Ghee", unit: "ltr", categoryHint: "Groceries & Spices" },
  { title: "Onions & Tomatoes", unit: "kg", categoryHint: "Vegetables & Fruits" },
  { title: "Potatoes", unit: "kg", categoryHint: "Vegetables & Fruits" },
  { title: "Milk & Yogurt", unit: "ltr", categoryHint: "Dairy & Bakery" },
  { title: "Eggs", unit: "dozen", categoryHint: "Dairy & Bakery" },
  { title: "Atta / Flour", unit: "bags", categoryHint: "Groceries & Spices" },
  { title: "LPG Gas Cylinder", unit: "pcs", categoryHint: "Kitchen Supplies & Gas" },
];

export function AddLedgerItemModal({
  isOpen,
  onClose,
  categories,
  currentUserName,
  defaultDate,
  onSuccess,
  onCategoryCreated,
}: AddLedgerItemModalProps) {
  const user = useUser();
  const { activeTenant } = useTenant();

  const [title, setTitle] = useState("");
  const [quantityInput, setQuantityInput] = useState("1");
  const [unit, setUnit] = useState("pcs");
  const [unitCostInput, setUnitCostInput] = useState("");
  const [totalCostInput, setTotalCostInput] = useState("");
  const [vendorName, setVendorName] = useState("");
  const [categoryId, setCategoryId] = useState("");
  const [localCategories, setLocalCategories] = useState<LedgerCategory[]>([]);
  const [paymentMethod, setPaymentMethod] = useState<"cash" | "card" | "online" | "other">("cash");
  const [dateTime, setDateTime] = useState("");

  // Custom Category Creation State
  const [isAddingCategory, setIsAddingCategory] = useState(false);
  const [newCategoryName, setNewCategoryName] = useState("");
  const [isCreatingCategory, setIsCreatingCategory] = useState(false);

  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [successToast, setSuccessToast] = useState<string | null>(null);

  const titleInputRef = useRef<HTMLInputElement>(null);

  const getAuthHeaders = (): Record<string, string> => {
    const headers: Record<string, string> = {
      "Content-Type": "application/json",
    };
    if (activeTenant?.id) {
      headers["x-tenant-id"] = activeTenant.id;
    }
    const email = user?.primaryEmail || activeTenant?.admin_email;
    if (email) {
      headers["x-user-email"] = email;
    }
    if (currentUserName) {
      headers["x-user-name"] = currentUserName;
    }
    return headers;
  };

  // Merge prop categories and locally fetched categories
  const combinedCategories = categories.length > 0 ? categories : localCategories;
  const expenseCategories = combinedCategories.filter((c) => c.type === "expense");
  const activeCategories = expenseCategories.length > 0 ? expenseCategories : combinedCategories;

  // Auto-fetch categories if modal opens and categories list is empty
  useEffect(() => {
    if (isOpen && categories.length === 0 && localCategories.length === 0) {
      fetch("/api/ledger/categories", {
        headers: getAuthHeaders(),
        credentials: "include",
      })
        .then((res) => res.json())
        .then((json) => {
          if (json.success && Array.isArray(json.data)) {
            setLocalCategories(json.data);
          }
        })
        .catch((err) => console.error("Failed to fetch fallback categories:", err));
    }
  }, [isOpen, categories.length, localCategories.length, activeTenant?.id]);

  // Initialize date time string to local ISO
  useEffect(() => {
    if (isOpen) {
      const now = new Date();
      const offsetMs = now.getTimezoneOffset() * 60000;
      const localNowISO = new Date(now.getTime() - offsetMs).toISOString().slice(0, 16);

      if (defaultDate && defaultDate !== localNowISO.slice(0, 10)) {
        setDateTime(`${defaultDate}T12:00`);
      } else {
        setDateTime(localNowISO);
      }
      setError(null);
      setSuccessToast(null);

      setTimeout(() => {
        titleInputRef.current?.focus();
      }, 100);
    }
  }, [isOpen, defaultDate]);

  // Auto-select first category
  useEffect(() => {
    if (activeCategories.length > 0) {
      if (!activeCategories.some((c) => c.id === categoryId)) {
        setCategoryId(activeCategories[0].id);
      }
    } else {
      setCategoryId("");
    }
  }, [activeCategories, categoryId]);

  if (!isOpen) return null;

  // Two-way calculation handlers for Quantity, Unit Cost, and Total Cost Price
  const handleQuantityChange = (val: string) => {
    setQuantityInput(val);
    const qty = parseFloat(val);
    const uCost = parseFloat(unitCostInput);
    if (!isNaN(qty) && qty > 0 && !isNaN(uCost) && uCost > 0) {
      setTotalCostInput((qty * uCost).toFixed(2).replace(/\.00$/, ""));
    }
  };

  const handleUnitCostChange = (val: string) => {
    setUnitCostInput(val);
    const qty = parseFloat(quantityInput) || 1;
    const uCost = parseFloat(val);
    if (!isNaN(uCost) && uCost >= 0) {
      setTotalCostInput((qty * uCost).toFixed(2).replace(/\.00$/, ""));
    } else {
      setTotalCostInput("");
    }
  };

  const handleTotalCostChange = (val: string) => {
    setTotalCostInput(val);
    const qty = parseFloat(quantityInput) || 1;
    const tCost = parseFloat(val);
    if (!isNaN(tCost) && tCost >= 0 && qty > 0) {
      setUnitCostInput((tCost / qty).toFixed(2).replace(/\.00$/, ""));
    } else {
      setUnitCostInput("");
    }
  };

  const handleQuickItemSelect = (item: (typeof QUICK_ITEMS)[number]) => {
    setTitle(item.title);
    setUnit(item.unit);
    const matchedCat = activeCategories.find(
      (c) => c.name.toLowerCase() === item.categoryHint.toLowerCase()
    );
    if (matchedCat) {
      setCategoryId(matchedCat.id);
    }
  };

  const getTotalAmountMinor = (): number => {
    const parsed = parseFloat(totalCostInput);
    if (isNaN(parsed) || parsed <= 0) return 0;
    return Math.round(parsed * 100);
  };

  const getUnitCostMinor = (): number => {
    const parsed = parseFloat(unitCostInput);
    if (isNaN(parsed) || parsed <= 0) {
      const total = getTotalAmountMinor();
      const qty = parseFloat(quantityInput) || 1;
      return qty > 0 ? Math.round(total / qty) : total;
    }
    return Math.round(parsed * 100);
  };

  const handleCreateCategory = async () => {
    if (!newCategoryName.trim()) return;
    try {
      setIsCreatingCategory(true);
      setError(null);
      const res = await fetch("/api/ledger/categories", {
        method: "POST",
        headers: getAuthHeaders(),
        credentials: "include",
        body: JSON.stringify({
          name: newCategoryName.trim(),
          type: "expense",
        }),
      });
      const json = await res.json();
      if (json.success && json.data) {
        onCategoryCreated(json.data);
        setLocalCategories((prev) => [...prev, json.data]);
        setCategoryId(json.data.id);
        setIsAddingCategory(false);
        setNewCategoryName("");
      } else {
        setError(json.error || "Failed to create category");
      }
    } catch (err: any) {
      setError(err.message);
    } finally {
      setIsCreatingCategory(false);
    }
  };

  const submitEntry = async (keepOpen: boolean = false) => {
    const amountMinor = getTotalAmountMinor();
    const unitCostMinor = getUnitCostMinor();
    const quantity = parseFloat(quantityInput) || 1;

    if (!title.trim()) {
      setError("Please enter the item name (e.g., Chicken, Rice, Cooking Oil).");
      titleInputRef.current?.focus();
      return;
    }
    if (quantity <= 0) {
      setError("Quantity must be greater than 0.");
      return;
    }
    if (amountMinor <= 0) {
      setError("Please enter the Cost Price (greater than Rs. 0).");
      return;
    }

    try {
      setIsSubmitting(true);
      setError(null);

      const selectedCategoryObj = activeCategories.find((c) => c.id === categoryId);

      const payload = {
        type: "expense" as const,
        title: title.trim(),
        categoryId: categoryId || null,
        categoryName: selectedCategoryObj?.name || null,
        quantity,
        unit,
        unitCostMinor,
        amountMinor,
        vendorName: vendorName.trim() || null,
        currency: "PKR",
        paymentMethod,
        occurredAt: dateTime ? new Date(dateTime).toISOString() : new Date().toISOString(),
      };

      const res = await fetch("/api/ledger/entries", {
        method: "POST",
        headers: getAuthHeaders(),
        credentials: "include",
        body: JSON.stringify(payload),
      });

      const json = await res.json();
      if (json.success) {
        onSuccess();
        if (keepOpen) {
          setTitle("");
          setQuantityInput("1");
          setUnitCostInput("");
          setTotalCostInput("");
          setSuccessToast(
            `Added "${quantity} ${unit} ${payload.title}" (Rs. ${(amountMinor / 100).toLocaleString()}) to Khata!`
          );
          setTimeout(() => setSuccessToast(null), 3500);
          titleInputRef.current?.focus();
        } else {
          setTitle("");
          setQuantityInput("1");
          setUnitCostInput("");
          setTotalCostInput("");
          setVendorName("");
          onClose();
        }
      } else {
        setError(json.error || "Failed to save item entry.");
      }
    } catch (err: any) {
      setError(err.message || "An unexpected error occurred.");
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    submitEntry(false);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm animate-in fade-in duration-200">
      <div className="bg-white rounded-2xl max-w-xl w-full p-6 shadow-2xl border border-slate-200 relative max-h-[92vh] overflow-y-auto">
        <button
          onClick={onClose}
          className="absolute top-4 right-4 text-slate-400 hover:text-slate-600 p-1.5 rounded-lg hover:bg-slate-100 transition"
          tabIndex={-1}
        >
          <X className="w-5 h-5" />
        </button>

        {/* Modal Header */}
        <div className="flex items-center gap-3 mb-4">
          <div className="w-11 h-11 rounded-xl flex items-center justify-center text-white bg-emerald-600 shadow-md shadow-emerald-600/25">
            <ShoppingBag className="w-5 h-5" />
          </div>
          <div>
            <h2 className="text-lg font-bold text-slate-900">
              Add Item Brought to Hotel / Khata
            </h2>
            <p className="text-xs text-slate-500">
              Record item name, quantity (e.g. 100 Chicken), and its cost price for daily, weekly & monthly tracking
            </p>
          </div>
        </div>

        {/* Feedback Alerts */}
        {error && (
          <div className="mb-4 p-3 bg-rose-50 border border-rose-200 rounded-xl text-rose-700 text-xs font-medium animate-in fade-in">
            {error}
          </div>
        )}

        {successToast && (
          <div className="mb-4 p-3 bg-emerald-50 border border-emerald-200 rounded-xl text-emerald-800 text-xs flex items-center gap-2 animate-in fade-in">
            <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />
            <span className="font-semibold">{successToast}</span>
          </div>
        )}

        {/* Quick Select Common Hotel Items */}
        <div className="mb-4">
          <span className="text-[11px] font-semibold text-slate-500 uppercase tracking-wider block mb-1.5">
            Quick Pick Common Items:
          </span>
          <div className="flex flex-wrap gap-1.5">
            {QUICK_ITEMS.map((item) => (
              <button
                key={item.title}
                type="button"
                onClick={() => handleQuickItemSelect(item)}
                className={`px-2.5 py-1 rounded-lg text-[11px] font-medium border transition ${
                  title.toLowerCase() === item.title.toLowerCase()
                    ? "bg-emerald-600 text-white border-emerald-600 shadow-sm"
                    : "bg-slate-50 hover:bg-slate-100 text-slate-700 border-slate-200"
                }`}
              >
                + {item.title}
              </button>
            ))}
          </div>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4 text-xs">
          {/* 1. Item Name */}
          <div>
            <label className="font-semibold text-slate-700 block mb-1">
              Item Brought / Expense Title *
            </label>
            <div className="relative">
              <Package className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
              <input
                ref={titleInputRef}
                type="text"
                required
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="e.g., Chicken, Basmati Rice, Cooking Oil, Fresh Milk..."
                className="w-full pl-9 pr-3.5 py-2.5 rounded-xl border border-slate-200 focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-600 text-slate-900 font-medium text-sm"
              />
            </div>
          </div>

          {/* 2. Quantity & Unit */}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="font-semibold text-slate-700 block mb-1">
                Quantity Brought *
              </label>
              <input
                type="number"
                step="0.01"
                min="0.01"
                required
                value={quantityInput}
                onChange={(e) => handleQuantityChange(e.target.value)}
                placeholder="e.g., 100"
                className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-600 text-slate-900 font-bold text-sm font-mono"
              />
            </div>

            <div>
              <label className="font-semibold text-slate-700 block mb-1">
                Measurement Unit *
              </label>
              <select
                value={unit}
                onChange={(e) => setUnit(e.target.value)}
                className="w-full px-3 py-2.5 rounded-xl border border-slate-200 bg-white focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-600 text-slate-900 font-medium text-xs"
              >
                {COMMON_UNITS.map((u) => (
                  <option key={u.value} value={u.value}>
                    {u.label}
                  </option>
                ))}
              </select>
            </div>
          </div>

          {/* 3. Cost Price Calculator Box (Unit Cost & Total Cost Price) */}
          <div className="p-3.5 bg-emerald-50/60 border border-emerald-200/80 rounded-xl space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-[11px] font-bold text-emerald-900 uppercase tracking-wider flex items-center gap-1.5">
                <Calculator className="w-3.5 h-3.5 text-emerald-600" />
                Cost Price Details (Enter either Unit Rate or Total Cost)
              </span>
              {getTotalAmountMinor() > 0 && (
                <span className="text-xs font-extrabold text-emerald-700 font-mono">
                  {quantityInput || 1} {unit} × Rs.{" "}
                  {(getUnitCostMinor() / 100).toLocaleString()} = Rs.{" "}
                  {(getTotalAmountMinor() / 100).toLocaleString()}
                </span>
              )}
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div>
                <label className="font-semibold text-slate-700 block mb-1">
                  Rate per {unit} (PKR)
                </label>
                <div className="relative">
                  <span className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 font-bold text-xs">
                    Rs.
                  </span>
                  <input
                    type="number"
                    step="0.01"
                    min="0"
                    value={unitCostInput}
                    onChange={(e) => handleUnitCostChange(e.target.value)}
                    placeholder="e.g., 450"
                    className="w-full pl-9 pr-3 py-2 rounded-xl border border-slate-200 bg-white focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-600 text-slate-900 font-mono font-semibold text-sm"
                  />
                </div>
              </div>

              <div>
                <label className="font-bold text-emerald-900 block mb-1">
                  Total Cost Price (PKR) *
                </label>
                <div className="relative">
                  <span className="absolute left-3 top-1/2 -translate-y-1/2 text-emerald-700 font-bold text-xs">
                    Rs.
                  </span>
                  <input
                    type="number"
                    step="0.01"
                    min="0.01"
                    required
                    value={totalCostInput}
                    onChange={(e) => handleTotalCostChange(e.target.value)}
                    placeholder="e.g., 45000"
                    className="w-full pl-9 pr-3 py-2 rounded-xl border-2 border-emerald-500/50 bg-white focus:outline-none focus:ring-2 focus:ring-emerald-500/30 focus:border-emerald-600 text-slate-900 font-mono font-extrabold text-sm"
                  />
                </div>
              </div>
            </div>
          </div>

          {/* 4. Category & Supplier */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <div className="flex items-center justify-between mb-1">
                <label className="font-semibold text-slate-700">Expense Category *</label>
                <button
                  type="button"
                  onClick={() => setIsAddingCategory(!isAddingCategory)}
                  className="text-[11px] font-semibold text-emerald-600 hover:text-emerald-700 flex items-center gap-0.5"
                >
                  <Plus className="w-3 h-3" />
                  {isAddingCategory ? "Cancel" : "New Category"}
                </button>
              </div>

              {isAddingCategory ? (
                <div className="flex gap-1.5">
                  <input
                    type="text"
                    value={newCategoryName}
                    onChange={(e) => setNewCategoryName(e.target.value)}
                    placeholder="Category name..."
                    className="flex-1 px-2.5 py-2 rounded-xl border border-emerald-300 focus:outline-none text-slate-900 text-xs"
                  />
                  <button
                    type="button"
                    disabled={isCreatingCategory || !newCategoryName.trim()}
                    onClick={handleCreateCategory}
                    className="px-3 py-2 bg-emerald-600 hover:bg-emerald-500 text-white font-semibold rounded-xl disabled:opacity-50"
                  >
                    {isCreatingCategory ? <Loader2 className="w-3.5 h-3.5 animate-spin" /> : "Add"}
                  </button>
                </div>
              ) : (
                <select
                  value={categoryId}
                  onChange={(e) => setCategoryId(e.target.value)}
                  className="w-full px-3 py-2.5 rounded-xl border border-slate-200 bg-white focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-600 text-slate-900 font-medium"
                >
                  {activeCategories.length > 0 ? (
                    activeCategories.map((c) => (
                      <option key={c.id} value={c.id}>
                        {c.name}
                      </option>
                    ))
                  ) : (
                    <option value="">General Khata Expense (Default)</option>
                  )}
                </select>
              )}
            </div>

            <div>
              <label className="font-semibold text-slate-700 block mb-1">
                Supplier / Market (Optional)
              </label>
              <div className="relative">
                <Store className="w-3.5 h-3.5 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                <input
                  type="text"
                  value={vendorName}
                  onChange={(e) => setVendorName(e.target.value)}
                  placeholder="e.g., Sabzi Mandi, Poultry Farm..."
                  className="w-full pl-8 pr-3 py-2.5 rounded-xl border border-slate-200 focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-600 text-slate-900"
                />
              </div>
            </div>
          </div>

          {/* 5. Date & Payment Method */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label className="font-semibold text-slate-700 flex items-center gap-1 mb-1">
                <Calendar className="w-3.5 h-3.5 text-slate-400" />
                Date & Time Brought
              </label>
              <input
                type="datetime-local"
                value={dateTime}
                onChange={(e) => setDateTime(e.target.value)}
                className="w-full px-3 py-2 rounded-xl border border-slate-200 focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-600 text-slate-900 font-mono text-xs"
              />
            </div>

            <div>
              <label className="font-semibold text-slate-700 block mb-1">Payment Mode</label>
              <div className="grid grid-cols-4 gap-1.5">
                {[
                  { id: "cash", label: "Cash", icon: Banknote },
                  { id: "online", label: "Online", icon: Globe },
                  { id: "card", label: "Card", icon: CreditCard },
                  { id: "other", label: "Udhaar", icon: HelpCircle },
                ].map((pm) => {
                  const Icon = pm.icon;
                  const active = paymentMethod === pm.id;
                  return (
                    <button
                      key={pm.id}
                      type="button"
                      onClick={() => setPaymentMethod(pm.id as any)}
                      className={`flex flex-col items-center justify-center gap-0.5 py-1.5 px-1 rounded-lg border font-semibold transition-all text-[10px] ${
                        active
                          ? "bg-slate-900 text-white border-slate-900 shadow-sm"
                          : "bg-slate-50 text-slate-600 border-slate-200 hover:bg-slate-100"
                      }`}
                    >
                      <Icon className="w-3.5 h-3.5" />
                      <span>{pm.label}</span>
                    </button>
                  );
                })}
              </div>
            </div>
          </div>

          {/* Recorded By Read-only Info */}
          <div className="flex items-center justify-between px-3 py-2 bg-slate-50 rounded-xl border border-slate-200/80 text-slate-500">
            <span className="flex items-center gap-1.5">
              <User className="w-3.5 h-3.5 text-slate-400" />
              Recorded by:{" "}
              <strong className="text-slate-700">{currentUserName || "Admin"}</strong>
            </span>
            <span className="text-[11px] text-emerald-700 font-semibold">
              Party Khata Expense
            </span>
          </div>

          {/* Action Buttons */}
          <div className="flex flex-col sm:flex-row items-center justify-end gap-2.5 pt-3 border-t border-slate-100">
            <button
              type="button"
              onClick={onClose}
              className="w-full sm:w-auto px-4 py-2.5 rounded-xl border border-slate-200 text-slate-600 font-semibold hover:bg-slate-50 transition"
            >
              Cancel
            </button>
            <button
              type="button"
              disabled={isSubmitting}
              onClick={() => submitEntry(true)}
              className="w-full sm:w-auto px-4 py-2.5 rounded-xl border border-emerald-300 bg-emerald-50 hover:bg-emerald-100 text-emerald-800 font-bold transition flex items-center justify-center gap-1.5 disabled:opacity-50"
            >
              {isSubmitting ? (
                <Loader2 className="w-4 h-4 animate-spin" />
              ) : (
                <Plus className="w-4 h-4" />
              )}
              Save & Add Next Item
            </button>
            <button
              type="submit"
              disabled={isSubmitting}
              className="w-full sm:w-auto px-5 py-2.5 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white font-bold shadow-md shadow-emerald-600/20 transition flex items-center justify-center gap-1.5 disabled:opacity-50"
            >
              {isSubmitting && <Loader2 className="w-4 h-4 animate-spin" />}
              Save Item to Khata
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
