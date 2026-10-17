"use client";

import React, { useState, useMemo, useEffect, useCallback } from "react";
import {
  useReactTable,
  getCoreRowModel,
  flexRender,
  ColumnDef,
} from "@tanstack/react-table";
import {
  Search,
  Download,
  Eye,
  ShieldAlert,
  Loader2,
  ChevronLeft,
  ChevronRight,
  RefreshCw,
  Package,
  Calendar,
  Store,
  X,
} from "lucide-react";
import { useUser } from "@stackframe/stack";
import { useTenant } from "@/context/TenantContext";
import {
  LedgerEntry,
  LedgerCategory,
  AggregatedItemSummary,
} from "@/lib/ledger/service";
import { FilterPeriodMode } from "./TodaySummaryCards";

interface ExcelLedgerTableProps {
  categories: LedgerCategory[];
  refreshTrigger: number;
  filterMode: FilterPeriodMode;
  selectedDate: string;
  selectedMonth: number;
  selectedYear: number;
  onRefreshNeeded: () => void;
  onSelectEntryForDetails: (entry: LedgerEntry) => void;
  onSelectEntryForVoid: (entry: LedgerEntry) => void;
}

interface FilteredTotals {
  totalIncomeMinor: number;
  totalExpenseMinor: number;
  totalCostMinor: number;
  totalQuantity: number;
  activeCount: number;
  netMinor: number;
}

const MONTH_NAMES = [
  "January",
  "February",
  "March",
  "April",
  "May",
  "June",
  "July",
  "August",
  "September",
  "October",
  "November",
  "December",
];

