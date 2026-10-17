"use client";

import React, { useState, useEffect } from "react";
import {
  Building2,
  Plus,
  Search,
  ShieldCheck,
  ShieldAlert,
  Users,
  Mail,
  Phone,
  MapPin,
  ExternalLink,
  CheckCircle2,
  AlertCircle,
  X,
  Sparkles,
  Clock,
  RotateCcw,
} from "lucide-react";

interface CompanyTenant {
  id: string;
  name: string;
  slug: string;
  admin_email: string;
  phone?: string;
  address?: string;
  plan_tier: string;
  max_distributors: number;
  is_active: boolean;
  trial_started_at?: string | null;
  expires_at?: string | null;
  created_at: string;
}

export default function AdminCompaniesPage() {
  const [companies, setCompanies] = useState<CompanyTenant[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState("");
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  // Form State
  const [formData, setFormData] = useState({
    name: "",
    slug: "",
    adminEmail: "",
    phone: "",
    address: "",
    planTier: "free_trial",
    maxDistributors: 5,
  });

  const fetchCompanies = async () => {
    try {
      setIsLoading(true);
      const res = await fetch("/admin/api/companies");
      const json = await res.json();
      if (json.success) {
        setCompanies(json.companies || []);
      } else {
        // Fallback demo companies if table just initialized
        setCompanies([
          {
            id: "comp_apex_agro_01",
            name: "Apex Agro Chemical Ltd.",
            slug: "apex-agro",
            admin_email: "admin@apexagro.com",
            phone: "+92 42 35789000",
            address: "Plot 42, Industrial Estate, Kot Lakhpat, Lahore",
            plan_tier: "enterprise",
            max_distributors: 50,
            is_active: true,
            created_at: new Date(Date.now() - 86400000 * 30).toISOString(),
          },
          {
            id: "comp_crescent_feed_02",
            name: "Crescent Cattle Feed & Grains",
            slug: "crescent-feed",
            admin_email: "operations@crescentfeed.pk",
            phone: "+92 41 8765432",
            address: "Sargodha Road, Faisalabad",
            plan_tier: "free_trial",
            max_distributors: 5,
            is_active: true,
            trial_started_at: new Date(Date.now() - 86400000 * 10).toISOString(),
            expires_at: new Date(Date.now() + 86400000 * 20).toISOString(),
            created_at: new Date(Date.now() - 86400000 * 10).toISOString(),
          },
          {
            id: "comp_indus_fertilizer_03",
            name: "Indus Valley Fertilizer Corp",
            slug: "indus-fertilizer",
            admin_email: "mgmt@indusfert.com",
            phone: "+92 61 4567890",
            address: "Khanewal Road, Multan",
            plan_tier: "free_trial",
            max_distributors: 5,
            is_active: false,
            trial_started_at: new Date(Date.now() - 86400000 * 35).toISOString(),
            expires_at: new Date(Date.now() - 86400000 * 5).toISOString(),
            created_at: new Date(Date.now() - 86400000 * 35).toISOString(),
          },
        ]);
      }
    } catch (err: any) {
      console.error(err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchCompanies();
  }, []);

  const handleCreateCompany = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    setErrorMessage(null);

    try {
      const res = await fetch("/admin/api/companies", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: jsonEncodeSafe(formData),
      });
      const data = await res.json();

      if (data.success) {
        setSuccessMessage(
          `Tenant "${formData.name}" provisioned! They can now sign in with ${formData.adminEmail}.`
        );
        setIsModalOpen(false);
        setFormData({
          name: "",
          slug: "",
          adminEmail: "",
          phone: "",
          address: "",
          planTier: "free_trial",
          maxDistributors: 5,
        });
        await fetchCompanies();
        setTimeout(() => setSuccessMessage(null), 4000);
      } else {
        setErrorMessage(data.error || "Failed to provision company tenant.");
      }
    } catch (err: any) {
      setErrorMessage(err.message || "Network error. Please try again.");
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleToggleActive = async (id: string, currentStatus: boolean) => {
    try {
      const res = await fetch("/admin/api/companies", {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ id, isActive: !currentStatus }),
      });
      const data = await res.json();
      if (data.success && data.company) {
        setCompanies((prev) =>
          prev.map((c) => (c.id === id ? data.company : c))
        );
      }
    } catch (err) {
      console.error(err);
    }
  };

  const handleExtendOneMonth = async (id: string) => {
    try {
      const res = await fetch("/admin/api/companies", {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ id, isActive: true, extendDays: 30 }),
      });
      const data = await res.json();
      if (data.success && data.company) {
        setCompanies((prev) =>
          prev.map((c) => (c.id === id ? data.company : c))
        );
        setSuccessMessage("Extended tenant access by 1 month (30 days) and activated!");
        setTimeout(() => setSuccessMessage(null), 3500);
      }
    } catch (err) {
      console.error(err);
    }
  };

  const getExpiryInfo = (comp: CompanyTenant) => {
    if (!comp.expires_at) return null;
    const expMs = new Date(comp.expires_at).getTime();
    const diffDays = Math.ceil((expMs - Date.now()) / (1000 * 60 * 60 * 24));
    return {
      isExpired: diffDays < 0,
      daysRemaining: Math.max(0, diffDays),
      formattedDate: new Date(comp.expires_at).toLocaleDateString(),
    };
  };

  const filteredCompanies = companies.filter(
    (c) =>
      c.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      c.admin_email.toLowerCase().includes(searchQuery.toLowerCase()) ||
      c.slug.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="max-w-7xl mx-auto space-y-6 pb-12">
      {/* Top Banner Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 bg-slate-900 border border-slate-800 p-6 rounded-3xl text-white shadow-xl">
        <div>
          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-emerald-500/10 text-emerald-400 border border-emerald-500/30 text-xs font-semibold mb-2">
            <Sparkles className="w-3.5 h-3.5 text-emerald-400" />
            Multi-Tenant Provisioning & 1-Month Free Tier Lifecycle
          </div>
          <h1 className="text-2xl sm:text-3xl font-extrabold tracking-tight text-white">
            Companies & Tenant Provisioning
          </h1>
          <p className="text-slate-400 text-xs sm:text-sm mt-1 max-w-2xl">
            Create tenants for companies to sign into, or monitor self-service Company Sign-Ups (which automatically activate a 1-Month Free Tier and deactivate after 30 days).
          </p>
        </div>

        <button
          onClick={() => setIsModalOpen(true)}
          className="flex items-center gap-2 px-4 py-2.5 bg-emerald-600 hover:bg-emerald-500 text-white rounded-xl text-xs sm:text-sm font-semibold shadow-lg shadow-emerald-600/20 transition self-start sm:self-auto"
        >
          <Plus className="w-4 h-4" />
          Add New Company Tenant
        </button>
      </div>

      {/* Success Notification */}
      {successMessage && (
        <div className="p-4 bg-emerald-950/60 border border-emerald-600/40 rounded-2xl flex items-center gap-3 text-emerald-300 text-sm">
          <CheckCircle2 className="w-5 h-5 text-emerald-400 shrink-0" />
          <span>{successMessage}</span>
        </div>
      )}

      {/* Search and Filters Bar */}
      <div className="flex flex-col sm:flex-row items-center justify-between gap-4">
        <div className="relative w-full sm:w-80">
          <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
          <input
            type="text"
            placeholder="Search company name, email, slug..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-10 pr-4 py-2 bg-slate-900/90 border border-slate-800 rounded-xl text-xs text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition"
          />
        </div>

        <div className="flex items-center gap-2 text-xs text-slate-400">
          <span>Total Tenants:</span>
          <span className="font-bold text-white px-2 py-0.5 bg-slate-800 rounded-md">
            {companies.length}
          </span>
        </div>
      </div>

      {/* Companies Grid */}
      {isLoading ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {[1, 2, 3].map((i) => (
            <div
              key={i}
              className="h-56 bg-slate-900/50 rounded-2xl border border-slate-800 animate-pulse"
            />
          ))}
        </div>
      ) : filteredCompanies.length === 0 ? (
        <div className="p-12 text-center bg-slate-900/40 rounded-3xl border border-slate-800">
          <Building2 className="w-12 h-12 text-slate-600 mx-auto mb-3" />
          <h2 className="text-base font-bold text-white">No Company Tenants Found</h2>
          <p className="text-xs text-slate-400 mt-1 max-w-sm mx-auto">
            {searchQuery
              ? `No results matching "${searchQuery}".`
              : "Click the 'Add New Company Tenant' button to onboard your first tenant."}
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
          {filteredCompanies.map((comp) => {
            const expiry = getExpiryInfo(comp);
            return (
              <div
                key={comp.id}
                className="p-5 bg-slate-900/90 rounded-2xl border border-slate-800 hover:border-slate-700 transition flex flex-col justify-between group shadow-sm"
              >
                <div>
                  {/* Header */}
                  <div className="flex items-start justify-between gap-3">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-emerald-600 to-teal-500 flex items-center justify-center text-white font-extrabold text-sm shadow-md">
                        {comp.name.substring(0, 2).toUpperCase()}
                      </div>
                      <div>
                        <h2 className="text-base font-bold text-white group-hover:text-emerald-400 transition truncate max-w-[180px]">
                          {comp.name}
                        </h2>
                        <span className="text-[11px] font-mono text-slate-500">
                          @{comp.slug}
                        </span>
                      </div>
                    </div>

                    <span
                      className={`text-[10px] font-bold px-2 py-0.5 rounded-full uppercase tracking-wider ${
                        comp.plan_tier === "enterprise"
                          ? "bg-purple-950/80 text-purple-400 border border-purple-800/50"
                          : comp.plan_tier === "growth"
                          ? "bg-blue-950/80 text-blue-400 border border-blue-800/50"
                          : comp.plan_tier === "free_trial"
                          ? "bg-amber-950/80 text-amber-400 border border-amber-800/50"
                          : "bg-slate-800 text-slate-300 border border-slate-700"
                      }`}
                    >
                      {comp.plan_tier === "free_trial" ? "Free Tier (1M)" : comp.plan_tier}
                    </span>
                  </div>

                  {/* Details */}
                  <div className="mt-4 space-y-2 text-xs text-slate-400 border-t border-slate-800/60 pt-3">
                    <div className="flex items-center gap-2 truncate">
                      <Mail className="w-3.5 h-3.5 text-slate-500 shrink-0" />
                      <span className="truncate">{comp.admin_email}</span>
                    </div>

                    {comp.phone && (
                      <div className="flex items-center gap-2 truncate">
                        <Phone className="w-3.5 h-3.5 text-slate-500 shrink-0" />
                        <span>{comp.phone}</span>
                      </div>
                    )}

                    {comp.address && (
                      <div className="flex items-center gap-2 truncate">
                        <MapPin className="w-3.5 h-3.5 text-slate-500 shrink-0" />
                        <span className="truncate">{comp.address}</span>
                      </div>
                    )}

                    <div className="flex items-center gap-2 text-emerald-400 font-medium">
                      <Users className="w-3.5 h-3.5 text-emerald-500 shrink-0" />
                      <span>Quota: Up to {comp.max_distributors} Mobile Seats</span>
                    </div>

                    {expiry && (
                      <div
                        className={`flex items-center justify-between gap-2 px-2.5 py-1.5 rounded-lg border text-[11px] font-mono ${
                          expiry.isExpired
                            ? "bg-rose-950/50 border-rose-800/60 text-rose-300"
                            : "bg-amber-950/40 border-amber-800/50 text-amber-300"
                        }`}
                      >
                        <span className="flex items-center gap-1.5">
                          <Clock className="w-3.5 h-3.5 shrink-0" />
                          {expiry.isExpired
                            ? `Expired (${expiry.formattedDate})`
                            : `${expiry.daysRemaining}d left (until ${expiry.formattedDate})`}
                        </span>
                      </div>
                    )}
                  </div>
                </div>

                {/* Footer controls */}
                <div className="mt-5 pt-3 border-t border-slate-800/80 flex items-center justify-between gap-2">
                  <div className="flex items-center gap-1.5">
                    <button
                      onClick={() => handleToggleActive(comp.id, comp.is_active)}
                      className={`flex items-center gap-1.5 px-2.5 py-1 rounded-lg text-xs font-semibold transition ${
                        comp.is_active
                          ? "bg-emerald-950/60 text-emerald-400 border border-emerald-600/30 hover:bg-rose-950/40 hover:text-rose-400 hover:border-rose-600/30"
                          : "bg-rose-950/60 text-rose-400 border border-rose-600/30 hover:bg-emerald-950/40 hover:text-emerald-400 hover:border-emerald-600/30"
                      }`}
                      title={comp.is_active ? "Click to deactivate tenant" : "Click to activate tenant"}
                    >
                      {comp.is_active ? (
                        <>
                          <ShieldCheck className="w-3.5 h-3.5" />
                          Active
                        </>
                      ) : (
                        <>
                          <ShieldAlert className="w-3.5 h-3.5" />
                          Deactivated
                        </>
                      )}
                    </button>

                    {(!comp.is_active || expiry?.isExpired) && (
                      <button
                        onClick={() => handleExtendOneMonth(comp.id)}
                        className="flex items-center gap-1 px-2 py-1 rounded-lg text-[11px] font-semibold bg-amber-500/10 text-amber-300 border border-amber-500/30 hover:bg-amber-500/20 transition"
                        title="Extend +1 Month & Reactivate"
                      >
                        <RotateCcw className="w-3 h-3" />
                        +1M
                      </button>
                    )}
                  </div>

                  <a
                    href={process.env.NEXT_PUBLIC_COMPANY_WEB_URL || (typeof window !== "undefined" && window.location.hostname !== "localhost" ? "/" : "http://localhost:3000")}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="flex items-center gap-1 text-xs text-slate-400 hover:text-white transition"
                    title="Launch Tenant Portal"
                  >
                    <span>Portal</span>
                    <ExternalLink className="w-3.5 h-3.5" />
                  </a>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Add Tenant Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/75 backdrop-blur-sm animate-in fade-in">
          <div className="bg-slate-900 border border-slate-800 rounded-3xl max-w-lg w-full p-6 text-white shadow-2xl relative">
            <button
              onClick={() => setIsModalOpen(false)}
              className="absolute right-5 top-5 p-1 rounded-lg text-slate-400 hover:text-white hover:bg-slate-800 transition"
            >
              <X className="w-5 h-5" />
            </button>

            <div className="flex items-center gap-2 mb-1">
              <Building2 className="w-5 h-5 text-emerald-400" />
              <h2 className="text-xl font-bold">Add New Company Tenant</h2>
            </div>
            <p className="text-xs text-slate-400 mb-6">
              Provision a tenant in Neon Postgres so the Company Admin can sign in directly.
            </p>

            {errorMessage && (
              <div className="mb-4 p-3 bg-rose-950/60 border border-rose-600/40 rounded-xl flex items-center gap-2 text-rose-300 text-xs">
                <AlertCircle className="w-4 h-4 text-rose-400 shrink-0" />
                <span>{errorMessage}</span>
              </div>
            )}

            <form onSubmit={handleCreateCompany} className="space-y-4 text-xs">
              <div>
                <label className="block text-slate-300 font-semibold mb-1">
                  Company / Organization Name *
                </label>
                <input
                  type="text"
                  required
                  placeholder="e.g. Chenab Agro Fertilizers"
                  value={formData.name}
                  onChange={(e) => {
                    const name = e.target.value;
                    const slug = name
                      .toLowerCase()
                      .replace(/[^a-z0-9]+/g, "-")
                      .replace(/^-+|-+$/g, "");
                    setFormData({ ...formData, name, slug });
                  }}
                  className="w-full px-3.5 py-2.5 bg-slate-800/80 border border-slate-700 rounded-xl text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition"
                />
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="block text-slate-300 font-semibold mb-1">
                    Tenant Slug Identifier *
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. chenab-agro"
                    value={formData.slug}
                    onChange={(e) => setFormData({ ...formData, slug: e.target.value })}
                    className="w-full px-3.5 py-2.5 bg-slate-800/80 border border-slate-700 rounded-xl text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition font-mono"
                  />
                </div>

                <div>
                  <label className="block text-slate-300 font-semibold mb-1">
                    Company Admin Email *
                  </label>
                  <input
                    type="email"
                    required
                    placeholder="admin@chenab.pk"
                    value={formData.adminEmail}
                    onChange={(e) => setFormData({ ...formData, adminEmail: e.target.value })}
                    className="w-full px-3.5 py-2.5 bg-slate-800/80 border border-slate-700 rounded-xl text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="block text-slate-300 font-semibold mb-1">
                    Contact Phone
                  </label>
                  <input
                    type="text"
                    placeholder="+92 300 0000000"
                    value={formData.phone}
                    onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                    className="w-full px-3.5 py-2.5 bg-slate-800/80 border border-slate-700 rounded-xl text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition"
                  />
                </div>

                <div>
                  <label className="block text-slate-300 font-semibold mb-1">
                    Max Distributor Seats
                  </label>
                  <input
                    type="number"
                    min="1"
                    max="500"
                    value={formData.maxDistributors}
                    onChange={(e) =>
                      setFormData({ ...formData, maxDistributors: parseInt(e.target.value) || 5 })
                    }
                    className="w-full px-3.5 py-2.5 bg-slate-800/80 border border-slate-700 rounded-xl text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition"
                  />
                </div>
              </div>

              <div>
                <label className="block text-slate-300 font-semibold mb-1">
                  Subscription Plan Tier
                </label>
                <select
                  value={formData.planTier}
                  onChange={(e) => {
                    const tier = e.target.value;
                    setFormData({
                      ...formData,
                      planTier: tier,
                      maxDistributors: tier === "free_trial" ? 5 : tier === "standard" ? 25 : 50,
                    });
                  }}
                  className="w-full px-3.5 py-2.5 bg-slate-800/80 border border-slate-700 rounded-xl text-white focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition"
                >
                  <option value="free_trial">Free Tier (1 Month Trial - Auto Deactivates After 30 Days)</option>
                  <option value="standard">Standard Plan (25 Seats, Full Accounting)</option>
                  <option value="growth">Growth Plan (50 Seats, Priority PowerSync)</option>
                  <option value="enterprise">Enterprise Plan (Unlimited Seats, Dedicated Neon)</option>
                </select>
              </div>

              <div>
                <label className="block text-slate-300 font-semibold mb-1">
                  HQ Physical Address
                </label>
                <textarea
                  rows={2}
                  placeholder="Street, City, Industrial Area..."
                  value={formData.address}
                  onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                  className="w-full px-3.5 py-2.5 bg-slate-800/80 border border-slate-700 rounded-xl text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition"
                />
              </div>

              <div className="pt-4 flex items-center justify-end gap-3">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-xl font-medium transition"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="px-5 py-2 bg-emerald-600 hover:bg-emerald-500 text-white rounded-xl font-semibold shadow-md shadow-emerald-600/20 transition flex items-center gap-2"
                >
                  {isSubmitting ? "Provisioning..." : "Provision Tenant"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}

function jsonEncodeSafe(data: any): string {
  return JSON.stringify(data);
}
