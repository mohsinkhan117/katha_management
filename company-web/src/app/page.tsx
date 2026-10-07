import Link from "next/link";

const modules = [
  {
    title: "Master Product Catalog",
    href: "/products",
    desc: "Add & manage company products, SKUs, and size variants synced to field distributors.",
  },
  {
    title: "Distributors & Invite Tokens",
    href: "/distributors",
    desc: "Generate 12-char invite tokens (KTH-XXXX-XXXX) and track distributor sales & ledger stats.",
  },
  {
    title: "Territories & Regions",
    href: "/territories",
    desc: "Define geographic sales territories and assign field distributors to regions.",
  },
  {
    title: "B2B Orders & Fulfillment",
    href: "/orders",
    desc: "Realtime feed of orders placed by distributors from the Flutter mobile app.",
  },
  {
    title: "Parties & Khata Ledger",
    href: "/parties",
    desc: "Centralized company receivables, credit limits, and party transaction history.",
  },
  {
    title: "Company Settings",
    href: "/settings",
    desc: "Manage company profile, invoice branding, and subscription plan usage.",
  },
];

export default function CompanyDashboardPage() {
  return (
    <main className="max-w-6xl mx-auto p-8">
      <header className="mb-8 border-b pb-4">
        <span className="text-xs font-semibold uppercase tracking-wider text-blue-700 bg-blue-50 px-2.5 py-1 rounded">
          Panel 2 &bull; Company Admin Portal
        </span>
        <h1 className="text-3xl font-bold mt-2 text-slate-900">
          Company Central Command
        </h1>
        <p className="text-slate-600 mt-1">
          Manage your master catalog, distributor invite tokens, territories, and centralized B2B orders.
        </p>
      </header>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
        {modules.map((m) => (
          <Link
            key={m.href}
            href={m.href}
            className="block p-5 bg-white rounded-xl border border-slate-200 shadow-sm hover:border-blue-500 transition"
          >
            <h2 className="text-lg font-semibold text-slate-900">{m.title}</h2>
            <p className="text-sm text-slate-600 mt-2">{m.desc}</p>
          </Link>
        ))}
      </div>
    </main>
  );
}

