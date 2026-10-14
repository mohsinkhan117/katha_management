import { NextRequest, NextResponse } from "next/server";
import { sql } from "@/lib/neon/db";

// Ensure companies table exists
async function ensureCompaniesTable() {
  await sql`
    CREATE TABLE IF NOT EXISTS companies (
      id VARCHAR(64) PRIMARY KEY,
      name VARCHAR(255) NOT NULL,
      slug VARCHAR(128) UNIQUE NOT NULL,
      admin_email VARCHAR(255) NOT NULL,
      phone VARCHAR(64),
      address TEXT,
      plan_tier VARCHAR(32) DEFAULT 'standard',
      max_distributors INT DEFAULT 25,
      is_active BOOLEAN DEFAULT true,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
  `;
}

// GET: List all tenant companies
export async function GET() {
  try {
    await ensureCompaniesTable();

    const rows = await sql`
      SELECT 
        id,
        name,
        slug,
        admin_email,
        phone,
        address,
        plan_tier,
        max_distributors,
        is_active,
        created_at
      FROM companies
      ORDER BY created_at DESC;
    `;

    return NextResponse.json({
      success: true,
      companies: rows,
    });
  } catch (error: any) {
    return NextResponse.json(
      { success: false, error: error.message },
      { status: 500 }
    );
  }
}

// POST: Provision a new tenant company
export async function POST(req: NextRequest) {
  try {
    await ensureCompaniesTable();

    const body = await req.json();
    const { name, slug, adminEmail, phone, address, planTier, maxDistributors } = body;

    if (!name || !adminEmail) {
      return NextResponse.json(
        { success: false, error: "Company name and Admin Email are required." },
        { status: 400 }
      );
    }

    const companySlug = (slug || name)
      .toLowerCase()
      .trim()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-+|-+$/g, "");

    const companyId = `comp_${companySlug}_${Date.now().toString(36)}`;

    const rows = await sql`
      INSERT INTO companies (
        id,
        name,
        slug,
        admin_email,
        phone,
        address,
        plan_tier,
        max_distributors,
        is_active
      ) VALUES (
        ${companyId},
        ${name.trim()},
        ${companySlug},
        ${adminEmail.trim().toLowerCase()},
        ${phone || null},
        ${address || null},
        ${planTier || 'standard'},
        ${maxDistributors || 25},
        true
      )
      RETURNING *;
    `;

    return NextResponse.json({
      success: true,
      message: "Company tenant provisioned successfully.",
      company: rows[0],
    });
  } catch (error: any) {
    return NextResponse.json(
      { success: false, error: error.message },
      { status: 500 }
    );
  }
}

// PATCH: Toggle tenant activation status
export async function PATCH(req: NextRequest) {
  try {
    const { id, isActive } = await req.json();

    if (!id || typeof isActive !== "boolean") {
      return NextResponse.json(
        { success: false, error: "Company ID and isActive status are required." },
        { status: 400 }
      );
    }

    const rows = await sql`
      UPDATE companies
      SET is_active = ${isActive}, updated_at = NOW()
      WHERE id = ${id}
      RETURNING *;
    `;

    return NextResponse.json({
      success: true,
      company: rows[0],
    });
  } catch (error: any) {
    return NextResponse.json(
      { success: false, error: error.message },
      { status: 500 }
    );
  }
}

