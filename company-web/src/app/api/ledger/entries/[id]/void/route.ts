import { NextRequest, NextResponse } from "next/server";
import { assertAdminAuth, voidLedgerEntry } from "@/lib/ledger/service";
import { VoidLedgerEntrySchema } from "@/lib/ledger/schemas";

export async function POST(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const auth = await assertAdminAuth(req);
    const { id } = await params;
    const body = await req.json();

    const parsed = VoidLedgerEntrySchema.safeParse(body);
    if (!parsed.success) {
      return NextResponse.json(
        { success: false, error: "Validation failed", details: parsed.error.format() },
        { status: 400 }
      );
    }

    const updated = await voidLedgerEntry(
      auth.tenantId,
      auth.userId,
      id,
      parsed.data.reason
    );

    return NextResponse.json({
      success: true,
      message: "Ledger entry voided successfully.",
      data: updated,
    });
  } catch (error: any) {
    const status = error.status || 500;
    return NextResponse.json(
      { success: false, error: error.message || "Failed to void ledger entry" },
      { status }
    );
  }
}

