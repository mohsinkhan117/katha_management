import { SignIn } from "@stackframe/stack";

export default function SuperAdminLoginPage() {
  return (
    <div className="min-h-screen flex items-center justify-center p-6 bg-slate-950">
      <div className="w-full max-w-md">
        <SignIn />
      </div>
    </div>
  );
}
