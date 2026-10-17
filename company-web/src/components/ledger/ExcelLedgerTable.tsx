"use client";

import React, { useState, useMemo, useEffect, useCallback } from "react";
import {
  useReactTable,
  getCoreRowModel,
  flexRender,
  ColumnDef,
  SortingState,
} from "@tanstack/react-table";
import {
  Search,
  Filter,
  Download,
  ArrowUpDown,
  ArrowUp,
  ArrowDown,
  Eye,
  ShieldAlert,
  Loader2,
  Calendar,
  Layers,
  ChevronLeft,
  ChevronRight,
  TrendingUp,
  TrendingDown,
  RefreshCw,
} from "lucide-react";
import { LedgerEntry, LedgerCategory } from "@/lib/ledger/service";

interface ExcelLedgerTableProps {
  categories: LedgerCategory[];
  refreshTrigger: number;
  onRefreshNeeded: () => void;
  onSelectEntryForDetails: (entry: LedgerEntry) => void;
  onSelectEntryForVoid: (entry: LedgerEntry) => void;
}

interface FilteredTotals {
  totalIncomeMinor: number;
  totalExpenseMinor: number;
  netMinor: number;
}

export function ExcelLedgerTable({
  categories,
  refreshTrigger,
  onRefreshNeeded,
  onSelectEntryForDetails,
  onSelectEntryForVoid,
}: ExcelLedgerTableProps) {
  // Data state
  const [entries, setEntries] = useState<LedgerEntry[]>([]);
  const [totalCount, setTotalCount] = useState(0);
  const [filteredTotals, setFilteredTotals] = useState<FilteredTotals>({
    totalIncomeMinor: 0,
    totalExpenseMinor: 0,
    netMinor: 0,
  });
  const [isLoading, setIsLoading] = useState(true);
  const [isExporting, setIsExporting] = useState(false);

  // Filters & Pagination state
  const [search, setSearch] = useState("");
  const [debouncedSearch, setDebouncedSearch] = useState("");
  const [typeFilter, setTypeFilter] = useState<"all" | "income" | "expense">("all");
  const [categoryIdFilter, setCategoryIdFilter] = useState<string>("all");
  const [fromDate, setFromDate] = useState("");
  const [toDate, setToDate] = useState("");
  const [includeVoided, setIncludeVoided] = useState(true);
  const [showRunningBalance, setShowRunningBalance] = useState(true);
  const [pageIndex, setPageIndex] = useState(0);
  const [pageSize, setPageSize] = useState(50);
  const [sortOrder, setSortOrder] = useState<"desc" | "asc">("desc");

  // Debounce search input
  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedSearch(search);
      setPageIndex(0);
    }, 300);
    return () => clearTimeout(timer);
  }, [search]);

  // Currency Formatter
  const formatCurrency = (minor: number) => {
    return new Intl.NumberFormat("en-PK", {
      style: "currency",
      currency: "PKR",
      maximumFractionDigits: 2,
    }).format(minor / 100);
  };

  // Fetch entries from server API
  const fetchEntries = useCallback(async () => {
    setIsLoading(true);
    try {
      const params = new URLSearchParams();
      params.set("limit", pageSize.toString());
      params.set("offset", (pageIndex * pageSize).toString());
      params.set("sort", sortOrder);
      if (typeFilter !== "all") params.set("type", typeFilter);
      if (categoryIdFilter !== "all") params.set("categoryId", categoryIdFilter);
      if (debouncedSearch.trim()) params.set("search", debouncedSearch.trim());
      if (fromDate) params.set("from", new Date(fromDate).toISOString());
      if (toDate) {
        // End of the day
        const endDay = new Date(toDate);
        endDay.setHours(23, 59, 59, 999);
        params.set("to", endDay.toISOString());
      }
      if (includeVoided) params.set("includeVoided", "true");

      const res = await fetch(`/api/ledger/entries?${params.toString()}`);
      if (!res.ok) throw new Error("Failed to fetch ledger entries");
      const json = await res.json();

      setEntries(json.data.entries || []);
      setTotalCount(json.data.totalCount || 0);
      setFilteredTotals(
        json.data.filteredTotals || {
          totalIncomeMinor: 0,
          totalExpenseMinor: 0,
          netMinor: 0,
        }
      );
    } catch (err) {
      console.error("Error fetching entries:", err);
    } finally {
      setIsLoading(false);
    }
  }, [
    pageIndex,
    pageSize,
    sortOrder,
    typeFilter,
    categoryIdFilter,
    debouncedSearch,
    fromDate,
    toDate,
    includeVoided,
  ]);

  useEffect(() => {
    fetchEntries();
  }, [fetchEntries, refreshTrigger]);

  // Compute running balance for displayed entries
  const entriesWithRunningBalance = useMemo(() => {
    let balance = 0;
    // Calculate running balance forward
    return entries.map((entry) => {
      if (!entry.is_voided) {
        if (entry.type === "income") {
          balance += entry.amount_minor;
        } else {
          balance -= entry.amount_minor;
        }
      }
      return {
        ...entry,
        running_balance_minor: balance,
      };
    });
  }, [entries]);

  // Export to CSV
  const handleExportCsv = async () => {
    setIsExporting(true);
    try {
      const params = new URLSearchParams();
      if (typeFilter !== "all") params.set("type", typeFilter);
      if (categoryIdFilter !== "all") params.set("categoryId", categoryIdFilter);
      if (debouncedSearch.trim()) params.set("search", debouncedSearch.trim());
      if (fromDate) params.set("from", new Date(fromDate).toISOString());
      if (toDate) {
        const endDay = new Date(toDate);
        endDay.setHours(23, 59, 59, 999);
        params.set("to", endDay.toISOString());
      }
      if (includeVoided) params.set("includeVoided", "true");

      // Trigger browser download
      window.open(`/api/ledger/export?${params.toString()}`, "_blank");
    } catch (err) {
      console.error("Export error:", err);
    } finally {
      setIsExporting(false);
    }
  };

  // Table Columns Definition
  const columns = useMemo<ColumnDef<LedgerEntry & { running_balance_minor: number }>[]>(
    () => [
      {
        id: "index",
        header: "#",
        size: 50,
        cell: (info) => (
          <span className="text-slate-500 font-mono text-xs">
            {pageIndex * pageSize + info.row.index + 1}
          </span>
        ),
      },
      {
        accessorKey: "occurred_at",
        header: "Date & Time",
        size: 160,
        cell: ({ row }) => {
          const date = new Date(row.original.occurred_at);
          return (
            <div className="flex flex-col text-xs font-mono">
              <span className="text-slate-200">
                {date.toLocaleDateString("en-US", { month: "short", day: "2-digit", year: "numeric" })}
              </span>
              <span className="text-[11px] text-slate-500">
                {date.toLocaleTimeString("en-US", { hour: "2-digit", minute: "2-digit", hour12: true })}
              </span>
            </div>
          );
        },
      },
      {
        accessorKey: "title",
        header: "Title / Description",
        cell: ({ row }) => (
          <div className="flex flex-col max-w-xs truncate">
            <span
              className={`font-medium truncate ${
                row.original.is_voided
                  ? "line-through text-slate-500"
                  : "text-slate-200"
              }`}
              title={row.original.title}
            >
              {row.original.title}
            </span>
            {row.original.is_voided && row.original.void_reason && (
              <span className="text-[10px] text-red-400 italic truncate" title={row.original.void_reason}>
                Voided: {row.original.void_reason}
              </span>
            )}
          </div>
        ),
      },
      {
        accessorKey: "category_name",
        header: "Category",
        cell: ({ row }) => (
          <span className="inline-block px-2 py-0.5 rounded text-xs bg-slate-800 text-slate-300 border border-slate-700/60 font-medium">
            {row.original.category_name}
          </span>
        ),
      },
      {
        accessorKey: "type",
        header: "Type",
        cell: ({ row }) => {
          const isIncome = row.original.type === "income";
          return (
            <span
              className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-semibold uppercase tracking-wider ${
                isIncome
                  ? "bg-emerald-500/10 text-emerald-400 border border-emerald-500/20"
                  : "bg-rose-500/10 text-rose-400 border border-rose-500/20"
              }`}
            >
              {isIncome ? <TrendingUp className="w-3 h-3" /> : <TrendingDown className="w-3 h-3" />}
              {row.original.type}
            </span>
          );
        },
      },
      {
        accessorKey: "payment_method",
        header: "Payment",
        cell: ({ row }) => (
          <span className="text-xs text-slate-400 capitalize">
            {row.original.payment_method || "Other"}
          </span>
        ),
      },
      {
        accessorKey: "amount_minor",
        header: "Amount",
        cell: ({ row }) => {
          const isIncome = row.original.type === "income";
          return (
            <div className="text-right">
              <span
                className={`font-mono text-sm font-semibold tabular-nums ${
                  row.original.is_voided
                    ? "line-through text-slate-500"
                    : isIncome
                    ? "text-emerald-400"
                    : "text-rose-400"
                }`}
              >
                {isIncome ? "+" : "-"}
                {formatCurrency(row.original.amount_minor)}
              </span>
            </div>
          );
        },
      },
      ...(showRunningBalance
        ? [
            {
              id: "running_balance",
              header: "Running Bal.",
              cell: ({ row }: any) => {
                const bal = row.original.running_balance_minor;
                return (
                  <div className="text-right">
                    <span
                      className={`font-mono text-xs tabular-nums ${
                        bal >= 0 ? "text-slate-300" : "text-amber-400"
                      }`}
                    >
                      {formatCurrency(bal)}
                    </span>
                  </div>
                );
              },
            },
          ]
        : []),
      {
        accessorKey: "added_by_name",
        header: "Added By",
        cell: ({ row }) => (
          <span className="text-xs text-slate-400 truncate max-w-[100px] block" title={row.original.added_by_name || "Admin"}>
            {row.original.added_by_name || "Admin"}
          </span>
        ),
      },
      {
        accessorKey: "is_voided",
        header: "Status",
        cell: ({ row }) => (
          <span
            className={`inline-block px-2 py-0.5 rounded text-[10px] font-semibold uppercase tracking-wider ${
              row.original.is_voided
                ? "bg-red-500/10 text-red-400 border border-red-500/20"
                : "bg-emerald-500/10 text-emerald-400 border border-emerald-500/20"
            }`}
          >
            {row.original.is_voided ? "Voided" : "Active"}
          </span>
        ),
      },
      {
        id: "actions",
        header: "Actions",
        size: 90,
        cell: ({ row }) => (
          <div className="flex items-center gap-1 justify-end">
            <button
              onClick={() => onSelectEntryForDetails(row.original)}
              title="View Entry Details"
              className="p-1 rounded text-slate-400 hover:text-slate-200 hover:bg-slate-800 transition"
            >
              <Eye className="w-3.5 h-3.5" />
            </button>
            {!row.original.is_voided && (
              <button
                onClick={() => onSelectEntryForVoid(row.original)}
                title="Void Entry"
                className="p-1 rounded text-slate-400 hover:text-red-400 hover:bg-red-500/10 transition"
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
      showRunningBalance,
      onSelectEntryForDetails,
      onSelectEntryForVoid,
    ]
  );

  const table = useReactTable({
    data: entriesWithRunningBalance,
    columns,
    getCoreRowModel: getCoreRowModel(),
  });

  const totalPages = Math.ceil(totalCount / pageSize);

  return (
    <div className="bg-slate-900 border border-slate-800 rounded-xl overflow-hidden shadow-xl flex flex-col">
      {/* Table Toolbar / Filters */}
      <div className="p-4 border-b border-slate-800 space-y-3 bg-slate-950/40">
        <div className="flex flex-wrap items-center justify-between gap-3">
          {/* Search Box */}
          <div className="relative min-w-[240px] flex-1 max-w-sm">
            <Search className="w-4 h-4 text-slate-500 absolute left-3 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search by title or description..."
              className="w-full pl-9 pr-3 py-1.5 bg-slate-900 border border-slate-700/80 rounded-lg text-xs text-slate-100 placeholder-slate-500 focus:outline-none focus:ring-1 focus:ring-emerald-500"
            />
          </div>

          {/* Quick Actions & CSV Export */}
          <div className="flex items-center gap-2">
            <button
              onClick={handleExportCsv}
              disabled={isExporting}
              className="flex items-center gap-1.5 px-3 py-1.5 bg-slate-800 hover:bg-slate-700 active:bg-slate-800 border border-slate-700 text-slate-200 rounded-lg text-xs font-semibold transition"
              title="Download UTF-8 BOM CSV compatible with Excel"
            >
              {isExporting ? (
                <Loader2 className="w-3.5 h-3.5 animate-spin" />
              ) : (
                <Download className="w-3.5 h-3.5 text-emerald-400" />
              )}
              <span>Export CSV</span>
            </button>

            <button
              onClick={fetchEntries}
              disabled={isLoading}
              className="p-1.5 bg-slate-800 hover:bg-slate-700 border border-slate-700 text-slate-300 rounded-lg text-xs transition"
              title="Refresh table"
            >
              <RefreshCw className={`w-3.5 h-3.5 ${isLoading ? "animate-spin" : ""}`} />
            </button>
          </div>
        </div>

        {/* Filter Pills / Selectors */}
        <div className="flex flex-wrap items-center gap-3 text-xs pt-1">
          {/* Type Filter */}
          <div className="flex items-center gap-1 bg-slate-900 p-0.5 rounded-lg border border-slate-800">
            {(["all", "income", "expense"] as const).map((t) => (
              <button
                key={t}
                onClick={() => {
                  setTypeFilter(t);
                  setPageIndex(0);
                }}
                className={`px-2.5 py-1 rounded capitalize font-medium transition ${
                  typeFilter === t
                    ? "bg-slate-800 text-white shadow-sm"
                    : "text-slate-400 hover:text-slate-200"
                }`}
              >
                {t}
              </button>
            ))}
          </div>

          {/* Category Filter */}
          <select
            value={categoryIdFilter}
            onChange={(e) => {
              setCategoryIdFilter(e.target.value);
              setPageIndex(0);
            }}
            className="px-2.5 py-1 bg-slate-900 border border-slate-800 rounded-lg text-xs text-slate-200 focus:outline-none focus:ring-1 focus:ring-emerald-500"
          >
            <option value="all">All Categories</option>
            {categories.map((c) => (
              <option key={c.id} value={c.id}>
                {c.name} ({c.type})
              </option>
            ))}
          </select>

          {/* Date Range */}
          <div className="flex items-center gap-1.5">
            <span className="text-slate-500">From:</span>
            <input
              type="date"
              value={fromDate}
              onChange={(e) => {
                setFromDate(e.target.value);
                setPageIndex(0);
              }}
              className="px-2 py-1 bg-slate-900 border border-slate-800 rounded-lg text-xs font-mono text-slate-200"
            />
            <span className="text-slate-500">To:</span>
            <input
              type="date"
              value={toDate}
              onChange={(e) => {
                setToDate(e.target.value);
                setPageIndex(0);
              }}
              className="px-2 py-1 bg-slate-900 border border-slate-800 rounded-lg text-xs font-mono text-slate-200"
            />
          </div>

          {/* Toggles */}
          <div className="flex items-center gap-4 ml-auto">
            <label className="flex items-center gap-1.5 cursor-pointer select-none text-slate-300">
              <input
                type="checkbox"
                checked={includeVoided}
                onChange={(e) => setIncludeVoided(e.target.checked)}
                className="w-3.5 h-3.5 rounded bg-slate-950 border-slate-700 text-emerald-500 focus:ring-emerald-500"
              />
              <span>Show Voided</span>
            </label>

            <label className="flex items-center gap-1.5 cursor-pointer select-none text-slate-300">
              <input
                type="checkbox"
                checked={showRunningBalance}
                onChange={(e) => setShowRunningBalance(e.target.checked)}
                className="w-3.5 h-3.5 rounded bg-slate-950 border-slate-700 text-emerald-500 focus:ring-emerald-500"
              />
              <span>Running Bal.</span>
            </label>
          </div>
        </div>
      </div>

      {/* Excel Table Container with Sticky Header */}
      <div className="relative overflow-x-auto max-h-[560px] scrollbar-thin scrollbar-thumb-slate-700">
        <table className="w-full text-left border-collapse text-xs">
          {/* Sticky Header */}
          <thead className="sticky top-0 z-10 bg-slate-950 border-b border-slate-800 text-slate-400 uppercase tracking-wider font-semibold select-none shadow-md">
            {table.getHeaderGroups().map((headerGroup) => (
              <tr key={headerGroup.id}>
                {headerGroup.headers.map((header) => (
                  <th
                    key={header.id}
                    style={{ width: header.getSize() !== 150 ? header.getSize() : undefined }}
                    className={`px-3 py-3 font-semibold ${
                      header.id === "amount_minor" || header.id === "running_balance"
                        ? "text-right"
                        : "text-left"
                    }`}
                  >
                    {flexRender(header.column.columnDef.header, header.getContext())}
                  </th>
                ))}
              </tr>
            ))}
          </thead>

          {/* Table Body with Zebra Striping */}
          <tbody className="divide-y divide-slate-800/60">
            {isLoading ? (
              <tr>
                <td colSpan={columns.length} className="py-16 text-center text-slate-400">
                  <div className="flex flex-col items-center justify-center gap-2">
                    <Loader2 className="w-6 h-6 animate-spin text-emerald-500" />
                    <span>Loading ledger records...</span>
                  </div>
                </td>
              </tr>
            ) : entries.length === 0 ? (
              <tr>
                <td colSpan={columns.length} className="py-16 text-center text-slate-500">
                  No ledger entries match the selected filters.
                </td>
              </tr>
            ) : (
              table.getRowModel().rows.map((row, idx) => (
                <tr
                  key={row.id}
                  className={`transition-colors hover:bg-slate-800/60 ${
                    idx % 2 === 0 ? "bg-slate-900/30" : "bg-slate-950/30"
                  } ${row.original.is_voided ? "opacity-60 bg-red-950/5" : ""}`}
                >
                  {row.getVisibleCells().map((cell) => (
                    <td
                      key={cell.id}
                      className={`px-3 py-2.5 whitespace-nowrap ${
                        cell.column.id === "amount_minor" || cell.column.id === "running_balance"
                          ? "text-right"
                          : "text-left"
                      }`}
                    >
                      {flexRender(cell.column.columnDef.cell, cell.getContext())}
                    </td>
                  ))}
                </tr>
              ))
            )}
          </tbody>

          {/* Sticky Excel Footer Summary Row */}
          {!isLoading && entries.length > 0 && (
            <tfoot className="sticky bottom-0 z-10 bg-slate-950 border-t-2 border-slate-700 text-xs font-semibold text-slate-200">
              <tr>
                <td colSpan={3} className="px-3 py-3 text-slate-400 uppercase tracking-wider">
                  Filtered Dataset Totals ({totalCount} entries)
                </td>
                <td colSpan={3} className="px-3 py-3 text-right text-slate-400">
                  Total Income:{" "}
                  <span className="font-mono text-emerald-400 font-bold">
                    +{formatCurrency(filteredTotals.totalIncomeMinor)}
                  </span>
                  <span className="mx-2 text-slate-600">|</span>
                  Total Expense:{" "}
                  <span className="font-mono text-rose-400 font-bold">
                    -{formatCurrency(filteredTotals.totalExpenseMinor)}
                  </span>
                </td>
                <td className="px-3 py-3 text-right">
                  <span
                    className={`font-mono font-bold text-sm tabular-nums ${
                      filteredTotals.netMinor >= 0 ? "text-emerald-400" : "text-rose-400"
                    }`}
                  >
                    {filteredTotals.netMinor >= 0 ? "+" : ""}
                    {formatCurrency(filteredTotals.netMinor)}
                  </span>
                </td>
                <td colSpan={showRunningBalance ? 4 : 3} className="px-3 py-3" />
              </tr>
            </tfoot>
          )}
        </table>
      </div>

      {/* Pagination Controls */}
      <div className="flex flex-wrap items-center justify-between gap-3 p-3 px-4 border-t border-slate-800 bg-slate-950/60 text-xs text-slate-400">
        <div className="flex items-center gap-2">
          <span>Rows per page:</span>
          <select
            value={pageSize}
            onChange={(e) => {
              setPageSize(Number(e.target.value));
              setPageIndex(0);
            }}
            className="px-2 py-1 bg-slate-900 border border-slate-800 rounded text-xs text-slate-200 focus:outline-none"
          >
            {[25, 50, 100].map((size) => (
              <option key={size} value={size}>
                {size}
              </option>
            ))}
          </select>
          <span className="text-slate-500">
            Showing {entries.length > 0 ? pageIndex * pageSize + 1 : 0} -{" "}
            {Math.min((pageIndex + 1) * pageSize, totalCount)} of {totalCount}
          </span>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={() => setPageIndex((p) => Math.max(0, p - 1))}
            disabled={pageIndex === 0 || isLoading}
            className="p-1.5 rounded bg-slate-800 hover:bg-slate-700 disabled:opacity-40 disabled:cursor-not-allowed text-slate-200 transition"
          >
            <ChevronLeft className="w-4 h-4" />
          </button>
          <span className="font-mono text-slate-300">
            Page {pageIndex + 1} of {Math.max(1, totalPages)}
          </span>
          <button
            onClick={() => setPageIndex((p) => p + 1)}
            disabled={pageIndex + 1 >= totalPages || isLoading}
            className="p-1.5 rounded bg-slate-800 hover:bg-slate-700 disabled:opacity-40 disabled:cursor-not-allowed text-slate-200 transition"
          >
            <ChevronRight className="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>
  );
}

