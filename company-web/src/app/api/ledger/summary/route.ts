import { NextRequest, NextResponse } from "next/server";
import { assertAdminAuth, getLedgerSummary } from "@/lib/ledger/service";

// GET /api/ledger/summary?date=YYYY-MM-DD
export async function GET(req: NextRequest) {
  try {
    const auth = await assertAdminAuth(req);
    const { searchParams } = new URL(req.url);
    const dateStr = searchParams.get("date") || undefined;

    const summary = await getLedgerSummary(auth.tenantId, dateStr, auth.timezone);

    return NextResponse.json({
      success: true,
      data: summary,
    });
  } catch (error: any) {
    const status = error.status || 500;
    return NextResponse.json(
      { success: false, error: error.message || "Failed to fetch ledger summary" },
      { status }
    );
  }
}

