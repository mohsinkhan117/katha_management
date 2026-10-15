import { NextRequest, NextResponse } from "next/server";
import { sql } from "@/lib/neon/db";

// Ensure companies table exists in Neon Postgres
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

// GET: Retrieve all active tenants or get current tenant by slug/header
export async function GET(req: NextRequest) {
  try {
    await ensureCompaniesTable();

    const { searchParams } = new URL(req.url);
    const slug = searchParams.get("slug");

    if (slug) {
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
          is_active
        FROM companies
        WHERE slug = ${slug} AND is_active = true
        LIMIT 1;
      `;

      if (rows && rows.length > 0) {
        return NextResponse.json({ success: true, company: rows[0] });
      }
      return NextResponse.json(
        { success: false, error: "Tenant not found or inactive." },
        { status: 404 }
      );
    }

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
        is_active
      FROM companies
      WHERE is_active = true
      ORDER BY name ASC;
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

