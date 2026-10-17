"use client";

import React from "react";
import Link from "next/link";
import { PlusCircle, KeyRound, PackagePlus, Receipt, ArrowRight } from "lucide-react";

interface QuickActionsProps {
  onActionClick?: (actionKey: "token" | "order" | "product" | "collection") => void;
}

export function QuickActions({ onActionClick }: QuickActionsProps) {
  const actions = [
    {
      actionKey: "token" as const,
      title: "Issue Distributor Token",
      desc: "Generate a 12-char KTH-XXXX token",
      href: "/distributors",
      icon: KeyRound,
      color: "bg-blue-600 text-white hover:bg-blue-700",
    },
    {
      actionKey: "order" as const,
      title: "New B2B Order",
      desc: "Create company dispatch order",
      href: "/orders",
      icon: PlusCircle,
      color: "bg-slate-900 text-white hover:bg-slate-800",
    },
    {
      actionKey: "product" as const,
      title: "Add Product SKU",
      desc: "Catalog item with size tiers",
      href: "/products",
      icon: PackagePlus,
      color: "bg-emerald-600 text-white hover:bg-emerald-700",
    },
    {
      actionKey: "collection" as const,
      title: "Record Collection",
      desc: "Credit ledger settlement entry",
      href: "/parties",
      icon: Receipt,
      color: "bg-violet-600 text-white hover:bg-violet-700",
    },
  ];

  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3 my-4">
      {actions.map((act) => {
        const Icon = act.icon;
        const content = (
          <div className="flex items-center justify-between p-3.5 bg-white rounded-2xl border border-slate-200/90 shadow-sm hover:border-slate-300 hover:shadow-md transition group w-full text-left cursor-pointer">
            <div className="flex items-center gap-3 min-w-0">
              <div
                className={`w-9 h-9 rounded-xl flex items-center justify-center shrink-0 ${act.color} shadow-sm transition-transform group-hover:scale-105`}
              >
                <Icon className="w-4 h-4" />
              </div>
              <div className="min-w-0">
                <div className="text-xs font-bold text-slate-900 truncate">
                  {act.title}
                </div>
                <div className="text-[11px] text-slate-400 truncate">
                  {act.desc}
                </div>
              </div>
            </div>
            <ArrowRight className="w-4 h-4 text-slate-400 group-hover:text-slate-700 group-hover:translate-x-1 transition-all shrink-0 ml-2" />
          </div>
        );

        if (onActionClick) {
          return (
            <button
              key={act.title}
              type="button"
              onClick={() => onActionClick(act.actionKey)}
              className="w-full block"
            >
              {content}
            </button>
          );
        }

        return (
          <Link key={act.title} href={act.href}>
            {content}
          </Link>
        );
      })}
    </div>
  );
}
