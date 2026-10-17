import { NextRequest, NextResponse } from "next/server";
import { sql } from "@/lib/neon/db";
import { stackServerApp } from "@/stack";

// Ensure companies table exists in Neon Postgres with 1-month free trial columns
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

  // Auto-deactivate any tenant whose 1-month free trial or subscription has expired
  await sql`
    UPDATE companies
    SET is_active = false, updated_at = NOW()
    WHERE is_active = true
      AND expires_at IS NOT NULL
      AND expires_at < NOW();
  `;
}

function enrichCompanyStatus(company: any) {
  if (!company) return null;
  const now = Date.now();
  const expiresMs = company.expires_at ? new Date(company.expires_at).getTime() : null;
  const isExpired = expiresMs !== null && expiresMs < now;
  const daysRemaining =
    expiresMs !== null
      ? Math.max(0, Math.ceil((expiresMs - now) / (1000 * 60 * 60 * 24)))
      : null;

  return {
    ...company,
    is_active: isExpired ? false : Boolean(company.is_active),
    is_expired: isExpired,
    days_remaining: daysRemaining,
  };
}

async function getAuthenticatedEmail(req: NextRequest): Promise<{ user: any; email: string | null }> {
  let user: any = null;
  try {
    user = await stackServerApp.getUser({ tokenStore: req } as any);
  } catch (e) {
    // ignore
  }
  if (!user) {
    try {
      user = await stackServerApp.getUser();
    } catch (e) {
      // ignore
    }
  }
  const email = (user?.primaryEmail || user?.emails?.[0] || "")
    .toString()
    .trim()
    .toLowerCase();
  return { user, email: email || null };
}

// GET: Retrieve ONLY the authenticated user's own tenant
export async function GET(req: NextRequest) {
  try {
    await ensureCompaniesTable();

    const { email: sessionEmail } = await getAuthenticatedEmail(req);
    if (!sessionEmail) {
      return NextResponse.json(
        { success: false, error: "Authentication required. Please sign in." },
        { status: 401 }
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
        is_active,
        trial_started_at,
        expires_at,
        created_at,
        updated_at
      FROM companies
      WHERE LOWER(admin_email) = ${sessionEmail}
      LIMIT 1;
    `;

    const company = rows.length > 0 ? enrichCompanyStatus(rows[0]) : null;

    return NextResponse.json({
      success: true,
      company,
      companies: company ? [company] : [],
    });
  } catch (error: any) {
    return NextResponse.json(
      { success: false, error: error.message },
      { status: 500 }
    );
  }
}

// POST:
// 1) If Super Admin already provisioned a tenant for this email -> Sign-In binds to that tenant (checks 1-month expiry / active status).
// 2) If Company signs up for the first time -> Activates 1-Month Free Tier (`free_trial`, expires in 30 days, auto-deactivates after 1 month).
export async function POST(req: NextRequest) {
  try {
    await ensureCompaniesTable();
    const { user, email: sessionEmail } = await getAuthenticatedEmail(req);
    const body = await req.json();
    const { email: bodyEmail, name, phone, address } = body;

    const cleanEmail = (sessionEmail || bodyEmail || "").trim().toLowerCase();

    if (!sessionEmail || !cleanEmail) {
      return NextResponse.json(
        { success: false, error: "Authentication required to access or create a tenant." },
        { status: 401 }
      );
    }

    // 1. Check if Super Admin provisioned a tenant or company previously signed up
    const existing = await sql`
      SELECT * FROM companies
      WHERE LOWER(admin_email) = ${sessionEmail}
      LIMIT 1;
    `;

    if (existing && existing.length > 0) {
      const enriched = enrichCompanyStatus(existing[0]);
      return NextResponse.json({
        success: true,
        company: enriched,
        isNew: false,
        isDeactivated: !enriched.is_active,
        deactivationReason: enriched.is_expired
          ? "Your 1-month Free Tier trial has expired and your tenant has been automatically deactivated. Please contact Super Admin to upgrade or renew your subscription."
          : !enriched.is_active
          ? "This company tenant has been deactivated by Super Admin."
          : null,
      });
    }

    // 2. First-time Company Sign-Up -> Activate 1-Month Free Tier (30 days)
    const displayName = user?.displayName || name;
    const companyName =
      displayName && displayName.trim().length > 0
        ? displayName.trim()
        : `${sessionEmail.split("@")[0].replace(/[^a-zA-Z0-9]/g, " ").trim()} Commercial`;

    let baseSlug = companyName
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-+|-+$/g, "");

    if (!baseSlug) baseSlug = "company";
    const uniqueSuffix = Date.now().toString(36).slice(-4);
    const finalSlug = `${baseSlug}-${uniqueSuffix}`;
    const companyId = `comp_${baseSlug}_${Date.now().toString(36)}`;

    const now = new Date();
    // 1-Month (30 days) Free Tier expiration
    const oneMonthLater = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);

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
        is_active,
        trial_started_at,
        expires_at
      ) VALUES (
        ${companyId},
        ${companyName},
        ${finalSlug},
        ${sessionEmail},
        ${phone || "+92 300 0000000"},
        ${address || "Headquarters Commercial Zone"},
        'free_trial',
        5,
        true,
        ${now.toISOString()},
        ${oneMonthLater.toISOString()}
      )
      RETURNING *;
    `;

    const enriched = enrichCompanyStatus(inserted[0]);

    return NextResponse.json({
      success: true,
      company: enriched,
      isNew: true,
      isDeactivated: false,
      message: "1-Month Free Tier activated! Your trial is active for 30 days.",
    });
  } catch (error: any) {
    return NextResponse.json(
      { success: false, error: error.message },
      { status: 500 }
    );
  }
}

// PATCH: Update tenant company profile settings (only for the signed-in owner)
export async function PATCH(req: NextRequest) {
  try {
    await ensureCompaniesTable();
    const { email: sessionEmail } = await getAuthenticatedEmail(req);
    if (!sessionEmail) {
      return NextResponse.json(
        { success: false, error: "Authentication required." },
        { status: 401 }
      );
    }

    const body = await req.json();
    const { id, name, phone, address } = body;

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
        updated_at = NOW()
      WHERE id = ${id} AND LOWER(admin_email) = ${sessionEmail}
      RETURNING *;
    `;

    if (!updated || updated.length === 0) {
      return NextResponse.json(
        { success: false, error: "Company not found or unauthorized." },
        { status: 403 }
      );
    }

    return NextResponse.json({
      success: true,
      message: "Company profile updated successfully.",
      company: enrichCompanyStatus(updated[0]),
    });
  } catch (error: any) {
    return NextResponse.json(
      { success: false, error: error.message },
      { status: 500 }
    );
  }
}
