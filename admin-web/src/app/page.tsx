import Link from "next/link";

const adminModules = [
  {
    title: "Companies & Tenant Provisioning",
    href: "/companies",
    desc: "Onboard new Company accounts, issue Company Admin credentials, and suspend or activate tenants.",
  },
  {
    title: "Subscriptions & Plan Quotas",
    href: "/subscriptions",
    desc: "Manage Free vs. Premium tiers, set max distributor seat limits, and track billing cycles.",
  },
  {
    title: "Global Users & RBAC Directory",
    href: "/users",
    desc: "Audit Super Admins, Company Admins, and connected Field Distributors across all tenants.",
  },
  {
    title: "Platform Analytics & Sync Health",
    href: "/analytics",
    desc: "Monitor Supabase + PowerSync replication telemetry, active tenants, and total platform GMV.",
  },
  {
    title: "Security & Audit Logs",
    href: "/audit-logs",
    desc: "Review invite token brute-force alerts, tenant provisioning logs, and RLS policy events.",
  },
];

export default function SuperAdminDashboardPage() {
  return (
    <main className="max-w-6xl mx-auto p-8">
      <header className="mb-8 border-b border-slate-800 pb-4">
        <span className="text-xs font-semibold uppercase tracking-wider text-emerald-400 bg-emerald-950/60 border border-emerald-800 px-2.5 py-1 rounded">
          Panel 3 &bull; Platform Super Admin Console
        </span>
        <h1 className="text-3xl font-bold mt-2 text-white">
          Multi-Tenant SaaS Control Plane
        </h1>
        <p className="text-slate-400 mt-1">
          Provision company access, control subscription tiers & distributor seat quotas, and monitor platform-wide telemetry.
        </p>
      </header>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
        {adminModules.map((m) => (
          <Link
            key={m.href}
            href={m.href}
            className="block p-5 bg-slate-900 rounded-xl border border-slate-800 hover:border-emerald-500 transition"
          >
            <h2 className="text-lg font-semibold text-white">{m.title}</h2>
            <p className="text-sm text-slate-400 mt-2">{m.desc}</p>
          </Link>
        ))}
      </div>
    </main>
  );
}

