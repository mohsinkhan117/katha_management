import { NextRequest, NextResponse } from "next/server";
import { assertAdminAuth, getLedgerChartData } from "@/lib/ledger/service";

// GET /api/ledger/chart?range=7d|30d|90d
export async function GET(req: NextRequest) {
  try {
    const auth = await assertAdminAuth(req);
    const { searchParams } = new URL(req.url);
    const range = searchParams.get("range") || "30d";

    const chartData = await getLedgerChartData(auth.tenantId, range, auth.timezone);

    return NextResponse.json({
      success: true,
      data: chartData,
    });
  } catch (error: any) {
    const status = error.status || 500;
    return NextResponse.json(
      { success: false, error: error.message || "Failed to fetch chart analytics" },
      { status }
    );
  }
}

