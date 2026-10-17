import { NextRequest, NextResponse } from "next/server";
import {
  sql,
  ensureAppSchema,
  getCachedTenantByEmail,
  setCachedTenantByEmail,
  invalidateTenantCache,
  fetchTenantDashboardPayload,
} from "@/lib/neon/db";
import { stackServerApp } from "@/stack";

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
    const [, { email: sessionEmail }] = await Promise.all([
      ensureAppSchema(),
      getAuthenticatedEmail(req),
    ]);

    if (!sessionEmail) {
      return NextResponse.json(
        { success: false, error: "Authentication required. Please sign in." },
        { status: 401 }
      );
    }

    let rawCompany = getCachedTenantByEmail(sessionEmail);
    if (!rawCompany) {
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
      rawCompany = rows.length > 0 ? rows[0] : null;
      if (rawCompany) {
        setCachedTenantByEmail(sessionEmail, rawCompany);
      }
    }

    const company = rawCompany ? enrichCompanyStatus(rawCompany) : null;

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
    const [, { user, email: sessionEmail }, body] = await Promise.all([
      ensureAppSchema(),
      getAuthenticatedEmail(req),
      req.json().catch(() => ({})),
    ]);

    const { email: bodyEmail, name, phone, address, includeData } = body;
    const cleanEmail = (sessionEmail || bodyEmail || "").trim().toLowerCase();

    if (!sessionEmail || !cleanEmail) {
      return NextResponse.json(
        { success: false, error: "Authentication required to access or create a tenant." },
        { status: 401 }
      );
    }

    // 1. Check if Super Admin provisioned a tenant or company previously signed up
    let rawCompany = getCachedTenantByEmail(sessionEmail);
    if (!rawCompany) {
      const existing = await sql`
        SELECT * FROM companies
        WHERE LOWER(admin_email) = ${sessionEmail}
        LIMIT 1;
      `;
      if (existing && existing.length > 0) {
        rawCompany = existing[0];
        setCachedTenantByEmail(sessionEmail, rawCompany);
      }
    }

    if (rawCompany) {
      const enriched = enrichCompanyStatus(rawCompany);
      const isDeactivated = !enriched.is_active;
      const tenantData =
        includeData && !isDeactivated
          ? await fetchTenantDashboardPayload(enriched.id)
          : null;

      return NextResponse.json({
        success: true,
        company: enriched,
        tenantData,
        isNew: false,
        isDeactivated,
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

    setCachedTenantByEmail(sessionEmail, inserted[0]);
    const enriched = enrichCompanyStatus(inserted[0]);
    const tenantData = includeData
      ? {
          metrics: {
            totalOrders: 0,
            totalSales: 0,
            totalPaid: 0,
            totalProfit: 0,
            outstandingReceivables: 0,
            recoveryRate: 0,
          },
          orderStatuses: [
            { status: "Delivered", count: 0, percentage: 0, color: "bg-emerald-500" },
            { status: "In Transit", count: 0, percentage: 0, color: "bg-blue-500" },
            { status: "Pending", count: 0, percentage: 0, color: "bg-amber-500" },
            { status: "Cancelled", count: 0, percentage: 0, color: "bg-rose-500" },
          ],
          distributors: [],
          orders: [],
          products: [],
          parties: [],
        }
      : null;

    return NextResponse.json({
      success: true,
      company: enriched,
      tenantData,
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
    const [, { email: sessionEmail }, body] = await Promise.all([
      ensureAppSchema(),
      getAuthenticatedEmail(req),
      req.json().catch(() => ({})),
    ]);

    if (!sessionEmail) {
      return NextResponse.json(
        { success: false, error: "Authentication required." },
        { status: 401 }
      );
    }

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

    invalidateTenantCache(sessionEmail);
    setCachedTenantByEmail(sessionEmail, updated[0]);

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

