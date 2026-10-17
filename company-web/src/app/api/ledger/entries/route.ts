import { NextRequest, NextResponse } from "next/server";
import { assertAdminAuth, createLedgerEntry, getLedgerEntries } from "@/lib/ledger/service";
import { CreateLedgerEntrySchema, LedgerFilterSchema } from "@/lib/ledger/schemas";

// GET /api/ledger/entries - List filtered ledger entries with server-side totals
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
        { success: false, error: "Invalid query parameters", details: parsedFilters.error.format() },
        { status: 400 }
      );
    }

    const data = await getLedgerEntries(auth.tenantId, parsedFilters.data);

    return NextResponse.json({
      success: true,
      data,
    });
  } catch (error: any) {
    const status = error.status || 500;
    return NextResponse.json(
      { success: false, error: error.message || "Failed to fetch ledger entries" },
      { status }
    );
  }
}

// POST /api/ledger/entries - Create a new ledger entry
export async function POST(req: NextRequest) {
  try {
    const auth = await assertAdminAuth(req);
    const body = await req.json();

    const parsed = CreateLedgerEntrySchema.safeParse(body);
    if (!parsed.success) {
      return NextResponse.json(
        { success: false, error: "Validation failed", details: parsed.error.format() },
        { status: 400 }
      );
    }

    const entry = await createLedgerEntry(
      auth.tenantId,
      auth.userId,
      auth.userName,
      parsed.data
    );

    return NextResponse.json({
      success: true,
      message: "Ledger entry created successfully.",
      data: entry,
    });
  } catch (error: any) {
    const status = error.status || 500;
    return NextResponse.json(
      { success: false, error: error.message || "Failed to create ledger entry" },
      { status }
    );
  }
}

