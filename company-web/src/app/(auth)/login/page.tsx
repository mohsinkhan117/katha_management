import React, { Suspense } from "react";
import { SignIn } from "@stackframe/stack";

export default function CompanyLoginPage() {
  return (
    <div className="min-h-screen flex items-center justify-center p-6 bg-slate-50">
      <div className="w-full max-w-md">
        <Suspense fallback={<div className="text-center text-sm text-slate-500">Loading sign in...</div>}>
          <SignIn />
        </Suspense>
      </div>
    </div>
  );
}
