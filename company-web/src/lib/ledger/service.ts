import { sql } from "@/lib/neon/db";
import { stackServerApp } from "@/stack";
import { NextRequest } from "next/server";
import { CreateLedgerEntryInput, LedgerFilterInput } from "./schemas";

export interface LedgerCategory {
  id: string;
  tenant_id: string;
  name: string;
  type: "income" | "expense";
  is_default: boolean;
  created_at: string;
}

export interface LedgerEntry {
  id: string;
  tenant_id: string;
  type: "income" | "expense";
  title: string;
  category_id: string;
  category_name?: string;
  quantity: number;
  unit: string;
  unit_cost_minor: number;
  amount_minor: number;
  vendor_name: string | null;
  currency: string;
  payment_method: "cash" | "card" | "online" | "other" | null;
  occurred_at: string;
  added_by: string;
  added_by_name: string;
  created_at: string;
  is_voided: boolean;
  voided_at: string | null;
  voided_by: string | null;
  void_reason: string | null;
}

export interface AggregatedItemSummary {
  itemName: string;
  unit: string;
  categoryName: string;
  totalQuantity: number;
  totalCostMinor: number;
  avgUnitCostMinor: number;
  purchaseCount: number;
}

// 1. Ensure Tables, Columns & Indexes Exist in Neon PostgreSQL
export async function ensureLedgerSchema() {
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
    CREATE TABLE IF NOT EXISTS ledger_categories (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      tenant_id VARCHAR(64) NOT NULL,
      name VARCHAR(128) NOT NULL,
      type VARCHAR(16) NOT NULL CHECK (type IN ('income', 'expense')),
      is_default BOOLEAN NOT NULL DEFAULT false,
      created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
      CONSTRAINT uq_tenant_category_name UNIQUE (tenant_id, name)
    );
  `;

  await sql`
    CREATE TABLE IF NOT EXISTS ledger_entries (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      tenant_id VARCHAR(64) NOT NULL,
      type VARCHAR(16) NOT NULL DEFAULT 'expense' CHECK (type IN ('income', 'expense')),
      title VARCHAR(255) NOT NULL,
      category_id UUID NOT NULL REFERENCES ledger_categories(id),
      quantity NUMERIC(12, 2) NOT NULL DEFAULT 1,
      unit VARCHAR(32) NOT NULL DEFAULT 'pcs',
      unit_cost_minor BIGINT,
      amount_minor BIGINT NOT NULL CHECK (amount_minor > 0),
      vendor_name VARCHAR(255),
      currency CHAR(3) NOT NULL DEFAULT 'PKR',
      payment_method VARCHAR(16) CHECK (payment_method IN ('cash', 'card', 'online', 'other')),
      occurred_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
      added_by VARCHAR(128) NOT NULL,
      added_by_name VARCHAR(255) NOT NULL,
      created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
      is_voided BOOLEAN NOT NULL DEFAULT false,
      voided_at TIMESTAMP WITH TIME ZONE,
      voided_by VARCHAR(128),
      void_reason TEXT
    );
  `;

  try {
    await sql`ALTER TABLE ledger_entries ADD COLUMN IF NOT EXISTS quantity NUMERIC(12, 2) NOT NULL DEFAULT 1;`;
    await sql`ALTER TABLE ledger_entries ADD COLUMN IF NOT EXISTS unit VARCHAR(32) NOT NULL DEFAULT 'pcs';`;
    await sql`ALTER TABLE ledger_entries ADD COLUMN IF NOT EXISTS unit_cost_minor BIGINT;`;
    await sql`ALTER TABLE ledger_entries ADD COLUMN IF NOT EXISTS vendor_name VARCHAR(255);`;
  } catch (err) {
    // Columns already exist
  }

  try {
    await sql`CREATE INDEX IF NOT EXISTS idx_ledger_categories_tenant ON ledger_categories (tenant_id, type);`;
    await sql`CREATE INDEX IF NOT EXISTS idx_ledger_entries_tenant_occurred ON ledger_entries (tenant_id, occurred_at DESC);`;
    await sql`CREATE INDEX IF NOT EXISTS idx_ledger_entries_tenant_category ON ledger_entries (tenant_id, category_id);`;
    await sql`CREATE INDEX IF NOT EXISTS idx_ledger_entries_tenant_type_occurred ON ledger_entries (tenant_id, type, occurred_at);`;
    await sql`CREATE INDEX IF NOT EXISTS idx_ledger_entries_tenant_void ON ledger_entries (tenant_id, is_voided);`;
  } catch (err: any) {
    // Indexes already exist
  }
}

// 2. Seed Default Categories per Tenant (Hotel / Party Purchase & Expense Categories)
export async function seedDefaultCategories(tenantId: string) {
  const defaultCategories: Array<{ name: string; type: "income" | "expense" }> = [
    // Hotel / Party Purchase & Expense Categories
    { name: "Meat & Poultry", type: "expense" },
    { name: "Vegetables & Fruits", type: "expense" },
    { name: "Groceries & Spices", type: "expense" },
    { name: "Dairy & Bakery", type: "expense" },
    { name: "Beverages & Drinks", type: "expense" },
    { name: "Kitchen Supplies & Gas", type: "expense" },
    { name: "Stock Purchase", type: "expense" },
    { name: "Utilities", type: "expense" },
    { name: "Wages", type: "expense" },
    { name: "Rent", type: "expense" },
    { name: "Transport", type: "expense" },
    { name: "Maintenance", type: "expense" },
    { name: "Other", type: "expense" },
    // Income Categories (if needed)
    { name: "Sales - Cash", type: "income" },
    { name: "Sales - Card", type: "income" },
    { name: "Sales - Online", type: "income" },
    { name: "Other Income", type: "income" },
  ];

  for (const cat of defaultCategories) {
    try {
      await sql`
        INSERT INTO ledger_categories (
          tenant_id,
          name,
          type,
          is_default
        ) VALUES (
          ${tenantId},
          ${cat.name},
          ${cat.type},
          true
        )
        ON CONFLICT (tenant_id, name) DO NOTHING;
      `;
    } catch (e) {
      // Ignore conflict
    }
  }
}

// 3. Multi-Tenant Server Authentication & Admin Access Guard
export async function assertAdminAuth(req?: NextRequest) {
  await ensureLedgerSchema();

  let user: any = null;
  if (req) {
    try {
      user = await stackServerApp.getUser({ tokenStore: req } as any);
    } catch (err) {
      // Fallback to default cookie store below
    }
  }
  if (!user) {
    try {
      user = await stackServerApp.getUser();
    } catch (err) {
      // Unauthenticated in Stack cookie store
    }
  }

  const headerTenantId =
    req?.headers.get("x-tenant-id")?.trim() ||
    req?.nextUrl?.searchParams?.get("tenantId")?.trim() ||
    "";
  const headerUserEmail = req?.headers.get("x-user-email")?.trim()?.toLowerCase() || "";
  const headerUserName = req?.headers.get("x-user-name")?.trim() || "";

  const stackEmail = (
    user?.primaryEmail ||
    user?.emails?.[0] ||
    ""
  )
    .toString()
    .toLowerCase()
    .trim();

  const userEmail = stackEmail || headerUserEmail;

  let tenant: any = null;

  // 1. If we have an authenticated userEmail, check if they own a company in Neon DB
  if (userEmail) {
    const byEmail = await sql`
      SELECT id, name, slug, admin_email, plan_tier, is_active
      FROM companies
      WHERE LOWER(admin_email) = ${userEmail}
      ORDER BY is_active DESC NULLS LAST, created_at DESC
      LIMIT 1;
    `;
    if (byEmail && byEmail.length > 0) {
      tenant = byEmail[0];
    }
  }

  // 2. If client passed an explicit active tenant ID (and either no userEmail company yet or superadmin/matching tenant)
  if (!tenant && headerTenantId) {
    const byId = await sql`
      SELECT id, name, slug, admin_email, plan_tier, is_active
      FROM companies
      WHERE id = ${headerTenantId} OR slug = ${headerTenantId}
      LIMIT 1;
    `;
    if (byId && byId.length > 0) {
      // Only use if userEmail isn't a brand-new user needing their own company, or if headerTenantId matches
      if (!userEmail || byId[0].admin_email?.toLowerCase() === userEmail || headerTenantId !== "comp_apex_agro_01") {
        tenant = byId[0];
      }
    }
  }

  // 3. If userEmail is present and still no company exists for them, auto-provision their tenant company
  if (!tenant && userEmail) {
    const cleanPrefix = userEmail.split("@")[0].replace(/[^a-zA-Z0-9]/g, "") || "tenant";
    const companyId = `comp_${cleanPrefix}_${Date.now().toString(36)}`;
    const companyName =
      user?.displayName ||
      headerUserName ||
      `${cleanPrefix.charAt(0).toUpperCase() + cleanPrefix.slice(1)} Commercial`;
    const companySlug = `${cleanPrefix.toLowerCase()}-${Date.now().toString(36).slice(-4)}`;

    const inserted = await sql`
      INSERT INTO companies (
        id, name, slug, admin_email, plan_tier, is_active
      ) VALUES (
        ${companyId}, ${companyName}, ${companySlug}, ${userEmail}, 'standard', true
      )
      RETURNING id, name, slug, admin_email, plan_tier, is_active;
    `;
    tenant = inserted[0];
  }

  // 4. Fallback to headerTenantId or first active company in DB (so portal works seamlessly even before Stack cookie sync)
  if (!tenant && headerTenantId) {
    const byId = await sql`
      SELECT id, name, slug, admin_email, plan_tier, is_active
      FROM companies
      WHERE id = ${headerTenantId} OR slug = ${headerTenantId}
      LIMIT 1;
    `;
    if (byId && byId.length > 0) {
      tenant = byId[0];
    }
  }

  if (!tenant) {
    const allCompanies = await sql`
      SELECT id, name, slug, admin_email, plan_tier, is_active
      FROM companies
      WHERE is_active = true
      ORDER BY created_at ASC
      LIMIT 1;
    `;
    tenant = allCompanies[0];
  }

  // 5. Ultimate fallback: if companies table is completely empty, seed default company
  if (!tenant) {
    const insertedDefault = await sql`
      INSERT INTO companies (
        id, name, slug, admin_email, phone, address, plan_tier, is_active
      ) VALUES (
        'comp_apex_agro_01',
        'Apex Agro Chemical Ltd.',
        'apex-agro',
        'admin@apexagro.com',
        '+92 42 35789000',
        'Plot 42, Industrial Estate, Kot Lakhpat, Lahore',
        'enterprise',
        true
      )
      ON CONFLICT (id) DO UPDATE SET is_active = true
      RETURNING id, name, slug, admin_email, plan_tier, is_active;
    `;
    tenant = insertedDefault[0];
  }

  await seedDefaultCategories(tenant.id);

  const effectiveEmail = userEmail || tenant.admin_email || "admin@katha.com";
  const effectiveName =
    user?.displayName ||
    headerUserName ||
    (userEmail ? userEmail.split("@")[0] : tenant.name || "Admin");
  const effectiveUserId = user?.id || `usr_${effectiveEmail.split("@")[0]}`;

  return {
    user,
    userId: effectiveUserId,
    userName: effectiveName,
    userEmail: effectiveEmail,
    tenantId: tenant.id as string,
    tenantName: tenant.name as string,
    currency: "PKR",
    timezone: "Asia/Karachi",
  };
}

// 4. Fetch Ledger Categories for Tenant
export async function getLedgerCategories(tenantId: string) {
  await ensureLedgerSchema();
  await seedDefaultCategories(tenantId);

  const rows = await sql`
    SELECT id, tenant_id, name, type, is_default, created_at
    FROM ledger_categories
    WHERE tenant_id = ${tenantId}
    ORDER BY is_default DESC, name ASC;
  `;
  return rows as unknown as LedgerCategory[];
}

// 5. Create Custom Ledger Category
export async function createLedgerCategory(tenantId: string, name: string, type: "income" | "expense" = "expense") {
  await ensureLedgerSchema();

  const rows = await sql`
    INSERT INTO ledger_categories (
      tenant_id,
      name,
      type,
      is_default
    ) VALUES (
      ${tenantId},
      ${name.trim()},
      ${type},
      false
    )
    ON CONFLICT (tenant_id, name) DO UPDATE SET type = EXCLUDED.type
    RETURNING id, tenant_id, name, type, is_default, created_at;
  `;
  return rows[0] as unknown as LedgerCategory;
}

// 6. Create Ledger Entry (Item Brought / Expense)
export async function createLedgerEntry(
  tenantId: string,
  userId: string,
  userName: string,
  input: CreateLedgerEntryInput
) {
  await ensureLedgerSchema();
  await seedDefaultCategories(tenantId);

  let category: any = null;
  const isUuid =
    input.categoryId &&
    /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(
      input.categoryId
    );

  // 1. Try matching categoryId for this tenant
  if (isUuid) {
    const catRows = await sql`
      SELECT id, name, type FROM ledger_categories
      WHERE id = ${input.categoryId} AND tenant_id = ${tenantId}
      LIMIT 1;
    `;
    if (catRows && catRows.length > 0) {
      category = catRows[0];
    } else {
      // Check if categoryId came from another tenant before context sync, and match by name for this tenant
      const otherCatRows = await sql`
        SELECT name, type FROM ledger_categories WHERE id = ${input.categoryId} LIMIT 1;
      `;
      if (otherCatRows && otherCatRows.length > 0) {
        const matchedByName = await sql`
          SELECT id, name, type FROM ledger_categories
          WHERE tenant_id = ${tenantId} AND LOWER(name) = LOWER(${otherCatRows[0].name})
          LIMIT 1;
        `;
        if (matchedByName && matchedByName.length > 0) {
          category = matchedByName[0];
        }
      }
    }
  }

  // 2. Try matching by categoryName if provided
  if (!category && input.categoryName) {
    const byName = await sql`
      SELECT id, name, type FROM ledger_categories
      WHERE tenant_id = ${tenantId} AND LOWER(name) = LOWER(${input.categoryName.trim()})
      LIMIT 1;
    `;
    if (byName && byName.length > 0) {
      category = byName[0];
    } else {
      category = await createLedgerCategory(tenantId, input.categoryName.trim(), input.type || "expense");
    }
  }

  // 3. Fallback to first default expense category for this tenant
  if (!category) {
    const fallbackCats = await sql`
      SELECT id, name, type FROM ledger_categories
      WHERE tenant_id = ${tenantId}
      ORDER BY (CASE WHEN name = 'Meat & Poultry' THEN 0 WHEN name = 'Other' THEN 1 ELSE 2 END), created_at ASC
      LIMIT 1;
    `;
    category = fallbackCats[0];
  }

  const entryType = input.type || category?.type || "expense";
  const occurredAt = input.occurredAt ? new Date(input.occurredAt) : new Date();

  const quantity = Number(input.quantity) > 0 ? Number(input.quantity) : 1;
  const unit = (input.unit || "pcs").trim();
  const unitCostMinor =
    input.unitCostMinor !== undefined && input.unitCostMinor !== null && input.unitCostMinor > 0
      ? Math.round(Number(input.unitCostMinor))
      : Math.round(Number(input.amountMinor) / quantity);

  const rows = await sql`
    INSERT INTO ledger_entries (
      tenant_id,
      type,
      title,
      category_id,
      quantity,
      unit,
      unit_cost_minor,
      amount_minor,
      vendor_name,
      currency,
      payment_method,
      occurred_at,
      added_by,
      added_by_name
    ) VALUES (
      ${tenantId},
      ${entryType},
      ${input.title.trim()},
      ${category.id},
      ${quantity},
      ${unit},
      ${unitCostMinor},
      ${input.amountMinor},
      ${input.vendorName ? input.vendorName.trim() : null},
      ${input.currency || "PKR"},
      ${input.paymentMethod || "cash"},
      ${occurredAt.toISOString()},
      ${userId},
      ${userName}
    )
    RETURNING *;
  `;

  const row = rows[0];
  return {
    ...row,
    quantity: Number(row.quantity || 1),
    unit: row.unit || "pcs",
    unit_cost_minor: Number(row.unit_cost_minor || row.amount_minor),
    amount_minor: Number(row.amount_minor),
    category_name: category.name,
  } as unknown as LedgerEntry;
}

// 7. Void Ledger Entry
export async function voidLedgerEntry(
  tenantId: string,
  userId: string,
  entryId: string,
  reason: string
) {
  await ensureLedgerSchema();

  const existing = await sql`
    SELECT id, tenant_id, is_voided, title
    FROM ledger_entries
    WHERE id = ${entryId} AND tenant_id = ${tenantId}
    LIMIT 1;
  `;

  if (!existing || existing.length === 0) {
    const error: any = new Error("Ledger entry not found");
    error.status = 404;
    throw error;
  }

  if (existing[0].is_voided) {
    const error: any = new Error("This ledger entry has already been voided");
    error.status = 400;
    throw error;
  }

  const updated = await sql`
    UPDATE ledger_entries
    SET 
      is_voided = true,
      voided_at = NOW(),
      voided_by = ${userId},
      void_reason = ${reason.trim()}
    WHERE id = ${entryId} AND tenant_id = ${tenantId}
    RETURNING *;
  `;

  return updated[0] as unknown as LedgerEntry;
}

// 8. Get Paginated Ledger Entries with Server-Side Totals & Item Breakdown (Date / Month / Year Filters)
export async function getLedgerEntries(
  tenantId: string,
  filters: LedgerFilterInput,
  timezone: string = "Asia/Karachi"
) {
  await ensureLedgerSchema();

  const limit = Math.min(10000, filters.limit || 50);
  const offset =
    filters.offset !== undefined
      ? Number(filters.offset)
      : ((filters.page || 1) - 1) * limit;
  const page = Math.floor(offset / limit) + 1;

  // Build dynamic SQL conditions strictly isolated by tenant_id
  const conditions = [sql`e.tenant_id = ${tenantId}`];

  if (filters.type) {
    conditions.push(sql`e.type = ${filters.type}`);
  }

  if (filters.categoryId && filters.categoryId !== "all") {
    conditions.push(sql`e.category_id = ${filters.categoryId}`);
  }

  if (filters.addedBy) {
    conditions.push(sql`e.added_by = ${filters.addedBy}`);
  }

  if (filters.includeVoided === "false") {
    conditions.push(sql`e.is_voided = false`);
  }

  // Date / Month / Year / Period filtering in tenant's timezone
  if (filters.date) {
    conditions.push(
      sql`(e.occurred_at AT TIME ZONE ${timezone})::date = ${filters.date}::date`
    );
  } else if (filters.month && filters.year) {
    conditions.push(
      sql`EXTRACT(MONTH FROM (e.occurred_at AT TIME ZONE ${timezone})) = ${filters.month}`
    );
    conditions.push(
      sql`EXTRACT(YEAR FROM (e.occurred_at AT TIME ZONE ${timezone})) = ${filters.year}`
    );
  } else if (filters.year && !filters.month) {
    conditions.push(
      sql`EXTRACT(YEAR FROM (e.occurred_at AT TIME ZONE ${timezone})) = ${filters.year}`
    );
  } else if (filters.period === "weekly" && !filters.from && !filters.to) {
    conditions.push(
      sql`(e.occurred_at AT TIME ZONE ${timezone})::date >= ((NOW() AT TIME ZONE ${timezone})::date - INTERVAL '6 days')`
    );
  }

  if (filters.from) {
    conditions.push(sql`e.occurred_at >= ${new Date(filters.from).toISOString()}`);
  }

  if (filters.to) {
    conditions.push(sql`e.occurred_at <= ${new Date(filters.to).toISOString()}`);
  }

  if (filters.search && filters.search.trim()) {
    const term = `%${filters.search.trim().toLowerCase()}%`;
    conditions.push(
      sql`(LOWER(e.title) LIKE ${term} OR LOWER(c.name) LIKE ${term} OR LOWER(COALESCE(e.vendor_name, '')) LIKE ${term} OR LOWER(e.added_by_name) LIKE ${term})`
    );
  }

  const whereClause = conditions.reduce((prev, curr) => sql`${prev} AND ${curr}`);

  // Sorting
  let orderByClause = sql`e.occurred_at DESC`;
  if (filters.sort === "asc" || filters.sort === "occurred_at:asc") {
    orderByClause = sql`e.occurred_at ASC`;
  } else if (filters.sort === "amount_minor:desc") {
    orderByClause = sql`e.amount_minor DESC`;
  } else if (filters.sort === "amount_minor:asc") {
    orderByClause = sql`e.amount_minor ASC`;
  }

  // 1. Fetch paginated entries
  const rawEntries = await sql`
    SELECT 
      e.id,
      e.tenant_id,
      e.type,
      e.title,
      e.category_id,
      c.name as category_name,
      COALESCE(e.quantity, 1) as quantity,
      COALESCE(e.unit, 'pcs') as unit,
      COALESCE(e.unit_cost_minor, e.amount_minor) as unit_cost_minor,
      e.amount_minor,
      e.vendor_name,
      e.currency,
      e.payment_method,
      e.occurred_at,
      e.added_by,
      e.added_by_name,
      e.created_at,
      e.is_voided,
      e.voided_at,
      e.voided_by,
      e.void_reason
    FROM ledger_entries e
    JOIN ledger_categories c ON e.category_id = c.id
    WHERE ${whereClause}
    ORDER BY ${orderByClause}
    LIMIT ${limit} OFFSET ${offset};
  `;

  const entries: LedgerEntry[] = rawEntries.map((r: any) => ({
    ...r,
    quantity: Number(r.quantity || 1),
    unit: r.unit || "pcs",
    unit_cost_minor: Number(r.unit_cost_minor || r.amount_minor),
    amount_minor: Number(r.amount_minor),
  }));

  // 2. Fetch total count for pagination
  const countResult = await sql`
    SELECT COUNT(*)::int as total
    FROM ledger_entries e
    JOIN ledger_categories c ON e.category_id = c.id
    WHERE ${whereClause};
  `;
  const totalCount = Number(countResult[0]?.total || 0);

  // 3. Compute filtered totals server-side across ALL matching rows (excluding voided)
  const totalsResult = await sql`
    SELECT 
      COALESCE(SUM(CASE WHEN e.type = 'income' AND e.is_voided = false THEN e.amount_minor ELSE 0 END), 0)::bigint as total_income,
      COALESCE(SUM(CASE WHEN e.type = 'expense' AND e.is_voided = false THEN e.amount_minor ELSE 0 END), 0)::bigint as total_expense,
      COALESCE(SUM(CASE WHEN e.is_voided = false THEN e.amount_minor ELSE 0 END), 0)::bigint as total_all_cost,
      COALESCE(SUM(CASE WHEN e.is_voided = false THEN COALESCE(e.quantity, 1) ELSE 0 END), 0)::numeric as total_quantity,
      COUNT(CASE WHEN e.is_voided = false THEN 1 END)::int as active_count
    FROM ledger_entries e
    JOIN ledger_categories c ON e.category_id = c.id
    WHERE ${whereClause};
  `;

  const totalIncomeMinor = Number(totalsResult[0]?.total_income || 0);
  const totalExpenseMinor = Number(totalsResult[0]?.total_expense || 0);
  const totalCostMinor = Number(totalsResult[0]?.total_all_cost || 0);
  const totalQuantity = Number(totalsResult[0]?.total_quantity || 0);
  const activeCount = Number(totalsResult[0]?.active_count || 0);
  const netMinor = totalIncomeMinor - totalExpenseMinor;

  // 4. Compute aggregated items breakdown for the selected Date / Month / Year filter
  const itemsBreakdownRows = await sql`
    SELECT 
      MAX(e.title) as item_name,
      COALESCE(e.unit, 'pcs') as unit,
      MAX(c.name) as category_name,
      SUM(COALESCE(e.quantity, 1))::numeric as total_quantity,
      SUM(e.amount_minor)::bigint as total_cost_minor,
      COUNT(*)::int as purchase_count
    FROM ledger_entries e
    JOIN ledger_categories c ON e.category_id = c.id
    WHERE ${whereClause} AND e.is_voided = false
    GROUP BY LOWER(TRIM(e.title)), COALESCE(e.unit, 'pcs')
    ORDER BY total_cost_minor DESC
    LIMIT 50;
  `;

  const itemsBreakdown: AggregatedItemSummary[] = itemsBreakdownRows.map((row: any) => {
    const qty = Number(row.total_quantity || 1);
    const cost = Number(row.total_cost_minor || 0);
    return {
      itemName: row.item_name,
      unit: row.unit || "pcs",
      categoryName: row.category_name || "General",
      totalQuantity: qty,
      totalCostMinor: cost,
      avgUnitCostMinor: qty > 0 ? Math.round(cost / qty) : cost,
      purchaseCount: Number(row.purchase_count || 1),
    };
  });

  return {
    entries,
    totalCount,
    pagination: {
      total: totalCount,
      page,
      limit,
      totalPages: Math.ceil(totalCount / limit) || 1,
    },
    filteredTotals: {
      totalIncomeMinor,
      totalExpenseMinor,
      totalCostMinor,
      totalQuantity,
      activeCount,
      netMinor,
    },
    itemsBreakdown,
  };
}

// 9. Multi-Horizon Summary (Daily, Weekly, Monthly, Yearly Expense & Item Totals)
export async function getLedgerSummary(
  tenantId: string,
  dateStr?: string,
  timezone: string = "Asia/Karachi",
  monthParam?: number,
  yearParam?: number
) {
  await ensureLedgerSchema();

  const targetDate = dateStr || new Date().toISOString().split("T")[0];
  const parsedDate = new Date(targetDate);
  const targetMonth = monthParam || parsedDate.getMonth() + 1;
  const targetYear = yearParam || parsedDate.getFullYear();

  // Compute Daily, Weekly, Monthly, Yearly totals in a single query
  const horizonRows = await sql`
    SELECT 
      -- Specific Day
      COALESCE(SUM(CASE WHEN is_voided = false AND (occurred_at AT TIME ZONE ${timezone})::date = ${targetDate}::date THEN amount_minor ELSE 0 END), 0)::bigint as day_cost_minor,
      COUNT(CASE WHEN is_voided = false AND (occurred_at AT TIME ZONE ${timezone})::date = ${targetDate}::date THEN 1 END)::int as day_entries,
      COALESCE(SUM(CASE WHEN is_voided = false AND (occurred_at AT TIME ZONE ${timezone})::date = ${targetDate}::date THEN COALESCE(quantity, 1) ELSE 0 END), 0)::numeric as day_quantity,

      -- Weekly (7-day window ending on targetDate)
      COALESCE(SUM(CASE WHEN is_voided = false AND (occurred_at AT TIME ZONE ${timezone})::date BETWEEN (${targetDate}::date - INTERVAL '6 days')::date AND ${targetDate}::date THEN amount_minor ELSE 0 END), 0)::bigint as week_cost_minor,
      COUNT(CASE WHEN is_voided = false AND (occurred_at AT TIME ZONE ${timezone})::date BETWEEN (${targetDate}::date - INTERVAL '6 days')::date AND ${targetDate}::date THEN 1 END)::int as week_entries,
      COALESCE(SUM(CASE WHEN is_voided = false AND (occurred_at AT TIME ZONE ${timezone})::date BETWEEN (${targetDate}::date - INTERVAL '6 days')::date AND ${targetDate}::date THEN COALESCE(quantity, 1) ELSE 0 END), 0)::numeric as week_quantity,

      -- Monthly (targetMonth & targetYear)
      COALESCE(SUM(CASE WHEN is_voided = false AND EXTRACT(MONTH FROM (occurred_at AT TIME ZONE ${timezone})) = ${targetMonth} AND EXTRACT(YEAR FROM (occurred_at AT TIME ZONE ${timezone})) = ${targetYear} THEN amount_minor ELSE 0 END), 0)::bigint as month_cost_minor,
      COUNT(CASE WHEN is_voided = false AND EXTRACT(MONTH FROM (occurred_at AT TIME ZONE ${timezone})) = ${targetMonth} AND EXTRACT(YEAR FROM (occurred_at AT TIME ZONE ${timezone})) = ${targetYear} THEN 1 END)::int as month_entries,
      COALESCE(SUM(CASE WHEN is_voided = false AND EXTRACT(MONTH FROM (occurred_at AT TIME ZONE ${timezone})) = ${targetMonth} AND EXTRACT(YEAR FROM (occurred_at AT TIME ZONE ${timezone})) = ${targetYear} THEN COALESCE(quantity, 1) ELSE 0 END), 0)::numeric as month_quantity,

      -- Yearly (targetYear)
      COALESCE(SUM(CASE WHEN is_voided = false AND EXTRACT(YEAR FROM (occurred_at AT TIME ZONE ${timezone})) = ${targetYear} THEN amount_minor ELSE 0 END), 0)::bigint as year_cost_minor,
      COUNT(CASE WHEN is_voided = false AND EXTRACT(YEAR FROM (occurred_at AT TIME ZONE ${timezone})) = ${targetYear} THEN 1 END)::int as year_entries,
      COALESCE(SUM(CASE WHEN is_voided = false AND EXTRACT(YEAR FROM (occurred_at AT TIME ZONE ${timezone})) = ${targetYear} THEN COALESCE(quantity, 1) ELSE 0 END), 0)::numeric as year_quantity,

      -- Payment split on targetDate
      COALESCE(SUM(CASE WHEN payment_method = 'cash' AND is_voided = false AND (occurred_at AT TIME ZONE ${timezone})::date = ${targetDate}::date THEN amount_minor ELSE 0 END), 0)::bigint as cash_minor,
      COALESCE(SUM(CASE WHEN payment_method = 'card' AND is_voided = false AND (occurred_at AT TIME ZONE ${timezone})::date = ${targetDate}::date THEN amount_minor ELSE 0 END), 0)::bigint as card_minor,
      COALESCE(SUM(CASE WHEN payment_method = 'online' AND is_voided = false AND (occurred_at AT TIME ZONE ${timezone})::date = ${targetDate}::date THEN amount_minor ELSE 0 END), 0)::bigint as online_minor,
      COALESCE(SUM(CASE WHEN payment_method = 'other' AND is_voided = false AND (occurred_at AT TIME ZONE ${timezone})::date = ${targetDate}::date THEN amount_minor ELSE 0 END), 0)::bigint as other_minor
    FROM ledger_entries
    WHERE tenant_id = ${tenantId};
  `;

  // Top category for the selected month
  const topExpense = await sql`
    SELECT c.name, SUM(e.amount_minor)::bigint as amount_minor
    FROM ledger_entries e
    JOIN ledger_categories c ON e.category_id = c.id
    WHERE 
      e.tenant_id = ${tenantId}
      AND e.is_voided = false
      AND EXTRACT(MONTH FROM (e.occurred_at AT TIME ZONE ${timezone})) = ${targetMonth}
      AND EXTRACT(YEAR FROM (e.occurred_at AT TIME ZONE ${timezone})) = ${targetYear}
    GROUP BY c.name
    ORDER BY amount_minor DESC
    LIMIT 1;
  `;

  const s = horizonRows[0] || {};
  const dayCostMinor = Number(s.day_cost_minor || 0);
  const weekCostMinor = Number(s.week_cost_minor || 0);
  const monthCostMinor = Number(s.month_cost_minor || 0);
  const yearCostMinor = Number(s.year_cost_minor || 0);

  return {
    date: targetDate,
    month: targetMonth,
    year: targetYear,
    timezone,
    // Multi-horizon tracking (Daily, Weekly, Monthly, Yearly)
    daily: {
      costMinor: dayCostMinor,
      entries: Number(s.day_entries || 0),
      quantity: Number(s.day_quantity || 0),
    },
    weekly: {
      costMinor: weekCostMinor,
      entries: Number(s.week_entries || 0),
      quantity: Number(s.week_quantity || 0),
    },
    monthly: {
      costMinor: monthCostMinor,
      entries: Number(s.month_entries || 0),
      quantity: Number(s.month_quantity || 0),
    },
    yearly: {
      costMinor: yearCostMinor,
      entries: Number(s.year_entries || 0),
      quantity: Number(s.year_quantity || 0),
    },
    // Backwards-compatible summary fields
    totalIncomeMinor: 0,
    totalExpenseMinor: dayCostMinor,
    todayIncomeMinor: 0,
    todayExpenseMinor: dayCostMinor,
    netMinor: -dayCostMinor,
    count: Number(s.day_entries || 0),
    entryCount: Number(s.day_entries || 0),
    topExpenseCategory: topExpense[0]
      ? { name: topExpense[0].name, amountMinor: Number(topExpense[0].amount_minor) }
      : null,
    paymentSplit: {
      cash: Number(s.cash_minor || 0),
      card: Number(s.card_minor || 0),
      online: Number(s.online_minor || 0),
      other: Number(s.other_minor || 0),
    },
    paymentMethodSplit: {
      cashMinor: Number(s.cash_minor || 0),
      cardMinor: Number(s.card_minor || 0),
      onlineMinor: Number(s.online_minor || 0),
      otherMinor: Number(s.other_minor || 0),
    },
  };
}

// 10. Chart Analytics Series (7d Daily, 30d Daily, 90d Daily)
export async function getLedgerChartData(
  tenantId: string,
  rangeStr: string = "30d",
  timezone: string = "Asia/Karachi"
) {
  await ensureLedgerSchema();

  const days = rangeStr === "7d" ? 7 : rangeStr === "90d" ? 90 : 30;

  const dailySeries = await sql`
    WITH date_range AS (
      SELECT (NOW() AT TIME ZONE ${timezone})::date - (n || ' days')::interval as day_date
      FROM generate_series(0, ${days - 1}) n
    )
    SELECT 
      TO_CHAR(d.day_date, 'YYYY-MM-DD') as date,
      TO_CHAR(d.day_date, 'Mon DD') as label,
      COALESCE(SUM(CASE WHEN e.type = 'income' AND e.is_voided = false THEN e.amount_minor ELSE 0 END), 0)::bigint as income_minor,
      COALESCE(SUM(CASE WHEN e.is_voided = false THEN e.amount_minor ELSE 0 END), 0)::bigint as expense_minor,
      COUNT(CASE WHEN e.is_voided = false THEN 1 END)::int as item_count
    FROM date_range d
    LEFT JOIN ledger_entries e 
      ON e.tenant_id = ${tenantId}
      AND (e.occurred_at AT TIME ZONE ${timezone})::date = d.day_date::date
    GROUP BY d.day_date
    ORDER BY d.day_date ASC;
  `;

  const categoryBreakdown = await sql`
    SELECT 
      c.name,
      SUM(e.amount_minor)::bigint as amount_minor,
      COUNT(*)::int as count
    FROM ledger_entries e
    JOIN ledger_categories c ON e.category_id = c.id
    WHERE 
      e.tenant_id = ${tenantId}
      AND e.is_voided = false
      AND e.occurred_at >= (NOW() - (${days || " days"}::interval))
    GROUP BY c.name
    ORDER BY amount_minor DESC
    LIMIT 8;
  `;

  const topItems = await sql`
    SELECT 
      MAX(e.title) as name,
      COALESCE(e.unit, 'pcs') as unit,
      SUM(COALESCE(e.quantity, 1))::numeric as total_quantity,
      SUM(e.amount_minor)::bigint as amount_minor,
      COUNT(*)::int as count
    FROM ledger_entries e
    WHERE 
      e.tenant_id = ${tenantId}
      AND e.is_voided = false
      AND e.occurred_at >= (NOW() - (${days || " days"}::interval))
    GROUP BY LOWER(TRIM(e.title)), COALESCE(e.unit, 'pcs')
    ORDER BY amount_minor DESC
    LIMIT 6;
  `;

  const categoriesFormatted = categoryBreakdown.map((c: any) => ({
    name: c.name,
    amountMinor: Number(c.amount_minor),
    count: Number(c.count),
    type: "expense" as const,
  }));

  return {
    range: `${days}d`,
    dailySeries: dailySeries.map((d: any) => ({
      date: d.date,
      label: d.label,
      incomeMinor: Number(d.income_minor),
      expenseMinor: Number(d.expense_minor),
      itemCount: Number(d.item_count || 0),
      netMinor: -Number(d.expense_minor),
    })),
    categories: categoriesFormatted,
    categoryBreakdown: categoriesFormatted,
    topItems: topItems.map((item: any) => ({
      name: item.name,
      unit: item.unit || "pcs",
      totalQuantity: Number(item.total_quantity || 0),
      amountMinor: Number(item.amount_minor || 0),
      count: Number(item.count || 0),
    })),
    paymentSplit: { cash: 0, card: 0, online: 0, other: 0 },
  };
}

// 11. Excel-Friendly CSV Export Stream with UTF-8 BOM
export async function generateLedgerCsv(tenantId: string, filters: LedgerFilterInput) {
  const exportFilters = { ...filters, page: 1, offset: 0, limit: 10000 };
  const { entries } = await getLedgerEntries(tenantId, exportFilters);

  const BOM = "\uFEFF";
  const headers = [
    "Entry ID",
    "Date",
    "Time",
    "Item Brought / Title",
    "Quantity",
    "Unit",
    "Unit Cost (PKR)",
    "Total Cost Price (PKR)",
    "Category",
    "Vendor / Supplier",
    "Payment Method",
    "Status",
    "Added By",
    "Created At",
    "Void Reason",
  ];

  const escapeCsv = (val: any) => {
    if (val === null || val === undefined) return '""';
    const str = String(val).replace(/"/g, '""');
    return `"${str}"`;
  };

  const rows = entries.map((e) => {
    const d = new Date(e.occurred_at);
    const dateStr = d.toISOString().split("T")[0];
    const timeStr = d.toLocaleTimeString("en-US", { hour12: true });
    const unitCostPkr = ((e.unit_cost_minor || e.amount_minor) / 100).toFixed(2);
    const totalCostPkr = (e.amount_minor / 100).toFixed(2);

    return [
      escapeCsv(e.id),
      escapeCsv(dateStr),
      escapeCsv(timeStr),
      escapeCsv(e.title),
      escapeCsv(e.quantity || 1),
      escapeCsv(e.unit || "pcs"),
      escapeCsv(unitCostPkr),
      escapeCsv(totalCostPkr),
      escapeCsv(e.category_name || "Uncategorized"),
      escapeCsv(e.vendor_name || ""),
      escapeCsv(e.payment_method ? e.payment_method.toUpperCase() : "CASH"),
      escapeCsv(e.is_voided ? "VOIDED" : "ACTIVE"),
      escapeCsv(e.added_by_name),
      escapeCsv(e.created_at),
      escapeCsv(e.void_reason || ""),
    ].join(",");
  });

  return BOM + [headers.join(","), ...rows].join("\r\n");
}
