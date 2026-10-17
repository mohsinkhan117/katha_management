import { NextRequest, NextResponse } from "next/server";
import { sql } from "@/lib/neon/db";

// Ensure companies table exists with 1-month free trial & expiration columns
async function ensureCompaniesTable() {
  await sql`
    CREATE TABLE IF NOT EXISTS companies (
      id VARCHAR(64) PRIMARY KEY,
      name VARCHAR(255) NOT NULL,
      slug VARCHAR(128) UNIQUE NOT NULL,
      admin_email VARCHAR(255) NOT NULL,
      phone VARCHAR(64),
      address TEXT,
      plan_tier VARCHAR(32) DEFAULT 'free_trial',
      max_distributors INT DEFAULT 25,
      is_active BOOLEAN DEFAULT true,
      trial_started_at TIMESTAMP WITH TIME ZONE,
      expires_at TIMESTAMP WITH TIME ZONE,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
  `;

  await sql`
    ALTER TABLE companies
      ADD COLUMN IF NOT EXISTS trial_started_at TIMESTAMP WITH TIME ZONE,
      ADD COLUMN IF NOT EXISTS expires_at TIMESTAMP WITH TIME ZONE;
  `;

  // Automatically deactivate any tenant whose 1-month trial or subscription has expired
  await sql`
    UPDATE companies
    SET is_active = false, updated_at = NOW()
    WHERE is_active = true
      AND expires_at IS NOT NULL
      AND expires_at < NOW();
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
        trial_started_at,
        expires_at,
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

// POST: Super Admin provisions a new tenant company
export async function POST(req: NextRequest) {
  try {
    await ensureCompaniesTable();

    const body = await req.json();
    const { name, slug, adminEmail, phone, address, planTier, maxDistributors, durationDays } = body;

    if (!name || !adminEmail) {
      return NextResponse.json(
        { success: false, error: "Company name and Admin Email are required." },
        { status: 400 }
      );
    }

    const cleanEmail = adminEmail.trim().toLowerCase();

    // Check if email already has a tenant
    const existing = await sql`
      SELECT id FROM companies WHERE LOWER(admin_email) = ${cleanEmail} LIMIT 1;
    `;
    if (existing.length > 0) {
      return NextResponse.json(
        { success: false, error: `A tenant company is already assigned to ${cleanEmail}.` },
        { status: 409 }
      );
    }

    const companySlug = (slug || name)
      .toLowerCase()
      .trim()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-+|-+$/g, "");

    const companyId = `comp_${companySlug}_${Date.now().toString(36)}`;
    const selectedTier = planTier || "standard";

    // If provisioned as free_trial, set 30-day (1 month) expiry; or if custom durationDays provided
    const days = selectedTier === "free_trial" ? (durationDays || 30) : (durationDays || null);
    const expiresAt = days
      ? new Date(Date.now() + Number(days) * 24 * 60 * 60 * 1000).toISOString()
      : null;
    const trialStartedAt = selectedTier === "free_trial" ? new Date().toISOString() : null;

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
        is_active,
        trial_started_at,
        expires_at
      ) VALUES (
        ${companyId},
        ${name.trim()},
        ${companySlug},
        ${cleanEmail},
        ${phone || null},
        ${address || null},
        ${selectedTier},
        ${maxDistributors || (selectedTier === "free_trial" ? 5 : 25)},
        true,
        ${trialStartedAt},
        ${expiresAt}
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

// PATCH: Toggle tenant activation status, extend 1-month trial, or upgrade plan
export async function PATCH(req: NextRequest) {
  try {
    await ensureCompaniesTable();
    const { id, isActive, planTier, extendDays } = await req.json();

    if (!id) {
      return NextResponse.json(
        { success: false, error: "Company ID is required." },
        { status: 400 }
      );
    }

    // If reactivating an expired tenant or extending days, push expires_at forward by 30 days (1 month)
    if (isActive === true || extendDays) {
      const daysToAdd = Number(extendDays) || 30;
      const newExpiresAt = new Date(Date.now() + daysToAdd * 24 * 60 * 60 * 1000).toISOString();
      const rows = await sql`
        UPDATE companies
        SET 
          is_active = true,
          plan_tier = COALESCE(${planTier || null}, plan_tier),
          expires_at = CASE
            WHEN ${Boolean(extendDays)} THEN ${newExpiresAt}::timestamptz
            WHEN expires_at IS NOT NULL AND expires_at < NOW() THEN ${newExpiresAt}::timestamptz
            ELSE expires_at
          END,
          updated_at = NOW()
        WHERE id = ${id}
        RETURNING *;
      `;
      return NextResponse.json({
        success: true,
        company: rows[0],
      });
    }

    const rows = await sql`
      UPDATE companies
      SET 
        is_active = COALESCE(${typeof isActive === "boolean" ? isActive : null}, is_active),
        plan_tier = COALESCE(${planTier || null}, plan_tier),
        updated_at = NOW()
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

