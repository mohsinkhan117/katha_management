"use client";

import React, { useState, useEffect } from "react";
import { Building2, Users, CheckCircle2, AlertCircle, Loader2, Save } from "lucide-react";
import { useTenant } from "@/context/TenantContext";

export default function CompanySettingsPage() {
  const { activeTenant, tenantData, updateTenantProfile } = useTenant();

  const [name, setName] = useState("");
  const [phone, setPhone] = useState("");
  const [address, setAddress] = useState("");
  const [adminEmail, setAdminEmail] = useState("");

  const [isSubmitting, setIsSubmitting] = useState(false);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  useEffect(() => {
    if (activeTenant) {
      setName(activeTenant.name || "");
      setPhone(activeTenant.phone || "");
      setAddress(activeTenant.address || "");
      setAdminEmail(activeTenant.admin_email || "");
    }
  }, [activeTenant]);

  const maxSeats = activeTenant?.max_distributors || 25;
  const usedSeats = tenantData?.distributors?.length || 0;
  const seatPercent = Math.min(100, Math.round((usedSeats / maxSeats) * 100));

  const handleSaveProfile = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      setIsSubmitting(true);
      setSuccessMessage(null);
      setErrorMessage(null);

      const res = await updateTenantProfile({
        name: name.trim(),
        phone: phone.trim(),
        address: address.trim(),
        adminEmail: adminEmail.trim(),
      });

      if (res.success) {
        setSuccessMessage("Company profile settings successfully updated in Neon PostgreSQL.");
        setTimeout(() => setSuccessMessage(null), 4000);
      } else {
        setErrorMessage(res.error || "Failed to update profile settings.");
      }
    } catch (err: any) {
      setErrorMessage(err.message || "An unexpected error occurred.");
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="max-w-5xl mx-auto space-y-6 pb-12">
      <div>
        <h1 className="text-2xl font-extrabold text-slate-900 tracking-tight">
          Company Settings & Configuration
        </h1>
        <p className="text-xs sm:text-sm text-slate-500 mt-1">
          Manage your organization profile, billing headers, distributor seat limits, and database synchronization.
        </p>
      </div>

      {successMessage && (
        <div className="p-4 bg-emerald-50 border border-emerald-200 rounded-2xl flex items-center gap-3 text-emerald-900 text-xs animate-in fade-in">
          <CheckCircle2 className="w-5 h-5 text-emerald-600 shrink-0" />
          <span className="font-semibold">{successMessage}</span>
        </div>
      )}

      {errorMessage && (
        <div className="p-4 bg-rose-50 border border-rose-200 rounded-2xl flex items-center gap-3 text-rose-900 text-xs animate-in fade-in">
          <AlertCircle className="w-5 h-5 text-rose-600 shrink-0" />
          <span className="font-semibold">{errorMessage}</span>
        </div>
      )}

      <form onSubmit={handleSaveProfile} className="space-y-6">
        {/* Company Profile Card */}
        <div className="bg-white rounded-2xl border border-slate-200 p-6 shadow-sm space-y-4">
          <div className="flex items-center gap-3 pb-3 border-b border-slate-100">
            <div className="w-8 h-8 rounded-lg bg-blue-50 text-blue-600 flex items-center justify-center">
              <Building2 className="w-4 h-4" />
            </div>
            <div>
              <h2 className="text-base font-bold text-slate-900">
                Company Profile & Commercial Identity
              </h2>
              <p className="text-xs text-slate-500">
                This appears on distributor order invoices and PDF ledger statements.
              </p>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-xs">
            <div>
              <label className="font-semibold text-slate-700 block mb-1">Company Registered Name *</label>
              <input
                type="text"
                required
                value={name}
                onChange={(e) => setName(e.target.value)}
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
              />
            </div>
            <div>
              <label className="font-semibold text-slate-700 block mb-1">Organization Slug (DB Identifier)</label>
              <input
                type="text"
                value={activeTenant?.slug || ""}
                disabled
                className="w-full px-3 py-2 bg-slate-100 border border-slate-200 rounded-xl text-slate-500 focus:outline-none font-mono cursor-not-allowed"
              />
            </div>
            <div>
              <label className="font-semibold text-slate-700 block mb-1">Primary Admin Email *</label>
              <input
                type="email"
                required
                value={adminEmail}
                onChange={(e) => setAdminEmail(e.target.value)}
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
              />
            </div>
            <div>
              <label className="font-semibold text-slate-700 block mb-1">Headquarters Phone</label>
              <input
                type="text"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                placeholder="+92 42 35889900"
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
              />
            </div>
            <div className="md:col-span-2">
              <label className="font-semibold text-slate-700 block mb-1">Headquarters Commercial Address</label>
              <textarea
                rows={2}
                value={address}
                onChange={(e) => setAddress(e.target.value)}
                placeholder="Plot 42, Industrial Estate, Kot Lakhpat, Lahore"
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 focus:outline-none focus:ring-2 focus:ring-blue-500/20 resize-none"
              />
            </div>
          </div>

          <div className="pt-2 flex justify-end">
            <button
              type="submit"
              disabled={isSubmitting}
              className="px-5 py-2.5 bg-blue-600 hover:bg-blue-500 text-white font-semibold rounded-xl text-xs flex items-center gap-2 shadow-md shadow-blue-600/20 transition disabled:opacity-60"
            >
              {isSubmitting ? (
                <Loader2 className="w-4 h-4 animate-spin" />
              ) : (
                <Save className="w-4 h-4" />
              )}
              Save Profile Changes
            </button>
          </div>
        </div>

        {/* Subscription & Seat Allocation */}
        <div className="bg-white rounded-2xl border border-slate-200 p-6 shadow-sm space-y-4">
          <div className="flex items-center justify-between pb-3 border-b border-slate-100">
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-lg bg-emerald-50 text-emerald-600 flex items-center justify-center">
                <Users className="w-4 h-4" />
              </div>
              <div>
                <h2 className="text-base font-bold text-slate-900">
                  Plan Quota & Distributor Seats
                </h2>
                <p className="text-xs text-slate-500">
                  Active field distributor licenses provisioned in Neon PostgreSQL.
                </p>
              </div>
            </div>
            <span className="text-xs font-bold capitalize text-blue-700 bg-blue-50 border border-blue-200 px-3 py-1 rounded-full">
              {activeTenant?.plan_tier || "standard"} Tier
            </span>
          </div>

          <div className="p-4 bg-slate-50 rounded-xl border border-slate-200/80 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
            <div>
              <div className="text-xs font-semibold text-slate-700">Distributor Mobile Seats Used</div>
              <div className="text-lg font-extrabold text-slate-900">
                {usedSeats} <span className="text-xs font-normal text-slate-500">of {maxSeats} seats issued</span>
              </div>
            </div>
            <div className="w-full sm:w-48 h-2 bg-slate-200 rounded-full overflow-hidden">
              <div
                style={{ width: `${seatPercent}%` }}
                className="h-full bg-blue-600 rounded-full transition-all duration-500"
              />
            </div>
          </div>
        </div>
      </form>
    </div>
  );
}
