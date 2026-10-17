import { NextRequest, NextResponse } from "next/server";
import { sql } from "@/lib/neon/db";
import { stackServerApp } from "@/stack";

async function getAuthenticatedUserEmail(req: NextRequest): Promise<string | null> {
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
  return email || null;
}

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
      unit VARCHAR(64) DEFAULT 'unit',
      description TEXT,
      image_url TEXT,
      retail_price NUMERIC(12, 2) DEFAULT 0,
      unit_price NUMERIC(12, 2) DEFAULT 0,
      discount_percentage NUMERIC(5, 2) DEFAULT 0,
      final_price NUMERIC(12, 2) DEFAULT 0,
      cost_price NUMERIC(12, 2),
      stock_quantity INT DEFAULT 0,
      status VARCHAR(32) DEFAULT 'inStock',
      is_active BOOLEAN DEFAULT true,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
  `;

  // Safely ensure all columns exist if table was created in an earlier migration
  try {
    await sql`ALTER TABLE products ADD COLUMN IF NOT EXISTS unit VARCHAR(64) DEFAULT 'unit';`;
    await sql`ALTER TABLE products ADD COLUMN IF NOT EXISTS description TEXT;`;
    await sql`ALTER TABLE products ADD COLUMN IF NOT EXISTS image_url TEXT;`;
    await sql`ALTER TABLE products ADD COLUMN IF NOT EXISTS retail_price NUMERIC(12, 2) DEFAULT 0;`;
    await sql`ALTER TABLE products ADD COLUMN IF NOT EXISTS discount_percentage NUMERIC(5, 2) DEFAULT 0;`;
    await sql`ALTER TABLE products ADD COLUMN IF NOT EXISTS final_price NUMERIC(12, 2) DEFAULT 0;`;
    await sql`ALTER TABLE products ADD COLUMN IF NOT EXISTS cost_price NUMERIC(12, 2);`;
    await sql`ALTER TABLE products ADD COLUMN IF NOT EXISTS status VARCHAR(32) DEFAULT 'inStock';`;
  } catch (err: any) {
    // Ignore if column already exists
  }

  await sql`
    CREATE TABLE IF NOT EXISTS product_sizes (
      id VARCHAR(64) PRIMARY KEY,
      product_id VARCHAR(64) NOT NULL,
      company_id VARCHAR(64) NOT NULL,
      label VARCHAR(128) NOT NULL,
      price NUMERIC(12, 2) NOT NULL,
      discount_percentage NUMERIC(5, 2) DEFAULT 0,
      final_price NUMERIC(12, 2) NOT NULL,
      cost_price NUMERIC(12, 2),
      sort_order INT DEFAULT 0,
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

    const sessionEmail = await getAuthenticatedUserEmail(req);
    if (!sessionEmail) {
      return NextResponse.json(
        { success: false, error: "Unauthorized: Please sign in." },
        { status: 401 }
      );
    }

    // Resolve company strictly owned by the signed-in user's email
    const compRows = await sql`
      SELECT * FROM companies
      WHERE LOWER(admin_email) = ${sessionEmail}
      LIMIT 1;
    `;
    const company = compRows.length > 0 ? compRows[0] : null;

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

    // Fetch products with their sizes for THIS tenant
    const rawProducts = await sql`
      SELECT 
        id,
        name,
        sku,
        category,
        COALESCE(unit, 'unit') as unit,
        description,
        image_url as "imageUrl",
        COALESCE(retail_price, unit_price, 0) as "retailPrice",
        COALESCE(unit_price, retail_price, 0) as "unitPrice",
        COALESCE(discount_percentage, 0) as "discountPercentage",
        COALESCE(final_price, unit_price, 0) as "finalPrice",
        cost_price as "costPrice",
        COALESCE(stock_quantity, 0) as "stockQuantity",
        COALESCE(status, 'inStock') as status,
        is_active as "isActive",
        created_at as "createdAt"
      FROM products
      WHERE company_id = ${company.id}
      ORDER BY created_at DESC;
    `;

    const rawSizes = await sql`
      SELECT 
        id,
        product_id as "productId",
        label,
        price,
        COALESCE(discount_percentage, 0) as "discountPercentage",
        final_price as "finalPrice",
        cost_price as "costPrice",
        COALESCE(sort_order, 0) as "sortOrder"
      FROM product_sizes
      WHERE company_id = ${company.id}
      ORDER BY sort_order ASC, price ASC;
    `;

    const products = rawProducts.map((p: any) => ({
      ...p,
      sizes: rawSizes.filter((s: any) => s.productId === p.id),
    }));

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

// POST /api/tenant/data - Create orders, tokens, products with sizes, or record collections
export async function POST(req: NextRequest) {
  try {
    await ensureTables();
    const sessionEmail = await getAuthenticatedUserEmail(req);
    if (!sessionEmail) {
      return NextResponse.json(
        { success: false, error: "Unauthorized: Please sign in." },
        { status: 401 }
      );
    }

    const compRows = await sql`
      SELECT id, is_active, expires_at FROM companies
      WHERE LOWER(admin_email) = ${sessionEmail}
      LIMIT 1;
    `;
    if (compRows.length === 0) {
      return NextResponse.json(
        { success: false, error: "No tenant company found for your account." },
        { status: 403 }
      );
    }

    const company = compRows[0];
    const isExpired = company.expires_at && new Date(company.expires_at).getTime() < Date.now();
    if (company.is_active === false || isExpired) {
      return NextResponse.json(
        {
          success: false,
          error: isExpired
            ? "Your 1-month Free Tier has expired and your company account is deactivated."
            : "Your company tenant account is deactivated.",
        },
        { status: 403 }
      );
    }

    const body = await req.json();
    const { action } = body;
    const companyId = company.id as string;

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

    // 3. Add Product with optional Sizes / Variants
    if (action === "create_product") {
      const {
        name,
        sku,
        category,
        unit,
        description,
        imageUrl,
        retailPrice,
        unitPrice,
        discountPercentage,
        finalPrice,
        costPrice,
        stockQuantity,
        status,
        sizes,
      } = body;

      if (!name) {
        return NextResponse.json(
          { success: false, error: "Product name is required" },
          { status: 400 }
        );
      }

      const id = `prod_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 6)}`;
      const prodSku = sku && sku.trim().length > 0
        ? sku.trim().toUpperCase()
        : `SKU-${Date.now().toString(36).toUpperCase().slice(-6)}`;

      const baseRetail = Number(retailPrice ?? unitPrice ?? 0);
      const baseDiscount = Number(discountPercentage ?? 0);
      const calculatedFinal = finalPrice !== undefined && finalPrice !== null
        ? Number(finalPrice)
        : Number((baseRetail * (1 - baseDiscount / 100)).toFixed(2));
      const baseCost = costPrice !== undefined && costPrice !== null && costPrice !== ""
        ? Number(costPrice)
        : null;

      const rows = await sql`
        INSERT INTO products (
          id,
          company_id,
          name,
          sku,
          category,
          unit,
          description,
          image_url,
          retail_price,
          unit_price,
          discount_percentage,
          final_price,
          cost_price,
          stock_quantity,
          status,
          is_active,
          created_at
        ) VALUES (
          ${id},
          ${companyId},
          ${name.trim()},
          ${prodSku},
          ${category || "General"},
          ${unit || "unit"},
          ${description || null},
          ${imageUrl || null},
          ${baseRetail},
          ${baseRetail},
          ${baseDiscount},
          ${calculatedFinal},
          ${baseCost},
          ${Number(stockQuantity || 0)},
          ${status || "inStock"},
          true,
          NOW()
        ) RETURNING *;
      `;

      // Insert any size variants if provided
      if (Array.isArray(sizes) && sizes.length > 0) {
        for (let i = 0; i < sizes.length; i++) {
          const s = sizes[i];
          if (!s.label) continue;
          const sizeId = `size_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 6)}_${i}`;
          const sPrice = Number(s.price || 0);
          const sDiscount = Number(s.discountPercentage || 0);
          const sFinal = s.finalPrice !== undefined && s.finalPrice !== null
            ? Number(s.finalPrice)
            : Number((sPrice * (1 - sDiscount / 100)).toFixed(2));
          const sCost = s.costPrice !== undefined && s.costPrice !== null && s.costPrice !== ""
            ? Number(s.costPrice)
            : null;

          await sql`
            INSERT INTO product_sizes (
              id,
              product_id,
              company_id,
              label,
              price,
              discount_percentage,
              final_price,
              cost_price,
              sort_order,
              created_at
            ) VALUES (
              ${sizeId},
              ${id},
              ${companyId},
              ${s.label.trim()},
              ${sPrice},
              ${sDiscount},
              ${sFinal},
              ${sCost},
              ${i},
              NOW()
            );
          `;
        }
      }

      return NextResponse.json({
        success: true,
        message: "Product and size variants added to catalog successfully.",
        product: rows[0],
      });
    }

    // 4. Delete Product and its sizes
    if (action === "delete_product") {
      const { productId } = body;
      if (!productId) {
        return NextResponse.json({ success: false, error: "productId is required" }, { status: 400 });
      }

      await sql`DELETE FROM product_sizes WHERE product_id = ${productId} AND company_id = ${companyId};`;
      await sql`DELETE FROM products WHERE id = ${productId} AND company_id = ${companyId};`;

      return NextResponse.json({
        success: true,
        message: "Product removed from catalog.",
      });
    }

    // 5. Default: Generate Distributor Invite Token
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
