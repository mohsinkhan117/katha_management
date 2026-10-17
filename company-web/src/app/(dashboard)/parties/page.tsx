"use client";

import React, { useState, useMemo } from "react";
import {
  Search,
  Plus,
  Users,
  MapPin,
  Phone,
  UserCheck,
  Store,
  ShoppingBag,
  Trash2,
  X,
  Loader2,
  CheckCircle2,
} from "lucide-react";
import { useTenant } from "@/context/TenantContext";

interface CustomerPartyRow {
  id: string;
  name: string;
  ownerName: string;
  phone: string;
  territory: string;
  ordersCount: number;
  totalOrderValue: number;
  createdAt?: string;
  isFromOrdersOnly?: boolean;
}

export default function CompanyPartiesCustomersPage() {
  const { activeTenant, tenantData, createParty, deleteParty } = useTenant();
  const [search, setSearch] = useState("");
  const [territoryFilter, setTerritoryFilter] = useState("all");

  // Add Party Modal state
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [partyName, setPartyName] = useState("");
  const [ownerName, setOwnerName] = useState("");
  const [phone, setPhone] = useState("");
  const [territory, setTerritory] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  // Combine registered parties in DB with any customer names from B2B orders
  const partiesList: CustomerPartyRow[] = useMemo(() => {
    const dbParties = tenantData?.parties || [];
    const orders = tenantData?.orders || [];

    // Aggregate order counts & values per party name (case-insensitive)
    const orderStatsByParty = new Map<
      string,
      { count: number; totalAmount: number; latestDate?: string }
    >();

    for (const o of orders) {
      if (!o.partyName) continue;
      const key = o.partyName.trim().toLowerCase();
      const prev = orderStatsByParty.get(key) || { count: 0, totalAmount: 0 };
      prev.count += 1;
      prev.totalAmount += Number(o.totalAmount || 0);
      if (!prev.latestDate && o.date) {
        prev.latestDate = o.date;
      }
      orderStatsByParty.set(key, prev);
    }

    const seenNames = new Set<string>();
    const rows: CustomerPartyRow[] = [];

    for (const p of dbParties) {
      const key = p.name.trim().toLowerCase();
      seenNames.add(key);
      const stats = orderStatsByParty.get(key);
      rows.push({
        id: p.id,
        name: p.name,
        ownerName: p.ownerName || "Proprietor",
        phone: p.phone || "N/A",
        territory: p.territory || "General Zone",
        ordersCount: stats?.count || 0,
        totalOrderValue: stats?.totalAmount || 0,
        createdAt: p.createdAt,
        isFromOrdersOnly: false,
      });
    }

    // Also include any customers who placed B2B orders but weren't added to `parties` yet
    let idx = 1;
    for (const o of orders) {
      if (!o.partyName) continue;
      const key = o.partyName.trim().toLowerCase();
      if (seenNames.has(key)) continue;
      seenNames.add(key);
      const stats = orderStatsByParty.get(key);
      rows.push({
        id: `ord_pty_${idx++}`,
        name: o.partyName,
        ownerName: "Registered via Order",
        phone: "—",
        territory: "Assigned Territory",
        ordersCount: stats?.count || 1,
        totalOrderValue: stats?.totalAmount || Number(o.totalAmount || 0),
        createdAt: o.date,
        isFromOrdersOnly: true,
      });
    }

    return rows;
  }, [tenantData?.parties, tenantData?.orders]);

  // Unique territories for filter dropdown
  const territories = useMemo(() => {
    const set = new Set<string>();
    for (const p of partiesList) {
      if (p.territory) set.add(p.territory);
    }
    for (const d of tenantData?.distributors || []) {
      if (d.territory) set.add(d.territory);
    }
    return Array.from(set);
  }, [partiesList, tenantData?.distributors]);

  const filteredParties = useMemo(() => {
    return partiesList.filter((p) => {
      const matchesTerritory =
        territoryFilter === "all" || p.territory === territoryFilter;
      const q = search.trim().toLowerCase();
      const matchesSearch =
        !q ||
        p.name.toLowerCase().includes(q) ||
        p.ownerName.toLowerCase().includes(q) ||
        p.phone.toLowerCase().includes(q) ||
        p.territory.toLowerCase().includes(q);
      return matchesTerritory && matchesSearch;
    });
  }, [partiesList, search, territoryFilter]);

  const activeOrderingPartiesCount = useMemo(
    () => partiesList.filter((p) => p.ordersCount > 0).length,
    [partiesList]
  );

  const handleAddParty = async (e: React.FormEvent) => {
    e.preventDefault();
    setFormError(null);

    if (!partyName.trim()) {
      setFormError("Party / Customer business name is required.");
      return;
    }

    setIsSubmitting(true);
    try {
      const res = await createParty({
        name: partyName.trim(),
        ownerName: ownerName.trim() || "Proprietor",
        phone: phone.trim() || "N/A",
        territory: territory.trim() || "General Zone",
      });

      if (!res.success) {
        setFormError(res.error || "Failed to add customer party.");
        return;
      }

      setPartyName("");
      setOwnerName("");
      setPhone("");
      setTerritory("");
      setIsAddModalOpen(false);
      setToastMessage("Customer party added successfully.");
      setTimeout(() => setToastMessage(null), 3500);
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDeleteParty = async (party: CustomerPartyRow) => {
    if (party.isFromOrdersOnly) return;
    await deleteParty(party.id);
    setToastMessage(`Removed "${party.name}" from parties directory.`);
    setTimeout(() => setToastMessage(null), 3000);
  };

  return (
    <div className="max-w-7xl mx-auto space-y-6 pb-12">
      {/* Toast Notification */}
      {toastMessage && (
        <div className="fixed bottom-5 right-5 z-50 flex items-center gap-2.5 bg-slate-900 text-white px-4 py-3 rounded-xl shadow-xl border border-slate-700 text-xs font-semibold">
          <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0" />
          <span>{toastMessage}</span>
        </div>
      )}

      {/* Top Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 bg-white border border-slate-200 rounded-2xl p-5 shadow-sm">
        <div className="flex items-center gap-3">
          <div className="p-2.5 rounded-xl bg-blue-600 text-white shadow-md shadow-blue-600/20">
            <Store className="w-5 h-5" />
          </div>
          <div>
            <h1 className="text-xl font-extrabold text-slate-900 tracking-tight">
              Parties / Customers Directory
            </h1>
            <p className="text-xs text-slate-500 mt-0.5">
              Manage B2B customer accounts, proprietors, contact details, and assigned sales territories for{" "}
              <span className="font-semibold text-slate-700">
                {activeTenant?.name || "your company"}
              </span>
              .
            </p>
          </div>
        </div>

        <button
          onClick={() => {
            setFormError(null);
            setIsAddModalOpen(true);
          }}
          className="flex items-center gap-2 px-4 py-2.5 bg-blue-600 hover:bg-blue-500 active:bg-blue-700 text-white rounded-xl text-xs sm:text-sm font-bold shadow-md shadow-blue-600/20 transition self-start sm:self-auto"
        >
          <Plus className="w-4 h-4" />
          <span>Add Party / Customer</span>
        </button>
      </div>

      {/* Summary KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm flex items-center justify-between">
          <div>
            <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">
              Total Parties / Customers
            </span>
            <div className="text-2xl font-extrabold text-slate-900 mt-1">
              {partiesList.length}
            </div>
            <span className="text-[11px] text-slate-500 mt-0.5 block">
              Registered customer accounts
            </span>
          </div>
          <div className="w-11 h-11 rounded-xl bg-blue-50 border border-blue-100 text-blue-600 flex items-center justify-center">
            <Users className="w-5 h-5" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm flex items-center justify-between">
          <div>
            <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">
              Active Ordering Customers
            </span>
            <div className="text-2xl font-extrabold text-emerald-600 mt-1">
              {activeOrderingPartiesCount}
            </div>
            <span className="text-[11px] text-slate-500 mt-0.5 block">
              Customers with B2B orders placed
            </span>
          </div>
          <div className="w-11 h-11 rounded-xl bg-emerald-50 border border-emerald-100 text-emerald-600 flex items-center justify-center">
            <UserCheck className="w-5 h-5" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm flex items-center justify-between">
          <div>
            <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">
              Territories Covered
            </span>
            <div className="text-2xl font-extrabold text-indigo-600 mt-1">
              {territories.length}
            </div>
            <span className="text-[11px] text-slate-500 mt-0.5 block">
              Active commercial zones
            </span>
          </div>
          <div className="w-11 h-11 rounded-xl bg-indigo-50 border border-indigo-100 text-indigo-600 flex items-center justify-center">
            <MapPin className="w-5 h-5" />
          </div>
        </div>
      </div>

      {/* Search & Territory Filter Bar */}
      <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-3">
        <div className="relative flex-1 max-w-md">
          <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search customer party, proprietor, phone, or territory..."
            className="w-full pl-9 pr-4 py-2 text-xs bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 text-slate-800"
          />
        </div>

        <div className="flex items-center gap-2">
          <span className="text-xs font-semibold text-slate-500">Territory:</span>
          <select
            value={territoryFilter}
            onChange={(e) => setTerritoryFilter(e.target.value)}
            className="px-3 py-2 text-xs bg-slate-50 border border-slate-200 rounded-xl text-slate-700 font-medium focus:outline-none focus:ring-2 focus:ring-blue-500/20"
          >
            <option value="all">All Territories ({partiesList.length})</option>
            {territories.map((t) => (
              <option key={t} value={t}>
                {t}
              </option>
            ))}
          </select>
        </div>
      </div>

      {/* Parties / Customers Table */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead>
              <tr className="bg-slate-50/80 border-b border-slate-200 text-slate-500 uppercase tracking-wider text-[11px]">
                <th className="py-3.5 px-4 font-semibold">Party / Customer Name</th>
                <th className="py-3.5 px-4 font-semibold">Proprietor / Contact</th>
                <th className="py-3.5 px-4 font-semibold">Phone Number</th>
                <th className="py-3.5 px-4 font-semibold">Territory / Zone</th>
                <th className="py-3.5 px-4 font-semibold text-center">B2B Orders</th>
                <th className="py-3.5 px-4 font-semibold text-right">Total Order Volume</th>
                <th className="py-3.5 px-4 font-semibold text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {filteredParties.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-14 px-4 text-center">
                    <div className="max-w-sm mx-auto flex flex-col items-center justify-center space-y-3">
                      <div className="w-12 h-12 rounded-2xl bg-slate-100 text-slate-400 flex items-center justify-center">
                        <Store className="w-6 h-6" />
                      </div>
                      <div className="space-y-1">
                        <div className="text-sm font-bold text-slate-800">
                          {partiesList.length === 0
                            ? "No customer parties registered yet"
                            : "No matching customer parties found"}
                        </div>
                        <p className="text-xs text-slate-500">
                          {partiesList.length === 0
                            ? "Add your B2B customer stores and parties here to organize your customer directory across territories."
                            : "Try adjusting your search query or territory filter."}
                        </p>
                      </div>
                      {partiesList.length === 0 && (
                        <button
                          onClick={() => setIsAddModalOpen(true)}
                          className="mt-2 inline-flex items-center gap-1.5 px-3.5 py-2 bg-blue-600 text-white hover:bg-blue-500 rounded-xl text-xs font-semibold transition shadow-sm"
                        >
                          <Plus className="w-3.5 h-3.5" />
                          Add First Party / Customer
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ) : (
                filteredParties.map((p) => (
                  <tr key={p.id} className="hover:bg-slate-50/80 transition">
                    <td className="py-3.5 px-4">
                      <div className="flex items-center gap-2.5">
                        <div className="w-8 h-8 rounded-lg bg-blue-50 border border-blue-100 text-blue-600 font-bold flex items-center justify-center text-xs shrink-0">
                          {p.name.charAt(0).toUpperCase()}
                        </div>
                        <div>
                          <div className="font-bold text-slate-900">{p.name}</div>
                          {p.createdAt && (
                            <div className="text-[10px] text-slate-400">
                              Added {new Date(p.createdAt).toLocaleDateString()}
                            </div>
                          )}
                        </div>
                      </div>
                    </td>
                    <td className="py-3.5 px-4 text-slate-700 font-medium">
                      {p.ownerName}
                    </td>
                    <td className="py-3.5 px-4 text-slate-600">
                      <span className="inline-flex items-center gap-1.5">
                        <Phone className="w-3.5 h-3.5 text-slate-400" />
                        {p.phone}
                      </span>
                    </td>
                    <td className="py-3.5 px-4">
                      <span className="inline-flex items-center gap-1 text-[11px] font-semibold px-2.5 py-0.5 rounded-full bg-slate-100 text-slate-700">
                        <MapPin className="w-3 h-3 text-slate-500" />
                        {p.territory}
                      </span>
                    </td>
                    <td className="py-3.5 px-4 text-center">
                      <span className="inline-flex items-center gap-1 text-[11px] font-semibold px-2.5 py-0.5 rounded-full bg-blue-50 text-blue-700 border border-blue-200/60">
                        <ShoppingBag className="w-3 h-3" />
                        {p.ordersCount} {p.ordersCount === 1 ? "Order" : "Orders"}
                      </span>
                    </td>
                    <td className="py-3.5 px-4 text-right font-bold text-slate-900">
                      Rs. {p.totalOrderValue.toLocaleString()}
                    </td>
                    <td className="py-3.5 px-4 text-right">
                      {!p.isFromOrdersOnly ? (
                        <button
                          onClick={() => handleDeleteParty(p)}
                          title="Remove Customer Party"
                          className="p-1.5 rounded-lg text-slate-400 hover:text-rose-600 hover:bg-rose-50 transition"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      ) : (
                        <span className="text-[11px] text-slate-400 italic">
                          Synced from Orders
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

      {/* Add Party / Customer Modal */}
      {isAddModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/50 backdrop-blur-sm p-4">
          <div className="bg-white rounded-2xl border border-slate-200 shadow-2xl w-full max-w-md overflow-hidden">
            <div className="flex items-center justify-between px-5 py-4 border-b border-slate-100">
              <div className="flex items-center gap-2.5">
                <div className="p-2 rounded-xl bg-blue-50 text-blue-600">
                  <Store className="w-4 h-4" />
                </div>
                <div>
                  <h3 className="text-sm font-bold text-slate-900">
                    Add New Party / Customer
                  </h3>
                  <p className="text-[11px] text-slate-500">
                    Register a B2B customer store or business account
                  </p>
                </div>
              </div>
              <button
                onClick={() => setIsAddModalOpen(false)}
                className="p-1.5 rounded-lg text-slate-400 hover:text-slate-600 hover:bg-slate-100"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <form onSubmit={handleAddParty} className="p-5 space-y-4">
              {formError && (
                <div className="p-3 rounded-xl bg-rose-50 border border-rose-200 text-rose-700 text-xs font-medium">
                  {formError}
                </div>
              )}

              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">
                  Party / Customer Business Name *
                </label>
                <input
                  type="text"
                  required
                  autoFocus
                  value={partyName}
                  onChange={(e) => setPartyName(e.target.value)}
                  placeholder="e.g. Al-Madina Cash & Carry"
                  className="w-full px-3.5 py-2 text-xs bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 text-slate-900"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">
                  Proprietor / Contact Person
                </label>
                <input
                  type="text"
                  value={ownerName}
                  onChange={(e) => setOwnerName(e.target.value)}
                  placeholder="e.g. Haji Tariq Mehmood"
                  className="w-full px-3.5 py-2 text-xs bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 text-slate-900"
                />
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">
                    Phone Number
                  </label>
                  <input
                    type="text"
                    value={phone}
                    onChange={(e) => setPhone(e.target.value)}
                    placeholder="+92 300 1234567"
                    className="w-full px-3.5 py-2 text-xs bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 text-slate-900"
                  />
                </div>

                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">
                    Territory / Zone
                  </label>
                  <input
                    type="text"
                    value={territory}
                    onChange={(e) => setTerritory(e.target.value)}
                    placeholder="e.g. Lahore East"
                    list="party-territory-suggestions"
                    className="w-full px-3.5 py-2 text-xs bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 text-slate-900"
                  />
                  <datalist id="party-territory-suggestions">
                    {territories.map((t) => (
                      <option key={t} value={t} />
                    ))}
                  </datalist>
                </div>
              </div>

              <div className="flex items-center justify-end gap-2 pt-3 border-t border-slate-100">
                <button
                  type="button"
                  onClick={() => setIsAddModalOpen(false)}
                  className="px-4 py-2 rounded-xl text-xs font-semibold text-slate-600 hover:bg-slate-100 transition"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="inline-flex items-center gap-1.5 px-4 py-2 rounded-xl text-xs font-bold bg-blue-600 hover:bg-blue-500 text-white shadow-md shadow-blue-600/20 disabled:opacity-50 transition"
                >
                  {isSubmitting ? (
                    <>
                      <Loader2 className="w-3.5 h-3.5 animate-spin" />
                      <span>Saving...</span>
                    </>
                  ) : (
                    <>
                      <Plus className="w-3.5 h-3.5" />
                      <span>Save Customer</span>
                    </>
                  )}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}

