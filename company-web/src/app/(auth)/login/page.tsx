import React, { Suspense } from "react";
import { SignIn } from "@stackframe/stack";
import { Sparkles, ShieldCheck, Clock } from "lucide-react";

export default function CompanyLoginPage() {
  return (
    <div className="min-h-screen flex flex-col items-center justify-center p-6 bg-slate-50">
      <div className="w-full max-w-md space-y-5">
        <div className="bg-slate-900 text-white rounded-2xl p-4 border border-slate-800 shadow-lg space-y-2">
          <div className="flex items-center gap-2 text-emerald-400 text-xs font-bold uppercase tracking-wider">
            <Sparkles className="w-3.5 h-3.5" />
            Company Authentication & Free Tier
          </div>
          <p className="text-xs text-slate-300 leading-relaxed">
            • <strong>Existing Tenant?</strong> Sign in with the Company Admin email issued by the Super Admin.
          </p>
          <p className="text-xs text-emerald-300 leading-relaxed flex items-start gap-1.5">
            <Clock className="w-3.5 h-3.5 shrink-0 mt-0.5" />
            <span>
              <strong>New Company Sign-Up:</strong> Signing up automatically activates a{" "}
              <strong>1-Month Free Tier (30 Days)</strong>, after which the account is automatically deactivated unless renewed.
            </span>
          </p>
        </div>

        <div className="bg-white rounded-2xl p-6 shadow-md border border-slate-200">
          <Suspense fallback={<div className="text-center text-sm text-slate-500">Loading authentication...</div>}>
            <SignIn />
          </Suspense>
        </div>
      </div>
    </div>
  );
}
