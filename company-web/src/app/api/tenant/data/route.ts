import { NextRequest, NextResponse } from "next/server";
import {
  sql,
  ensureAppSchema,
  getCachedTenantByEmail,
  setCachedTenantByEmail,
  fetchTenantDashboardPayload,
} from "@/lib/neon/db";
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

// GET /api/tenant/data?companyId=...&slug=...
export async function GET(req: NextRequest) {
  try {
    const [, sessionEmail] = await Promise.all([
      ensureAppSchema(),
      getAuthenticatedUserEmail(req),
    ]);

    if (!sessionEmail) {
      return NextResponse.json(
        { success: false, error: "Unauthorized: Please sign in." },
        { status: 401 }
      );
    }

    // Resolve company strictly owned by the signed-in user's email (with fast cache)
    let company = getCachedTenantByEmail(sessionEmail);
    if (!company) {
      const compRows = await sql`
        SELECT * FROM companies
        WHERE LOWER(admin_email) = ${sessionEmail}
        LIMIT 1;
      `;
      company = compRows.length > 0 ? compRows[0] : null;
      if (company) {
        setCachedTenantByEmail(sessionEmail, company);
      }
    }

    if (!company) {
      return NextResponse.json({
        success: true,
        hasAccess: false,
        isCustomTenant: false,
        data: null,
      });
    }

    const payload = await fetchTenantDashboardPayload(company.id);

    return NextResponse.json({
      success: true,
      hasAccess: true,
      isCustomTenant: true,
      company,
      ...payload,
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
    const [, sessionEmail, body] = await Promise.all([
      ensureAppSchema(),
      getAuthenticatedUserEmail(req),
      req.json().catch(() => ({})),
    ]);

    if (!sessionEmail) {
      return NextResponse.json(
        { success: false, error: "Unauthorized: Please sign in." },
        { status: 401 }
      );
    }

    let company = getCachedTenantByEmail(sessionEmail);
    if (!company) {
      const compRows = await sql`
        SELECT * FROM companies
        WHERE LOWER(admin_email) = ${sessionEmail}
        LIMIT 1;
      `;
      if (compRows.length === 0) {
        return NextResponse.json(
          { success: false, error: "No tenant company found for your account." },
          { status: 403 }
        );
      }
      company = compRows[0];
      setCachedTenantByEmail(sessionEmail, company);
    }

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
        ) RETURNING
          id,
          order_number as "orderNumber",
          party_name as "partyName",
          distributor_name as "distributorName",
          items_count as "itemsCount",
          total_amount as "totalAmount",
          paid_amount as "paidAmount",
          status,
          created_at as "date";
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
          RETURNING
            id,
            order_number as "orderNumber",
            party_name as "partyName",
            distributor_name as "distributorName",
            items_count as "itemsCount",
            total_amount as "totalAmount",
            paid_amount as "paidAmount",
            status,
            created_at as "date";
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
        ) RETURNING
          id,
          order_number as "orderNumber",
          party_name as "partyName",
          distributor_name as "distributorName",
          items_count as "itemsCount",
          total_amount as "totalAmount",
          paid_amount as "paidAmount",
          status,
          created_at as "date";
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

      const validSizes = Array.isArray(sizes)
        ? sizes.filter((s: any) => s && s.label && s.label.trim())
        : [];

      const sizeInsertPromises = validSizes.map((s: any, i: number) => {
        const sizeId = `size_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 6)}_${i}`;
        const sPrice = Number(s.price || 0);
        const sDiscount = Number(s.discountPercentage || 0);
        const sFinal = s.finalPrice !== undefined && s.finalPrice !== null
          ? Number(s.finalPrice)
          : Number((sPrice * (1 - sDiscount / 100)).toFixed(2));
        const sCost = s.costPrice !== undefined && s.costPrice !== null && s.costPrice !== ""
          ? Number(s.costPrice)
          : null;

        return sql`
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
          ) RETURNING
            id,
            product_id as "productId",
            label,
            price,
            discount_percentage as "discountPercentage",
            final_price as "finalPrice",
            cost_price as "costPrice",
            sort_order as "sortOrder";
        `;
      });

      const [rows, ...insertedSizeRows] = await Promise.all([
        sql`
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
          ) RETURNING
            id,
            name,
            sku,
            category,
            unit,
            description,
            image_url as "imageUrl",
            retail_price as "retailPrice",
            unit_price as "unitPrice",
            discount_percentage as "discountPercentage",
            final_price as "finalPrice",
            cost_price as "costPrice",
            stock_quantity as "stockQuantity",
            status,
            is_active as "isActive",
            created_at as "createdAt";
        `,
        ...sizeInsertPromises,
      ]);

      const createdProduct = {
        ...rows[0],
        sizes: insertedSizeRows.map((r: any) => r[0]).filter(Boolean),
      };

      return NextResponse.json({
        success: true,
        message: "Product and size variants added to catalog successfully.",
        product: createdProduct,
      });
    }

    // 4. Delete Product and its sizes in parallel
    if (action === "delete_product") {
      const { productId } = body;
      if (!productId) {
        return NextResponse.json({ success: false, error: "productId is required" }, { status: 400 });
      }

      await Promise.all([
        sql`DELETE FROM product_sizes WHERE product_id = ${productId} AND company_id = ${companyId};`,
        sql`DELETE FROM products WHERE id = ${productId} AND company_id = ${companyId};`,
      ]);

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
      ) RETURNING
        id,
        token as "inviteToken",
        COALESCE(distributor_name, 'Pending Claim') as name,
        COALESCE(phone, 'Unassigned') as phone,
        COALESCE(territory_name, 'General Zone') as territory,
        is_claimed as "isClaimed",
        created_at as "createdAt";
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

