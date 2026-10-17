import { NextRequest, NextResponse } from "next/server";
import { assertAdminAuth, generateLedgerCsv } from "@/lib/ledger/service";
import { LedgerFilterSchema } from "@/lib/ledger/schemas";

// GET /api/ledger/export - Export filtered entries as Excel-friendly CSV with UTF-8 BOM
export async function GET(req: NextRequest) {
  try {
    const auth = await assertAdminAuth(req);
    const { searchParams } = new URL(req.url);

    const queryParams: Record<string, string> = {};
    searchParams.forEach((val, key) => {
      queryParams[key] = val;
    });

    const parsedFilters = LedgerFilterSchema.safeParse(queryParams);
    if (!parsedFilters.success) {
      return NextResponse.json(
        { success: false, error: "Invalid export filter parameters" },
        { status: 400 }
      );
    }

    const csvContent = await generateLedgerCsv(auth.tenantId, parsedFilters.data);
    const fileName = `commercial-ledger-${auth.tenantName.toLowerCase().replace(/[^a-z0-9]/g, "-")}-${new Date().toISOString().split("T")[0]}.csv`;

    return new NextResponse(csvContent, {
      status: 200,
      headers: {
        "Content-Type": "text/csv; charset=utf-8",
        "Content-Disposition": `attachment; filename="${fileName}"`,
        "Cache-Control": "no-store, max-age=0",
      },
    });
  } catch (error: any) {
    const status = error.status || 500;
    return NextResponse.json(
      { success: false, error: error.message || "Failed to export ledger" },
      { status }
    );
  }
}

