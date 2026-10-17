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

// GET: Retrieve all active tenants, or get by slug, or get by email
export async function GET(req: NextRequest) {
  try {
    await ensureCompaniesTable();

    const { searchParams } = new URL(req.url);
    const slug = searchParams.get("slug");
    const email = searchParams.get("email");

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
          is_active,
          created_at,
          updated_at
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

    if (email) {
      const cleanEmail = email.trim().toLowerCase();
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
          created_at,
          updated_at
        FROM companies
        WHERE LOWER(admin_email) = ${cleanEmail} AND is_active = true
        LIMIT 1;
      `;

      if (rows && rows.length > 0) {
        return NextResponse.json({ success: true, company: rows[0] });
      }
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
        is_active,
        created_at,
        updated_at
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

// POST: Sync or auto-provision tenant company for a logged-in user
export async function POST(req: NextRequest) {
  try {
    await ensureCompaniesTable();
    const body = await req.json();
    const { email, name, phone, address } = body;

    if (!email) {
      return NextResponse.json(
        { success: false, error: "User email is required to sync tenant" },
        { status: 400 }
      );
    }

    const cleanEmail = email.trim().toLowerCase();

    // 1. Check if user already has an active company
    const existing = await sql`
      SELECT * FROM companies
      WHERE LOWER(admin_email) = ${cleanEmail}
      LIMIT 1;
    `;

    if (existing && existing.length > 0) {
      return NextResponse.json({
        success: true,
        company: existing[0],
        isNew: false,
      });
    }

    // 2. Derive company name and unique slug
    const companyName = name && name.trim().length > 0
      ? name.trim()
      : `${cleanEmail.split("@")[0].replace(/[^a-zA-Z0-9]/g, " ").trim()} Commercial`;

    let baseSlug = companyName
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-+|-+$/g, "");
    
    if (!baseSlug) baseSlug = "company";
    const uniqueSuffix = Date.now().toString(36).slice(-4);
    const finalSlug = `${baseSlug}-${uniqueSuffix}`;
    const companyId = `comp_${baseSlug}_${Date.now().toString(36)}`;

    // 3. Create tenant company in Neon DB
    const inserted = await sql`
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
        ${companyName},
        ${finalSlug},
        ${cleanEmail},
        ${phone || "+92 300 0000000"},
        ${address || "Headquarters Commercial Zone"},
        'standard',
        25,
        true
      )
      RETURNING *;
    `;

    return NextResponse.json({
      success: true,
      company: inserted[0],
      isNew: true,
    });
  } catch (error: any) {
    return NextResponse.json(
      { success: false, error: error.message },
      { status: 500 }
    );
  }
}

// PATCH: Update tenant company profile settings
export async function PATCH(req: NextRequest) {
  try {
    await ensureCompaniesTable();
    const body = await req.json();
    const { id, name, phone, address, adminEmail } = body;

    if (!id) {
      return NextResponse.json(
        { success: false, error: "Company ID is required to update profile." },
        { status: 400 }
      );
    }

    const updated = await sql`
      UPDATE companies
      SET 
        name = COALESCE(${name || null}, name),
        phone = COALESCE(${phone || null}, phone),
        address = COALESCE(${address || null}, address),
        admin_email = COALESCE(${adminEmail ? adminEmail.trim().toLowerCase() : null}, admin_email),
        updated_at = NOW()
      WHERE id = ${id}
      RETURNING *;
    `;

    if (!updated || updated.length === 0) {
      return NextResponse.json(
        { success: false, error: "Company not found." },
        { status: 404 }
      );
    }

    return NextResponse.json({
      success: true,
      message: "Company profile updated successfully.",
      company: updated[0],
    });
  } catch (error: any) {
    return NextResponse.json(
      { success: false, error: error.message },
      { status: 500 }
    );
  }
}
