import { NextRequest, NextResponse } from "next/server";
import { sql } from "@/lib/neon/db";

// Ensure schema exists in Neon Postgres
async function ensureTables() {
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

  await sql`
    CREATE TABLE IF NOT EXISTS distributor_invite_tokens (
      id VARCHAR(64) PRIMARY KEY,
      token VARCHAR(32) UNIQUE NOT NULL,
      company_id VARCHAR(64) NOT NULL,
      territory_id VARCHAR(64),
      territory_name VARCHAR(255),
      distributor_name VARCHAR(255),
      phone VARCHAR(64),
      device_id VARCHAR(128),
      is_claimed BOOLEAN DEFAULT false,
      claimed_at TIMESTAMP WITH TIME ZONE,
      expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '30 days'),
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
  `;

  await sql`
    CREATE TABLE IF NOT EXISTS orders (
      id VARCHAR(64) PRIMARY KEY,
      company_id VARCHAR(64) NOT NULL,
      order_number VARCHAR(64) NOT NULL,
      party_name VARCHAR(255) NOT NULL,
      distributor_name VARCHAR(255),
      items_count INT DEFAULT 1,
      total_amount NUMERIC(12, 2) DEFAULT 0,
      paid_amount NUMERIC(12, 2) DEFAULT 0,
      status VARCHAR(32) DEFAULT 'Pending',
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
  `;
}

// GET /api/tenant/data?companyId=...&slug=...
export async function GET(req: NextRequest) {
  try {
    await ensureTables();

    const { searchParams } = new URL(req.url);
    const companyId = searchParams.get("companyId");
    const slug = searchParams.get("slug");

    if (!companyId && !slug) {
      return NextResponse.json(
        { success: false, error: "companyId or slug is required" },
        { status: 400 }
      );
    }

    // Resolve company
    let company: any = null;
    if (companyId) {
      const compRows = await sql`SELECT * FROM companies WHERE id = ${companyId} LIMIT 1;`;
      if (compRows.length > 0) company = compRows[0];
    } else if (slug) {
      const compRows = await sql`SELECT * FROM companies WHERE slug = ${slug} LIMIT 1;`;
      if (compRows.length > 0) company = compRows[0];
    }

    if (!company) {
      // Tenant does not exist in DB or user has no access
      return NextResponse.json({
        success: true,
        hasAccess: false,
        isCustomTenant: false,
        data: null,
      });
    }

    // Fetch distributors / invite tokens for THIS tenant only
    const distributors = await sql`
      SELECT 
        id,
        token as "inviteToken",
        COALESCE(distributor_name, 'Pending Claim') as name,
        COALESCE(phone, 'Unassigned') as phone,
        COALESCE(territory_name, 'General Zone') as territory,
        is_claimed as "isClaimed",
        created_at as "createdAt"
      FROM distributor_invite_tokens
      WHERE company_id = ${company.id}
      ORDER BY created_at DESC;
    `;

    // Fetch orders for THIS tenant only
    const orders = await sql`
      SELECT 
        id,
        order_number as "orderNumber",
        party_name as "partyName",
        distributor_name as "distributorName",
        items_count as "itemsCount",
        total_amount as "totalAmount",
        paid_amount as "paidAmount",
        status,
        created_at as "date"
      FROM orders
      WHERE company_id = ${company.id}
      ORDER BY created_at DESC;
    `;

    // Calculate aggregated metrics for this tenant
    const totalOrdersCount = orders.length;
    const totalSalesNum = orders.reduce((sum: number, o: any) => sum + Number(o.totalAmount || 0), 0);
    const totalPaidNum = orders.reduce((sum: number, o: any) => sum + Number(o.paidAmount || 0), 0);
    const totalProfitNum = Math.round(totalSalesNum * 0.22); // estimated gross margin

    return NextResponse.json({
      success: true,
      hasAccess: true,
      isCustomTenant: company.slug !== "apex-agro",
      company,
      metrics: {
        totalOrders: totalOrdersCount,
        totalSales: totalSalesNum,
        totalPaid: totalPaidNum,
        totalProfit: totalProfitNum,
      },
      distributors,
      orders,
    });
  } catch (error: any) {
    return NextResponse.json(
      { success: false, error: error.message },
      { status: 500 }
    );
  }
}

// POST /api/tenant/data - Generate an invite token for this tenant
export async function POST(req: NextRequest) {
  try {
    await ensureTables();
    const body = await req.json();
    const { companyId, territoryName, distributorName, phone } = body;

    if (!companyId) {
      return NextResponse.json(
        { success: false, error: "companyId is required" },
        { status: 400 }
      );
    }

    // Generate token in KTH-XXXX-XXXX format
    const part1 = Math.floor(1000 + Math.random() * 9000);
    const part2 = Math.floor(1000 + Math.random() * 9000);
    const token = `KTH-${part1}-${part2}`;
    const id = `tok_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 6)}`;

    const rows = await sql`
      INSERT INTO distributor_invite_tokens (
        id,
        token,
        company_id,
        territory_name,
        distributor_name,
        phone,
        is_claimed
      ) VALUES (
        ${id},
        ${token},
        ${companyId},
        ${territoryName || 'Central Zone'},
        ${distributorName || null},
        ${phone || null},
        false
      ) RETURNING *;
    `;

    return NextResponse.json({
      success: true,
      token: rows[0],
    });
  } catch (error: any) {
    return NextResponse.json(
      { success: false, error: error.message },
      { status: 500 }
    );
  }
}

