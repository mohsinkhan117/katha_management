"use client";

import React from "react";
import { MapPin, Users, Building, Plus, ArrowUpRight } from "lucide-react";

const mockTerritories = [
  {
    id: "ter-1",
    name: "Lahore East (Zone A)",
    region: "Punjab Central",
    distributor: "Ali Hassan",
    partiesCount: 84,
    monthlyTarget: 2000000,
    currentSales: 1680000,
  },
  {
    id: "ter-2",
    name: "Faisalabad Industrial Area",
    region: "Punjab West",
    distributor: "Zubair Khan",
    partiesCount: 62,
    monthlyTarget: 1500000,
    currentSales: 1240000,
  },
  {
    id: "ter-3",
    name: "Gujranwala City & Cantt",
    region: "Punjab North",
    distributor: "Tariq Mehmood",
    partiesCount: 45,
    monthlyTarget: 1000000,
    currentSales: 890000,
  },
  {
    id: "ter-4",
    name: "Multan Central Zone",
    region: "Punjab South",
    distributor: "Unassigned (Awaiting Token)",
    partiesCount: 38,
    monthlyTarget: 800000,
    currentSales: 0,
  },
];

export default function CompanyTerritoriesPage() {
  return (
    <div className="max-w-7xl mx-auto space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-extrabold text-slate-900 tracking-tight">
            Territories & Field Zones
          </h1>
          <p className="text-xs sm:text-sm text-slate-500 mt-1">
            Partition sales regions, establish quotas, and bind field distributor app instances to customer bases.
          </p>
        </div>

        <button
          onClick={() => alert("Open Add Territory Modal")}
          className="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-500 text-white rounded-xl text-xs font-semibold shadow-md shadow-blue-600/20 transition self-start sm:self-auto"
        >
          <Plus className="w-4 h-4" />
          Add Territory Zone
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {mockTerritories.map((ter) => {
          const progressPercent = Math.min(100, Math.round((ter.currentSales / ter.monthlyTarget) * 100));

          return (
            <div
              key={ter.id}
              className="p-5 bg-white rounded-2xl border border-slate-200 shadow-sm hover:border-slate-300 transition"
            >
              <div className="flex items-start justify-between gap-2">
                <div>
                  <div className="flex items-center gap-2">
                    <MapPin className="w-4 h-4 text-blue-600" />
                    <h2 className="text-base font-bold text-slate-900">
                      {ter.name}
                    </h2>
                  </div>
                  <span className="text-xs text-slate-500 block mt-0.5">
                    {ter.region}
                  </span>
                </div>
                <span className="text-[11px] font-semibold text-slate-600 bg-slate-100 px-2 py-0.5 rounded-md">
                  {ter.partiesCount} Registered Stores
                </span>
              </div>

              <div className="my-4 p-3 bg-slate-50 rounded-xl border border-slate-200/80">
                <div className="flex items-center justify-between text-xs">
                  <span className="text-slate-600 font-medium">Assigned Distributor:</span>
                  <span className="font-bold text-slate-900">{ter.distributor}</span>
                </div>
              </div>

              <div>
                <div className="flex items-center justify-between text-xs text-slate-600 mb-1.5">
                  <span>Quota Achievement</span>
                  <span className="font-bold text-slate-900">{progressPercent}%</span>
                </div>
                <div className="w-full h-2.5 bg-slate-100 rounded-full overflow-hidden">
                  <div
                    style={{ width: `${progressPercent}%` }}
                    className="h-full bg-blue-600 rounded-full transition-all duration-500"
                  />
                </div>
                <div className="flex items-center justify-between text-[11px] text-slate-400 mt-1.5">
                  <span>Sales: Rs. {ter.currentSales.toLocaleString()}</span>
                  <span>Target: Rs. {ter.monthlyTarget.toLocaleString()}</span>
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
