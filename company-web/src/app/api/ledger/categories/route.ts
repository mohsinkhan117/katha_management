import { NextRequest, NextResponse } from "next/server";
import { assertAdminAuth, createLedgerCategory, getLedgerCategories } from "@/lib/ledger/service";
import { CreateLedgerCategorySchema } from "@/lib/ledger/schemas";

// GET /api/ledger/categories - List categories for this tenant
export async function GET(req: NextRequest) {
  try {
    const auth = await assertAdminAuth(req);
    const categories = await getLedgerCategories(auth.tenantId);

    return NextResponse.json({
      success: true,
      data: categories,
    });
  } catch (error: any) {
    const status = error.status || 500;
    return NextResponse.json(
      { success: false, error: error.message || "Failed to fetch categories" },
      { status }
    );
  }
}

// POST /api/ledger/categories - Add a custom category
export async function POST(req: NextRequest) {
  try {
    const auth = await assertAdminAuth(req);
    const body = await req.json();

    const parsed = CreateLedgerCategorySchema.safeParse(body);
    if (!parsed.success) {
      return NextResponse.json(
        { success: false, error: "Validation failed", details: parsed.error.format() },
        { status: 400 }
      );
    }

    const category = await createLedgerCategory(
      auth.tenantId,
      parsed.data.name,
      parsed.data.type
    );

    return NextResponse.json({
      success: true,
      message: "Custom category created.",
      data: category,
    });
  } catch (error: any) {
    const status = error.status || 500;
    return NextResponse.json(
      { success: false, error: error.message || "Failed to create category" },
      { status }
    );
  }
}

