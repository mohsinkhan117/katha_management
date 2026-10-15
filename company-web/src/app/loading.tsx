export default function Loading() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-900 text-white text-sm font-semibold">
      <div className="flex items-center gap-3">
        <div className="w-5 h-5 border-2 border-blue-500 border-t-transparent rounded-full animate-spin" />
        <span>Loading Katha Portal...</span>
      </div>
    </div>
  );
}

