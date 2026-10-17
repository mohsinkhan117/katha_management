import React, { Suspense } from "react";
import { SignIn } from "@stackframe/stack";
import { ShieldCheck } from "lucide-react";

export default function SuperAdminLoginPage() {
  return (
    <div className="min-h-screen flex flex-col items-center justify-center p-6 bg-slate-950 text-white">
      <div className="w-full max-w-md space-y-5">
        <div className="bg-slate-900 border border-slate-800 rounded-2xl p-4 shadow-xl space-y-1.5 text-center">
          <div className="inline-flex items-center gap-1.5 text-emerald-400 text-xs font-bold uppercase tracking-wider">
            <ShieldCheck className="w-4 h-4" />
            Super Admin Control Plane
          </div>
          <p className="text-xs text-slate-400">
            Restricted access. Sign in with your Super Admin credentials to provision and manage company tenants.
          </p>
        </div>
        <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 shadow-xl">
          <Suspense fallback={<div className="text-center text-sm text-slate-400">Loading Super Admin Sign-In...</div>}>
            <SignIn />
          </Suspense>
        </div>
      </div>
    </div>
  );
}
