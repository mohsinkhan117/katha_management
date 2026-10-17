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

  await sql`
    CREATE TABLE IF NOT EXISTS products (
      id VARCHAR(64) PRIMARY KEY,
      company_id VARCHAR(64) NOT NULL,
      name VARCHAR(255) NOT NULL,
      sku VARCHAR(64),
      category VARCHAR(128),
      unit_price NUMERIC(12, 2) DEFAULT 0,
      stock_quantity INT DEFAULT 0,
      is_active BOOLEAN DEFAULT true,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
  `;

  await sql`
    CREATE TABLE IF NOT EXISTS parties (
      id VARCHAR(64) PRIMARY KEY,
      company_id VARCHAR(64) NOT NULL,
      name VARCHAR(255) NOT NULL,
      owner_name VARCHAR(255),
      phone VARCHAR(64),
      territory VARCHAR(128),
      balance NUMERIC(12, 2) DEFAULT 0,
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
      return NextResponse.json({
        success: true,
        hasAccess: false,
        isCustomTenant: false,
        data: null,
      });
    }

    // Fetch distributors / invite tokens for THIS tenant
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

    // Fetch orders for THIS tenant
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

    // Fetch products for THIS tenant
    const products = await sql`
      SELECT 
        id,
        name,
        sku,
        category,
        unit_price as "unitPrice",
        stock_quantity as "stockQuantity",
        is_active as "isActive",
        created_at as "createdAt"
      FROM products
      WHERE company_id = ${company.id}
      ORDER BY created_at DESC;
    `;

    // Fetch parties for THIS tenant
    const parties = await sql`
      SELECT 
        id,
        name,
        owner_name as "ownerName",
        phone,
        territory,
        balance,
        created_at as "createdAt"
      FROM parties
      WHERE company_id = ${company.id}
      ORDER BY created_at DESC;
    `;

    // Calculate aggregated metrics from real database orders
    const totalOrdersCount = orders.length;
    const totalSalesNum = orders.reduce((sum: number, o: any) => sum + Number(o.totalAmount || 0), 0);
    const totalPaidNum = orders.reduce((sum: number, o: any) => sum + Number(o.paidAmount || 0), 0);
    const totalProfitNum = Math.round(totalSalesNum * 0.22); // gross profit margin

    // Status breakdown
    const deliveredCount = orders.filter((o: any) => o.status === "Delivered" || o.status === "Completed").length;
    const inTransitCount = orders.filter((o: any) => o.status === "In Transit").length;
    const pendingCount = orders.filter((o: any) => o.status === "Pending").length;
    const cancelledCount = orders.filter((o: any) => o.status === "Cancelled").length;

    const totalCalculated = totalOrdersCount || 1;
    const orderStatuses = [
      { status: "Delivered", count: deliveredCount, percentage: Number(((deliveredCount / totalCalculated) * 100).toFixed(1)), color: "bg-emerald-500" },
      { status: "In Transit", count: inTransitCount, percentage: Number(((inTransitCount / totalCalculated) * 100).toFixed(1)), color: "bg-blue-500" },
      { status: "Pending", count: pendingCount, percentage: Number(((pendingCount / totalCalculated) * 100).toFixed(1)), color: "bg-amber-500" },
      { status: "Cancelled", count: cancelledCount, percentage: Number(((cancelledCount / totalCalculated) * 100).toFixed(1)), color: "bg-rose-500" },
    ];

    // Collections breakdown
    const outstandingReceivables = Math.max(0, totalSalesNum - totalPaidNum);
    const recoveryRate = totalSalesNum > 0 ? Number(((totalPaidNum / totalSalesNum) * 100).toFixed(1)) : 0;

    return NextResponse.json({
      success: true,
      hasAccess: true,
      isCustomTenant: true,
      company,
      metrics: {
        totalOrders: totalOrdersCount,
        totalSales: totalSalesNum,
        totalPaid: totalPaidNum,
        totalProfit: totalProfitNum,
        outstandingReceivables,
        recoveryRate,
      },
      orderStatuses,
      distributors,
      orders,
      products,
      parties,
    });
  } catch (error: any) {
    return NextResponse.json(
      { success: false, error: error.message },
      { status: 500 }
    );
  }
}

// POST /api/tenant/data - Create orders, tokens, products, or record collections
export async function POST(req: NextRequest) {
  try {
    await ensureTables();
    const body = await req.json();
    const { action, companyId } = body;

    if (!companyId) {
      return NextResponse.json(
        { success: false, error: "companyId is required" },
        { status: 400 }
      );
    }

    // 1. Create a real B2B Order
    if (action === "create_order") {
      const { partyName, distributorName, totalAmount, paidAmount, status, itemsCount } = body;
      if (!partyName || !totalAmount) {
        return NextResponse.json(
          { success: false, error: "Party name and Total Amount are required" },
          { status: 400 }
        );
      }

      const id = `ord_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 6)}`;
      const orderNumber = `ORD-${new Date().getFullYear()}-${Math.floor(1000 + Math.random() * 9000)}`;

      const rows = await sql`
        INSERT INTO orders (
          id,
          company_id,
          order_number,
          party_name,
          distributor_name,
          items_count,
          total_amount,
          paid_amount,
          status,
          created_at
        ) VALUES (
          ${id},
          ${companyId},
          ${orderNumber},
          ${partyName},
          ${distributorName || "Field Agent"},
          ${itemsCount || 1},
          ${Number(totalAmount)},
          ${Number(paidAmount || 0)},
          ${status || "Pending"},
          NOW()
        ) RETURNING *;
      `;

      return NextResponse.json({
        success: true,
        message: "Order placed and saved to database successfully.",
        order: rows[0],
      });
    }

    // 2. Record Collection / Payment
    if (action === "record_collection") {
      const { orderId, amount, partyName } = body;
      if (!amount) {
        return NextResponse.json(
          { success: false, error: "Collection amount is required" },
          { status: 400 }
        );
      }

      if (orderId) {
        const rows = await sql`
          UPDATE orders
          SET paid_amount = paid_amount + ${Number(amount)}
          WHERE id = ${orderId} AND company_id = ${companyId}
          RETURNING *;
        `;
        return NextResponse.json({
          success: true,
          message: "Payment collection recorded against order.",
          order: rows[0],
        });
      }

      // If no specific order selected, find an order with outstanding balance or create collection order record
      const rows = await sql`
        INSERT INTO orders (
          id,
          company_id,
          order_number,
          party_name,
          distributor_name,
          items_count,
          total_amount,
          paid_amount,
          status,
          created_at
        ) VALUES (
          ${`col_${Date.now().toString(36)}`},
          ${companyId},
          ${`REC-${new Date().getFullYear()}-${Math.floor(1000 + Math.random() * 9000)}`},
          ${partyName || "Direct Khata Counter"},
          'Headquarters Cashier',
          1,
          ${Number(amount)},
          ${Number(amount)},
          'Delivered',
          NOW()
        ) RETURNING *;
      `;

      return NextResponse.json({
        success: true,
        message: "Khata settlement collection recorded successfully.",
        order: rows[0],
      });
    }

    // 3. Add Product SKU
    if (action === "create_product") {
      const { name, sku, category, unitPrice, stockQuantity } = body;
      if (!name || !unitPrice) {
        return NextResponse.json(
          { success: false, error: "Product name and Unit Price are required" },
          { status: 400 }
        );
      }

      const id = `prod_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 6)}`;
      const prodSku = sku || `SKU-${Date.now().toString(36).toUpperCase().slice(-6)}`;

      const rows = await sql`
        INSERT INTO products (
          id,
          company_id,
          name,
          sku,
          category,
          unit_price,
          stock_quantity,
          is_active
        ) VALUES (
          ${id},
          ${companyId},
          ${name},
          ${prodSku},
          ${category || "General SKU"},
          ${Number(unitPrice)},
          ${Number(stockQuantity || 0)},
          true
        ) RETURNING *;
      `;

      return NextResponse.json({
        success: true,
        message: "Product SKU added to catalog successfully.",
        product: rows[0],
      });
    }

    // 4. Default: Generate Distributor Invite Token
    const { territoryName, distributorName, phone } = body;
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
        ${territoryName || "Central Commercial Zone"},
        ${distributorName || null},
        ${phone || null},
        false
      ) RETURNING *;
    `;

    return NextResponse.json({
      success: true,
      message: "Distributor token generated successfully.",
      token: rows[0],
    });
  } catch (error: any) {
    return NextResponse.json(
      { success: false, error: error.message },
      { status: 500 }
    );
  }
}