export function ExcelLedgerTable({
  categories,
  refreshTrigger,
  filterMode,
  selectedDate,
  selectedMonth,
  selectedYear,
  onSelectEntryForDetails,
  onSelectEntryForVoid,
}: ExcelLedgerTableProps) {
  const user = useUser();
  const { activeTenant } = useTenant();

  const [entries, setEntries] = useState<LedgerEntry[]>([]);
  const [itemsBreakdown, setItemsBreakdown] = useState<AggregatedItemSummary[]>([]);
  const [totalCount, setTotalCount] = useState(0);
  const [filteredTotals, setFilteredTotals] = useState<FilteredTotals>({
    totalIncomeMinor: 0,
    totalExpenseMinor: 0,
    totalCostMinor: 0,
    totalQuantity: 0,
    activeCount: 0,
    netMinor: 0,
  });
  const [isLoading, setIsLoading] = useState(true);
  const [isExporting, setIsExporting] = useState(false);

  // Additional Table Filters
  const [search, setSearch] = useState("");
  const [debouncedSearch, setDebouncedSearch] = useState("");
  const [categoryIdFilter, setCategoryIdFilter] = useState<string>("all");
  const [includeVoided, setIncludeVoided] = useState(false);
  const [showRunningTotal, setShowRunningTotal] = useState(true);
  const [pageIndex, setPageIndex] = useState(0);
  const [pageSize, setPageSize] = useState(50);
  const [sortOrder, setSortOrder] = useState<string>("occurred_at:desc");

  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedSearch(search);
      setPageIndex(0);
    }, 250);
    return () => clearTimeout(timer);
  }, [search]);

  // Reset pagination when period filter changes
  useEffect(() => {
    setPageIndex(0);
  }, [filterMode, selectedDate, selectedMonth, selectedYear]);

  const formatCurrency = (minor: number) => {
    return new Intl.NumberFormat("en-PK", {
      style: "currency",
      currency: "PKR",
      maximumFractionDigits: 2,
    }).format((minor || 0) / 100);
  };

  const buildFilterQueryParams = useCallback(() => {
    const params = new URLSearchParams();
    params.set("limit", pageSize.toString());
    params.set("offset", (pageIndex * pageSize).toString());
    params.set("sort", sortOrder);
    params.set("includeVoided", includeVoided ? "true" : "false");

    if (filterMode === "date" && selectedDate) {
      params.set("date", selectedDate);
    } else if (filterMode === "week") {
      params.set("period", "weekly");
    } else if (filterMode === "month") {
      params.set("month", String(selectedMonth));
      params.set("year", String(selectedYear));
    } else if (filterMode === "year") {
      params.set("year", String(selectedYear));
    }

    if (categoryIdFilter !== "all") {
      params.set("categoryId", categoryIdFilter);
    }
    if (debouncedSearch.trim()) {
      params.set("search", debouncedSearch.trim());
    }
    return params;
  }, [
    pageSize,
    pageIndex,
    sortOrder,
    includeVoided,
    filterMode,
    selectedDate,
    selectedMonth,
    selectedYear,
    categoryIdFilter,
    debouncedSearch,
  ]);

  const fetchEntries = useCallback(async () => {
    setIsLoading(true);
    try {
      const params = buildFilterQueryParams();
      const headers: Record<string, string> = {};
      if (activeTenant?.id) {
        headers["x-tenant-id"] = activeTenant.id;
      }
      const email = user?.primaryEmail || activeTenant?.admin_email;
      if (email) {
        headers["x-user-email"] = email;
      }
      const res = await fetch(`/api/ledger/entries?${params.toString()}`, {
        headers,
        credentials: "include",
      });
      if (!res.ok) throw new Error("Failed to fetch khata entries");
      const json = await res.json();

      const data = json.data || {};
      setEntries(data.entries || []);
      setItemsBreakdown(data.itemsBreakdown || []);
      setTotalCount(data.totalCount ?? data.pagination?.total ?? 0);
      setFilteredTotals(
        data.filteredTotals || {
          totalIncomeMinor: 0,
          totalExpenseMinor: 0,
          totalCostMinor: 0,
          totalQuantity: 0,
          activeCount: 0,
          netMinor: 0,
        }
      );
    } catch (err) {
      console.error("Error fetching entries:", err);
    } finally {
      setIsLoading(false);
    }
  }, [buildFilterQueryParams, activeTenant?.id, activeTenant?.admin_email, user?.primaryEmail]);

  useEffect(() => {
    fetchEntries();
  }, [fetchEntries, refreshTrigger]);

  // Compute running cumulative cost across visible rows
  const entriesWithRunningCost = useMemo(() => {
    let cumulativeCost = 0;
    return entries.map((entry) => {
      if (!entry.is_voided) {
        cumulativeCost += entry.amount_minor;
      }
      return {
        ...entry,
        running_cost_minor: cumulativeCost,
      };
    });
  }, [entries]);

  const handleExportCsv = () => {
    setIsExporting(true);
    try {
      const params = buildFilterQueryParams();
      if (activeTenant?.id) {
        params.set("tenantId", activeTenant.id);
      }
      window.open(`/api/ledger/export?${params.toString()}`, "_blank");
    } finally {
      setIsExporting(false);
    }
  };

  // Human-readable title for the active Date / Month / Year filter
  const periodTitle = useMemo(() => {
    if (filterMode === "date") {
      const formatted = new Date(selectedDate).toLocaleDateString("en-US", {
        weekday: "short",
        month: "short",
        day: "numeric",
        year: "numeric",
      });
      return `Items Brought on ${formatted}`;
    }
    if (filterMode === "week") {
      return "Items Brought in Last 7 Days (Weekly Khata)";
    }
    if (filterMode === "month") {
      return `Items Brought in ${MONTH_NAMES[selectedMonth - 1]} ${selectedYear}`;
    }
    if (filterMode === "year") {
      return `Items Brought in Year ${selectedYear}`;
    }
    return "All Items Brought (Complete Khata History)";
  }, [filterMode, selectedDate, selectedMonth, selectedYear]);

  const columns = useMemo<ColumnDef<LedgerEntry & { running_cost_minor: number }>[]>(
    () => [
      {
        id: "index",
        header: "#",
        size: 48,
        cell: (info) => (
          <span className="text-slate-400 font-mono text-xs font-semibold">
            {pageIndex * pageSize + info.row.index + 1}
          </span>
        ),
      },
      {
        accessorKey: "occurred_at",
        header: "Date & Time",
        size: 145,
        cell: ({ row }) => {
          const date = new Date(row.original.occurred_at);
          return (
            <div className="flex flex-col text-xs font-mono">
              <span className="text-slate-800 font-semibold">
                {date.toLocaleDateString("en-US", {
                  month: "short",
                  day: "2-digit",
                  year: "numeric",
                })}
              </span>
              <span className="text-[11px] text-slate-400">
                {date.toLocaleTimeString("en-US", {
                  hour: "2-digit",
                  minute: "2-digit",
                  hour12: true,
                })}
              </span>
            </div>
          );
        },
      },
      {
        accessorKey: "title",
        header: "Item Brought",
        cell: ({ row }) => (
          <div className="flex items-center gap-2.5 max-w-xs">
            <div className="w-7 h-7 rounded-lg bg-emerald-50 border border-emerald-200 text-emerald-700 flex items-center justify-center shrink-0">
              <Package className="w-3.5 h-3.5" />
            </div>
            <div className="flex flex-col truncate">
              <span
                className={`font-bold text-xs truncate ${
                  row.original.is_voided
                    ? "line-through text-slate-400"
                    : "text-slate-900"
                }`}
                title={row.original.title}
              >
                {row.original.title}
              </span>
              {row.original.is_voided && row.original.void_reason && (
                <span
                  className="text-[10px] text-rose-600 italic truncate"
                  title={row.original.void_reason}
                >
                  Voided: {row.original.void_reason}
                </span>
              )}
            </div>
          </div>
        ),
      },
      {
        accessorKey: "quantity",
        header: "Quantity",
        cell: ({ row }) => {
          const qty = row.original.quantity || 1;
          const unit = row.original.unit || "pcs";
          return (
            <span
              className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-lg text-xs font-mono font-bold ${
                row.original.is_voided
                  ? "bg-slate-100 text-slate-400 line-through"
                  : "bg-blue-50 text-blue-800 border border-blue-200/80"
              }`}
            >
              {qty} {unit}
            </span>
          );
        },
      },
      {
        accessorKey: "unit_cost_minor",
        header: "Unit Rate",
        cell: ({ row }) => {
          const unitCost = row.original.unit_cost_minor || row.original.amount_minor;
          const unit = row.original.unit || "pcs";
          return (
            <div className="text-right font-mono text-xs text-slate-600 tabular-nums">
              {formatCurrency(unitCost)}{" "}
              <span className="text-[10px] text-slate-400">/ {unit}</span>
            </div>
          );
        },
      },
      {
        accessorKey: "amount_minor",
        header: "Total Cost Price",
        cell: ({ row }) => (
          <div className="text-right">
            <span
              className={`font-mono text-sm font-extrabold tabular-nums ${
                row.original.is_voided
                  ? "line-through text-slate-400"
                  : "text-slate-900"
              }`}
            >
              {formatCurrency(row.original.amount_minor)}
            </span>
          </div>
        ),
      },
      ...(showRunningTotal
        ? [
            {
              id: "running_cost",
              header: "Cumulative Cost",
              cell: ({ row }: any) => (
                <div className="text-right">
                  <span className="font-mono text-xs font-semibold text-emerald-700 tabular-nums">
                    {formatCurrency(row.original.running_cost_minor)}
                  </span>
                </div>
              ),
            },
          ]
        : []),
      {
        accessorKey: "category_name",
        header: "Category",
        cell: ({ row }) => (
          <span className="inline-block px-2.5 py-0.5 rounded-full text-[11px] bg-slate-100 text-slate-700 border border-slate-200 font-semibold">
            {row.original.category_name || "Expense"}
          </span>
        ),
      },
      {
        accessorKey: "vendor_name",
        header: "Supplier & Payment",
        cell: ({ row }) => (
          <div className="flex flex-col text-xs">
            <span className="text-slate-700 font-medium truncate max-w-[130px]">
              {row.original.vendor_name || "Direct Purchase"}
            </span>
            <span className="text-[10px] text-slate-400 uppercase font-semibold">
              {row.original.payment_method || "Cash"}
            </span>
          </div>
        ),
      },
      {
        accessorKey: "added_by_name",
        header: "Added By",
        cell: ({ row }) => (
          <span className="text-xs text-slate-600 font-medium truncate max-w-[90px] block">
            {row.original.added_by_name || "Admin"}
          </span>
        ),
      },
      {
        id: "actions",
        header: "Actions",
        size: 80,
        cell: ({ row }) => (
          <div className="flex items-center gap-1 justify-end">
            <button
              onClick={() => onSelectEntryForDetails(row.original)}
              title="View Full Item Details"
              className="p-1.5 rounded-lg text-slate-500 hover:text-slate-900 hover:bg-slate-100 transition"
            >
              <Eye className="w-3.5 h-3.5" />
            </button>
            {!row.original.is_voided && (
              <button
                onClick={() => onSelectEntryForVoid(row.original)}
                title="Void Mistaken Entry"
                className="p-1.5 rounded-lg text-slate-400 hover:text-rose-600 hover:bg-rose-50 transition"
              >
                <ShieldAlert className="w-3.5 h-3.5" />
              </button>
            )}
          </div>
        ),
      },
    ],
    [
      pageIndex,
      pageSize,
      showRunningTotal,
      onSelectEntryForDetails,
      onSelectEntryForVoid,
    ]
  );

  const table = useReactTable({
    data: entriesWithRunningCost,
    columns,
    getCoreRowModel: getCoreRowModel(),
  });

  const totalPages = Math.ceil(totalCount / pageSize);

  return (
    <div className="space-y-4">
      {/* 1. Aggregated Summary of All Items Brought in Selected Day / Month / Year */}
      <div className="bg-white border border-slate-200 rounded-2xl p-5 shadow-sm space-y-4">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-3 border-b border-slate-100">
          <div>
            <div className="flex items-center gap-2">
              <Calendar className="w-4 h-4 text-emerald-600" />
              <h3 className="text-base font-extrabold text-slate-900">
                {periodTitle}
              </h3>
            </div>
            <p className="text-xs text-slate-500 mt-0.5">
              Summary of all items brought to the hotel/business and total cost price for this period
            </p>
          </div>

          {/* Total Cost Highlight Pill for Selected Filter */}
          <div className="flex flex-wrap items-center gap-3 bg-emerald-50 border border-emerald-200 px-4 py-2.5 rounded-xl">
            <div>
              <span className="text-[10px] font-bold uppercase tracking-wider text-emerald-700 block">
                Total Period Cost
              </span>
              <span className="text-lg font-extrabold font-mono text-emerald-950">
                {formatCurrency(filteredTotals.totalCostMinor)}
              </span>
            </div>
            <div className="h-7 w-px bg-emerald-200" />
            <div>
              <span className="text-[10px] font-bold uppercase tracking-wider text-emerald-700 block">
                Items Brought
              </span>
              <span className="text-sm font-bold font-mono text-emerald-900">
                {filteredTotals.activeCount} entries ({filteredTotals.totalQuantity} units)
              </span>
            </div>
          </div>
        </div>

        {/* Grouped Items Breakdown Pills */}
        {itemsBreakdown.length > 0 ? (
          <div>
            <div className="flex items-center justify-between mb-2">
              <span className="text-[11px] font-bold text-slate-500 uppercase tracking-wider">
                All Items Brought in Selected Period (Click an item to filter rows):
              </span>
              {search && (
                <button
                  type="button"
                  onClick={() => setSearch("")}
                  className="text-xs font-semibold text-rose-600 hover:text-rose-700 flex items-center gap-1"
                >
                  <X className="w-3.5 h-3.5" />
                  Clear Item Filter ("{search}")
                </button>
              )}
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-2.5">
              {itemsBreakdown.map((item, i) => {
                const isSelected =
                  search.trim().toLowerCase() === item.itemName.toLowerCase();
                return (
                  <button
                    key={`${item.itemName}-${item.unit}-${i}`}
                    type="button"
                    onClick={() =>
                      setSearch(isSelected ? "" : item.itemName)
                    }
                    className={`text-left p-3 rounded-xl border transition-all flex items-center justify-between gap-2 ${
                      isSelected
                        ? "bg-emerald-50 border-emerald-500 ring-2 ring-emerald-500/20"
                        : "bg-slate-50/70 hover:bg-slate-100/80 border-slate-200/80"
                    }`}
                  >
                    <div className="min-w-0">
                      <div className="font-bold text-xs text-slate-900 truncate">
                        {item.itemName}
                      </div>
                      <div className="text-[11px] text-slate-500 font-mono mt-0.5">
                        <strong className="text-blue-700">
                          {item.totalQuantity} {item.unit}
                        </strong>{" "}
                        • {item.purchaseCount}x bought
                      </div>
                    </div>
                    <div className="text-right shrink-0">
                      <div className="font-mono font-extrabold text-xs text-slate-900">
                        {formatCurrency(item.totalCostMinor)}
                      </div>
                      <div className="text-[10px] font-mono text-slate-400">
                        ~{formatCurrency(item.avgUnitCostMinor)}/{item.unit}
                      </div>
                    </div>
                  </button>
                );
              })}
            </div>
          </div>
        ) : (
          !isLoading && (
            <div className="text-xs text-slate-500 italic py-2">
              No items recorded for this period yet. Click &ldquo;+ Add Item Brought&rdquo; above to log items like 100 Chicken with its cost price.
            </div>
          )
        )}
      </div>

      {/* 2. Excel-Style Ledger Table */}
      <div className="bg-white border border-slate-200 rounded-2xl overflow-hidden shadow-sm flex flex-col">
        {/* Table Toolbar */}
        <div className="p-4 border-b border-slate-200 bg-slate-50/60 flex flex-wrap items-center justify-between gap-3">
          {/* Search Input */}
          <div className="relative min-w-[240px] flex-1 max-w-sm">
            <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search item name (e.g. Chicken), category, supplier..."
              className="w-full pl-9 pr-3 py-2 bg-white border border-slate-200 rounded-xl text-xs text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-600"
            />
          </div>

          {/* Category, Sort & Export */}
          <div className="flex flex-wrap items-center gap-2.5 text-xs">
            <select
              value={categoryIdFilter}
              onChange={(e) => {
                setCategoryIdFilter(e.target.value);
                setPageIndex(0);
              }}
              className="px-3 py-2 bg-white border border-slate-200 rounded-xl text-xs font-semibold text-slate-700 focus:outline-none focus:border-emerald-600"
            >
              <option value="all">All Categories</option>
              {categories.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
            </select>

            <select
              value={sortOrder}
              onChange={(e) => setSortOrder(e.target.value)}
              className="px-3 py-2 bg-white border border-slate-200 rounded-xl text-xs font-semibold text-slate-700 focus:outline-none focus:border-emerald-600"
            >
              <option value="occurred_at:desc">Newest First</option>
              <option value="occurred_at:asc">Oldest First</option>
              <option value="amount_minor:desc">Highest Cost First</option>
              <option value="amount_minor:asc">Lowest Cost First</option>
            </select>

            <label className="flex items-center gap-1.5 cursor-pointer select-none text-slate-600 font-medium px-2">
              <input
                type="checkbox"
                checked={showRunningTotal}
                onChange={(e) => setShowRunningTotal(e.target.checked)}
                className="w-3.5 h-3.5 rounded border-slate-300 text-emerald-600 focus:ring-emerald-500"
              />
              <span>Cumulative Col</span>
            </label>

            <label className="flex items-center gap-1.5 cursor-pointer select-none text-slate-600 font-medium px-2">
              <input
                type="checkbox"
                checked={includeVoided}
                onChange={(e) => setIncludeVoided(e.target.checked)}
                className="w-3.5 h-3.5 rounded border-slate-300 text-emerald-600 focus:ring-emerald-500"
              />
              <span>Show Voided</span>
            </label>

            <button
              onClick={handleExportCsv}
              disabled={isExporting}
              className="flex items-center gap-1.5 px-3.5 py-2 bg-white hover:bg-slate-50 border border-slate-200 text-slate-700 rounded-xl text-xs font-bold shadow-sm transition"
              title="Export filtered items to Excel CSV"
            >
              {isExporting ? (
                <Loader2 className="w-3.5 h-3.5 animate-spin" />
              ) : (
                <Download className="w-3.5 h-3.5 text-emerald-600" />
              )}
              <span>Export Excel CSV</span>
            </button>

            <button
              onClick={fetchEntries}
              disabled={isLoading}
              className="p-2 bg-white hover:bg-slate-50 border border-slate-200 text-slate-600 rounded-xl transition"
              title="Refresh table"
            >
              <RefreshCw className={`w-3.5 h-3.5 ${isLoading ? "animate-spin" : ""}`} />
            </button>
          </div>
        </div>

        {/* Excel Spreadsheet Grid */}
        <div className="relative overflow-x-auto max-h-[580px]">
          <table className="w-full text-left border-collapse text-xs">
            <thead className="sticky top-0 z-10 bg-slate-100 border-b border-slate-200 text-slate-600 uppercase tracking-wider text-[11px] font-bold select-none">
              {table.getHeaderGroups().map((headerGroup) => (
                <tr key={headerGroup.id}>
                  {headerGroup.headers.map((header) => (
                    <th
                      key={header.id}
                      className={`px-3.5 py-3 border-r border-slate-200/60 last:border-r-0 ${
                        header.id === "amount_minor" ||
                        header.id === "unit_cost_minor" ||
                        header.id === "running_cost"
                          ? "text-right"
                          : "text-left"
                      }`}
                    >
                      {flexRender(
                        header.column.columnDef.header,
                        header.getContext()
                      )}
                    </th>
                  ))}
                </tr>
              ))}
            </thead>

            <tbody className="divide-y divide-slate-200/70">
              {isLoading ? (
                <tr>
                  <td
                    colSpan={columns.length}
                    className="py-16 text-center text-slate-500"
                  >
                    <div className="flex flex-col items-center justify-center gap-2">
                      <Loader2 className="w-6 h-6 animate-spin text-emerald-600" />
                      <span className="font-medium">Loading khata items...</span>
                    </div>
                  </td>
                </tr>
              ) : entries.length === 0 ? (
                <tr>
                  <td
                    colSpan={columns.length}
                    className="py-16 text-center text-slate-500"
                  >
                    <div className="max-w-sm mx-auto space-y-1">
                      <p className="font-bold text-slate-700 text-sm">
                        No items found for this selection
                      </p>
                      <p className="text-xs text-slate-400">
                        Add an item (for example: 100 Chicken with its cost price) or switch the Date / Month / Year filter above.
                      </p>
                    </div>
                  </td>
                </tr>
              ) : (
                table.getRowModel().rows.map((row, idx) => (
                  <tr
                    key={row.id}
                    className={`transition-colors hover:bg-emerald-50/40 ${
                      idx % 2 === 0 ? "bg-white" : "bg-slate-50/50"
                    } ${row.original.is_voided ? "opacity-50 bg-rose-50/20" : ""}`}
                  >
                    {row.getVisibleCells().map((cell) => (
                      <td
                        key={cell.id}
                        className={`px-3.5 py-2.5 whitespace-nowrap border-r border-slate-100 last:border-r-0 ${
                          cell.column.id === "amount_minor" ||
                          cell.column.id === "unit_cost_minor" ||
                          cell.column.id === "running_cost"
                            ? "text-right"
                            : "text-left"
                        }`}
                      >
                        {flexRender(
                          cell.column.columnDef.cell,
                          cell.getContext()
                        )}
                      </td>
                    ))}
                  </tr>
                ))
              )}
            </tbody>

            {/* Sticky Excel Footer Summary Row */}
            {!isLoading && entries.length > 0 && (
              <tfoot className="sticky bottom-0 z-10 bg-slate-900 text-white border-t-2 border-slate-800 text-xs font-bold">
                <tr>
                  <td colSpan={3} className="px-3.5 py-3 uppercase tracking-wider text-slate-300">
                    Total for Selected Period ({filteredTotals.activeCount} active items)
                  </td>
                  <td className="px-3.5 py-3 font-mono text-blue-300">
                    Total Qty: {filteredTotals.totalQuantity}
                  </td>
                  <td className="px-3.5 py-3 text-right text-slate-400">
                    Grand Total Cost:
                  </td>
                  <td className="px-3.5 py-3 text-right font-mono text-sm font-extrabold text-emerald-400 tabular-nums">
                    {formatCurrency(filteredTotals.totalCostMinor)}
                  </td>
                  <td colSpan={showRunningTotal ? 5 : 4} className="px-3.5 py-3" />
                </tr>
              </tfoot>
            )}
          </table>
        </div>

        {/* Pagination Footer */}
        <div className="flex flex-wrap items-center justify-between gap-3 p-3 px-4 border-t border-slate-200 bg-slate-50 text-xs text-slate-600">
          <div className="flex items-center gap-2">
            <span>Rows per page:</span>
            <select
              value={pageSize}
              onChange={(e) => {
                setPageSize(Number(e.target.value));
                setPageIndex(0);
              }}
              className="px-2 py-1 bg-white border border-slate-200 rounded-lg text-xs text-slate-800 font-semibold focus:outline-none"
            >
              {[25, 50, 100].map((size) => (
                <option key={size} value={size}>
                  {size}
                </option>
              ))}
            </select>
            <span className="text-slate-500">
              Showing {entries.length > 0 ? pageIndex * pageSize + 1 : 0} –{" "}
              {Math.min((pageIndex + 1) * pageSize, totalCount)} of {totalCount}
            </span>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={() => setPageIndex((p) => Math.max(0, p - 1))}
              disabled={pageIndex === 0 || isLoading}
              className="p-1.5 rounded-lg border border-slate-200 bg-white hover:bg-slate-100 disabled:opacity-40 disabled:cursor-not-allowed text-slate-700 transition"
            >
              <ChevronLeft className="w-4 h-4" />
            </button>
            <span className="font-mono font-semibold text-slate-700">
              Page {pageIndex + 1} of {Math.max(1, totalPages)}
            </span>
            <button
              onClick={() => setPageIndex((p) => p + 1)}
              disabled={pageIndex + 1 >= totalPages || isLoading}
              className="p-1.5 rounded-lg border border-slate-200 bg-white hover:bg-slate-100 disabled:opacity-40 disabled:cursor-not-allowed text-slate-700 transition"
            >
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
