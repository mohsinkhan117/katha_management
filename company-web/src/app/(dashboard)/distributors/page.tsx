"use client";

import React, { useState } from "react";
import { Users, KeyRound, Plus, Copy, Check, MapPin, Phone, ShieldCheck } from "lucide-react";

interface DistributorItem {
  id: string;
  name: string;
  phone: string;
  territory: string;
  inviteToken: string;
  isClaimed: boolean;
  totalOrders: number;
  monthlySales: number;
  lastActive: string;
}

const mockDistributors: DistributorItem[] = [
  {
    id: "dist-1",
    name: "Ali Hassan",
    phone: "+92 300 1234567",
    territory: "Lahore East (Zone A)",
    inviteToken: "KTH-8821-4920",
    isClaimed: true,
    totalOrders: 142,
    monthlySales: 1680000,
    lastActive: "10 mins ago",
  },
  {
    id: "dist-2",
    name: "Zubair Khan",
    phone: "+92 321 9876543",
    territory: "Faisalabad Industrial Area",
    inviteToken: "KTH-5192-3318",
    isClaimed: true,
    totalOrders: 98,
    monthlySales: 1240000,
    lastActive: "45 mins ago",
  },
  {
    id: "dist-3",
    name: "Tariq Mehmood",
    phone: "+92 333 4455667",
    territory: "Gujranwala City & Cantt",
    inviteToken: "KTH-7740-1099",
    isClaimed: true,
    totalOrders: 65,
    monthlySales: 890000,
    lastActive: "3 hours ago",
  },
  {
    id: "dist-4",
    name: "Pending Claim (New Seat)",
    phone: "Unassigned",
    territory: "Multan Central Zone",
    inviteToken: "KTH-9943-5521",
    isClaimed: false,
    totalOrders: 0,
    monthlySales: 0,
    lastActive: "Token Generated (Awaiting claim)",
  },
];

export default function CompanyDistributorsPage() {
  const [copiedToken, setCopiedToken] = useState<string | null>(null);

  const handleCopy = (token: string) => {
    navigator.clipboard.writeText(token);
    setCopiedToken(token);
    setTimeout(() => setCopiedToken(null), 2000);
  };

  return (
    <div className="max-w-7xl mx-auto space-y-6">
      {/* Top Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-extrabold text-slate-900 tracking-tight">
            Distributors & Invite Tokens
          </h1>
          <p className="text-xs sm:text-sm text-slate-500 mt-1">
            Issue 12-character cryptographic tokens to onboard field mobile agents and monitor territory sales.
          </p>
        </div>

        <button
          onClick={() => alert("Generated new token: KTH-" + Math.floor(1000 + Math.random() * 9000) + "-" + Math.floor(1000 + Math.random() * 9000))}
          className="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-500 text-white rounded-xl text-xs font-semibold shadow-md shadow-blue-600/20 transition self-start sm:self-auto"
        >
          <KeyRound className="w-4 h-4" />
          Generate 12-char Invite Token
        </button>
      </div>

      {/* Distributors Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {mockDistributors.map((dist) => (
          <div
            key={dist.id}
            className="p-5 bg-white rounded-2xl border border-slate-200 shadow-sm hover:border-slate-300 transition flex flex-col justify-between"
          >
            <div>
              <div className="flex items-start justify-between gap-2">
                <div>
                  <div className="flex items-center gap-2">
                    <h2 className="text-base font-bold text-slate-900">
                      {dist.name}
                    </h2>
                    {dist.isClaimed ? (
                      <span className="text-[10px] font-semibold px-2 py-0.5 rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200 flex items-center gap-1">
                        <ShieldCheck className="w-3 h-3" />
                        Active
                      </span>
                    ) : (
                      <span className="text-[10px] font-semibold px-2 py-0.5 rounded-full bg-amber-50 text-amber-700 border border-amber-200">
                        Unclaimed Token
                      </span>
                    )}
                  </div>
                  <div className="flex items-center gap-2 text-xs text-slate-500 mt-1">
                    <MapPin className="w-3.5 h-3.5 text-slate-400" />
                    <span>{dist.territory}</span>
                  </div>
                  {dist.phone !== "Unassigned" && (
                    <div className="flex items-center gap-2 text-xs text-slate-500 mt-0.5">
                      <Phone className="w-3.5 h-3.5 text-slate-400" />
                      <span>{dist.phone}</span>
                    </div>
                  )}
                </div>

                <div className="text-right">
                  <div className="text-xs font-semibold text-slate-400 uppercase">
                    Monthly Sales
                  </div>
                  <div className="text-lg font-bold text-slate-900">
                    Rs. {dist.monthlySales.toLocaleString()}
                  </div>
                </div>
              </div>

              {/* Token Bar */}
              <div className="my-4 p-3 bg-slate-50 rounded-xl border border-slate-200/80 flex items-center justify-between">
                <div>
                  <span className="text-[10px] uppercase font-semibold text-slate-400 block">
                    Invite Token
                  </span>
                  <span className="font-mono font-bold text-slate-800 text-xs tracking-wider">
                    {dist.inviteToken}
                  </span>
                </div>
                <button
                  onClick={() => handleCopy(dist.inviteToken)}
                  className="flex items-center gap-1 px-2.5 py-1 text-xs font-semibold bg-white border border-slate-200 rounded-lg text-slate-700 hover:bg-slate-100 transition shadow-sm"
                >
                  {copiedToken === dist.inviteToken ? (
                    <>
                      <Check className="w-3.5 h-3.5 text-emerald-600" />
                      Copied
                    </>
                  ) : (
                    <>
                      <Copy className="w-3.5 h-3.5" />
                      Copy
                    </>
                  )}
                </button>
              </div>
            </div>

            <div className="pt-3 border-t border-slate-100 flex items-center justify-between text-xs text-slate-500">
              <span>{dist.totalOrders} total B2B dispatches</span>
              <span>Last active: {dist.lastActive}</span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
