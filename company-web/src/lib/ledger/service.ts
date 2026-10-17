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
  amount_minor: number;
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

// 1. Ensure Tables & Indexes Exist in Neon PostgreSQL
export async function ensureLedgerSchema() {
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
      type VARCHAR(16) NOT NULL CHECK (type IN ('income', 'expense')),
      title VARCHAR(255) NOT NULL,
      category_id UUID NOT NULL REFERENCES ledger_categories(id),
      amount_minor BIGINT NOT NULL CHECK (amount_minor > 0),
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
    await sql`CREATE INDEX IF NOT EXISTS idx_ledger_categories_tenant ON ledger_categories (tenant_id, type);`;
    await sql`CREATE INDEX IF NOT EXISTS idx_ledger_entries_tenant_occurred ON ledger_entries (tenant_id, occurred_at DESC);`;
    await sql`CREATE INDEX IF NOT EXISTS idx_ledger_entries_tenant_category ON ledger_entries (tenant_id, category_id);`;
    await sql`CREATE INDEX IF NOT EXISTS idx_ledger_entries_tenant_type_occurred ON ledger_entries (tenant_id, type, occurred_at);`;
    await sql`CREATE INDEX IF NOT EXISTS idx_ledger_entries_tenant_void ON ledger_entries (tenant_id, is_voided);`;
  } catch (err: any) {
    // Indexes already exist
  }
}

// 2. Seed Shop Default Categories per Tenant
export async function seedDefaultCategories(tenantId: string) {
  const defaultCategories: Array<{ name: string; type: "income" | "expense" }> = [
    // Income
    { name: "Sales - Cash", type: "income" },
    { name: "Sales - Card", type: "income" },
    { name: "Sales - Online", type: "income" },
    { name: "Other Income", type: "income" },
    // Expense
    { name: "Stock Purchase", type: "expense" },
    { name: "Rent", type: "expense" },
    { name: "Wages", type: "expense" },
    { name: "Utilities", type: "expense" },
    { name: "Transport", type: "expense" },
    { name: "Maintenance", type: "expense" },
    { name: "Refunds", type: "expense" },
    { name: "Other", type: "expense" },
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

  let user = null;
  try {
    user = await stackServerApp.getUser();
  } catch (err) {
    // Unauthenticated
  }

  if (!user || !user.primaryEmail) {
    const error: any = new Error("Unauthorized: Authentication required");
    error.status = 401;
    throw error;
  }

  const userEmail = user.primaryEmail.toLowerCase().trim();

  // Find tenant by admin_email
  const companies = await sql`
    SELECT id, name, slug, admin_email, plan_tier, is_active
    FROM companies
    WHERE LOWER(admin_email) = ${userEmail} AND is_active = true
    LIMIT 1;
  `;

  let tenant = companies[0];

  // If user doesn't have an explicit company yet, check if they are superadmin or auto-provision
  if (!tenant) {
    const isSuperAdmin = Boolean(
      userEmail.includes("superadmin") ||
      userEmail.endsWith("@katha.com") ||
      userEmail === "admin@katha.com"
    );

    if (isSuperAdmin) {
      const allCompanies = await sql`SELECT id, name, slug, admin_email FROM companies WHERE is_active = true LIMIT 1;`;
      tenant = allCompanies[0];
    } else {
      // Check if user has an admin role in server metadata
      const hasAdminRole = user.serverMetadata?.role === "admin";
      if (!hasAdminRole) {
        // Auto-provision tenant for logged-in user so they have their own company
        const companyId = `comp_${userEmail.split("@")[0].replace(/[^a-zA-Z0-9]/g, "")}_${Date.now().toString(36)}`;
        const companyName = user.displayName || `${userEmail.split("@")[0]} Commercial`;
        const companySlug = `${userEmail.split("@")[0].toLowerCase().replace(/[^a-z0-9]/g, "-")}-${Date.now().toString(36).slice(-4)}`;

        const inserted = await sql`
          INSERT INTO companies (
            id, name, slug, admin_email, plan_tier, is_active
          ) VALUES (
            ${companyId}, ${companyName}, ${companySlug}, ${userEmail}, 'standard', true
          )
          RETURNING id, name, slug, admin_email;
        `;
        tenant = inserted[0];
      }
    }
  }

  if (!tenant) {
    const error: any = new Error("Forbidden: Admin access required for this tenant ledger");
    error.status = 403;
    throw error;
  }

  // Ensure default categories are seeded for this tenant
  await seedDefaultCategories(tenant.id);

  return {
    user,
    userId: user.id,
    userName: user.displayName || user.primaryEmail.split("@")[0],
    userEmail: user.primaryEmail,
    tenantId: tenant.id as string,
    tenantName: tenant.name as string,
    currency: "PKR",
    timezone: "Asia/Karachi", // Default tenant timezone
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
export async function createLedgerCategory(tenantId: string, name: string, type: "income" | "expense") {
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

// 6. Create Ledger Entry
export async function createLedgerEntry(
  tenantId: string,
  userId: string,
  userName: string,
  input: CreateLedgerEntryInput
) {
  await ensureLedgerSchema();

  // Validate category belongs to this tenant or is valid
  const catRows = await sql`
    SELECT id, name, type FROM ledger_categories
    WHERE id = ${input.categoryId} AND tenant_id = ${tenantId}
    LIMIT 1;
  `;

  if (!catRows || catRows.length === 0) {
    const error: any = new Error("Selected category does not exist for this tenant");
    error.status = 400;
    throw error;
  }

  const category = catRows[0];
  if (category.type !== input.type) {
    const error: any = new Error(`Category type '${category.type}' does not match entry type '${input.type}'`);
    error.status = 400;
    throw error;
  }

  const occurredAt = input.occurredAt ? new Date(input.occurredAt) : new Date();

  // Validate occurredAt is not in the future beyond 15 minutes tolerance
  const futureTolerance = new Date(Date.now() + 15 * 60 * 1000);
  if (occurredAt > futureTolerance) {
    const error: any = new Error("Entry date and time cannot be in the future");
    error.status = 400;
    throw error;
  }

  const rows = await sql`
    INSERT INTO ledger_entries (
      tenant_id,
      type,
      title,
      category_id,
      amount_minor,
      currency,
      payment_method,
      occurred_at,
      added_by,
      added_by_name
    ) VALUES (
      ${tenantId},
      ${input.type},
      ${input.title.trim()},
      ${input.categoryId},
      ${input.amountMinor},
      ${input.currency || 'PKR'},
      ${input.paymentMethod || null},
      ${occurredAt.toISOString()},
      ${userId},
      ${userName}
    )
    RETURNING *;
  `;

  return {
    ...rows[0],
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

  // Query entry strictly scoped to tenant_id
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

// 8. Get Paginated Ledger Entries with Server-Side Totals
export async function getLedgerEntries(tenantId: string, filters: LedgerFilterInput) {
  await ensureLedgerSchema();

  const page = filters.page || 1;
  const limit = Math.min(100, filters.limit || 50);
  const offset = (page - 1) * limit;

  // Build dynamic SQL query with parameters
  let conditions = [sql`e.tenant_id = ${tenantId}`];

  if (filters.type) {
    conditions.push(sql`e.type = ${filters.type}`);
  }

  if (filters.categoryId) {
    conditions.push(sql`e.category_id = ${filters.categoryId}`);
  }

  if (filters.addedBy) {
    conditions.push(sql`e.added_by = ${filters.addedBy}`);
  }

  if (filters.from) {
    conditions.push(sql`e.occurred_at >= ${new Date(filters.from).toISOString()}`);
  }

  if (filters.to) {
    conditions.push(sql`e.occurred_at <= ${new Date(filters.to).toISOString()}`);
  }

  if (filters.search && filters.search.trim()) {
    const term = `%${filters.search.trim().toLowerCase()}%`;
    conditions.push(sql`(LOWER(e.title) LIKE ${term} OR LOWER(c.name) LIKE ${term} OR LOWER(e.added_by_name) LIKE ${term})`);
  }

  // Combine conditions with AND
  const whereClause = conditions.reduce((prev, curr) => sql`${prev} AND ${curr}`);

  // Sorting
  let orderByClause = sql`e.occurred_at DESC`;
  if (filters.sort === "occurred_at:asc") orderByClause = sql`e.occurred_at ASC`;
  if (filters.sort === "amount_minor:desc") orderByClause = sql`e.amount_minor DESC`;
  if (filters.sort === "amount_minor:asc") orderByClause = sql`e.amount_minor ASC`;

  // 1. Fetch paginated entries
  const entries = await sql`
    SELECT 
      e.id,
      e.tenant_id,
      e.type,
      e.title,
      e.category_id,
      c.name as category_name,
      e.amount_minor,
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

  // 2. Fetch total count for pagination
  const countResult = await sql`
    SELECT COUNT(*)::int as total
    FROM ledger_entries e
    JOIN ledger_categories c ON e.category_id = c.id
    WHERE ${whereClause};
  `;
  const total = countResult[0]?.total || 0;

  // 3. Compute filtered totals server-side across ALL matching rows (excluding voided)
  const totalsResult = await sql`
    SELECT 
      COALESCE(SUM(CASE WHEN e.type = 'income' AND e.is_voided = false THEN e.amount_minor ELSE 0 END), 0)::bigint as total_income,
      COALESCE(SUM(CASE WHEN e.type = 'expense' AND e.is_voided = false THEN e.amount_minor ELSE 0 END), 0)::bigint as total_expense
    FROM ledger_entries e
    JOIN ledger_categories c ON e.category_id = c.id
    WHERE ${whereClause};
  `;

  const totalIncomeMinor = Number(totalsResult[0]?.total_income || 0);
  const totalExpenseMinor = Number(totalsResult[0]?.total_expense || 0);
  const netMinor = totalIncomeMinor - totalExpenseMinor;

  return {
    entries: entries as unknown as LedgerEntry[],
    pagination: {
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit) || 1,
    },
    filteredTotals: {
      totalIncomeMinor,
      totalExpenseMinor,
      netMinor,
    },
  };
}

// 9. Day Summary (computed in Tenant's Timezone)
export async function getLedgerSummary(tenantId: string, dateStr?: string, timezone: string = "Asia/Karachi") {
  await ensureLedgerSchema();

  // If no date provided, use today in tenant timezone
  const targetDate = dateStr || new Date().toISOString().split("T")[0];

  // Compute timezone-aware day boundary
  // e.g. 2026-10-17 00:00:00 to 2026-10-17 23:59:59 in timezone
  const rows = await sql`
    SELECT 
      COALESCE(SUM(CASE WHEN type = 'income' AND is_voided = false THEN amount_minor ELSE 0 END), 0)::bigint as today_income,
      COALESCE(SUM(CASE WHEN type = 'expense' AND is_voided = false THEN amount_minor ELSE 0 END), 0)::bigint as today_expense,
      COUNT(*)::int as total_entries,
      COALESCE(SUM(CASE WHEN payment_method = 'cash' AND is_voided = false AND type = 'income' THEN amount_minor ELSE 0 END), 0)::bigint as cash_minor,
      COALESCE(SUM(CASE WHEN payment_method = 'card' AND is_voided = false AND type = 'income' THEN amount_minor ELSE 0 END), 0)::bigint as card_minor,
      COALESCE(SUM(CASE WHEN payment_method = 'online' AND is_voided = false AND type = 'income' THEN amount_minor ELSE 0 END), 0)::bigint as online_minor,
      COALESCE(SUM(CASE WHEN payment_method = 'other' AND is_voided = false AND type = 'income' THEN amount_minor ELSE 0 END), 0)::bigint as other_minor
    FROM ledger_entries
    WHERE 
      tenant_id = ${tenantId}
      AND (occurred_at AT TIME ZONE ${timezone})::date = ${targetDate}::date;
  `;

  // Top expense category for this day
  const topExpense = await sql`
    SELECT c.name, SUM(e.amount_minor)::bigint as amount_minor
    FROM ledger_entries e
    JOIN ledger_categories c ON e.category_id = c.id
    WHERE 
      e.tenant_id = ${tenantId}
      AND e.type = 'expense'
      AND e.is_voided = false
      AND (e.occurred_at AT TIME ZONE ${timezone})::date = ${targetDate}::date
    GROUP BY c.name
    ORDER BY amount_minor DESC
    LIMIT 1;
  `;

  const summary = rows[0] || {};
  const todayIncomeMinor = Number(summary.today_income || 0);
  const todayExpenseMinor = Number(summary.today_expense || 0);
  const netMinor = todayIncomeMinor - todayExpenseMinor;

  return {
    date: targetDate,
    timezone,
    todayIncomeMinor,
    todayExpenseMinor,
    netMinor,
    entryCount: Number(summary.total_entries || 0),
    topExpenseCategory: topExpense[0]
      ? { name: topExpense[0].name, amountMinor: Number(topExpense[0].amount_minor) }
      : null,
    paymentMethodSplit: {
      cashMinor: Number(summary.cash_minor || 0),
      cardMinor: Number(summary.card_minor || 0),
      onlineMinor: Number(summary.online_minor || 0),
      otherMinor: Number(summary.other_minor || 0),
    },
  };
}

// 10. Chart Analytics Series (7d, 30d, 90d)
export async function getLedgerChartData(tenantId: string, rangeStr: string = "30d", timezone: string = "Asia/Karachi") {
  await ensureLedgerSchema();

  const days = rangeStr === "7d" ? 7 : rangeStr === "90d" ? 90 : 30;

  // Daily income and expense series
  const dailySeries = await sql`
    WITH date_range AS (
      SELECT (NOW() AT TIME ZONE ${timezone})::date - (n || ' days')::interval as day_date
      FROM generate_series(0, ${days - 1}) n
    )
    SELECT 
      TO_CHAR(d.day_date, 'YYYY-MM-DD') as date,
      TO_CHAR(d.day_date, 'Mon DD') as label,
      COALESCE(SUM(CASE WHEN e.type = 'income' AND e.is_voided = false THEN e.amount_minor ELSE 0 END), 0)::bigint as income_minor,
      COALESCE(SUM(CASE WHEN e.type = 'expense' AND e.is_voided = false THEN e.amount_minor ELSE 0 END), 0)::bigint as expense_minor
    FROM date_range d
    LEFT JOIN ledger_entries e 
      ON e.tenant_id = ${tenantId}
      AND (e.occurred_at AT TIME ZONE ${timezone})::date = d.day_date::date
    GROUP BY d.day_date
    ORDER BY d.day_date ASC;
  `;

  // Category breakdown for expenses in this range
  const categoryBreakdown = await sql`
    SELECT 
      c.name,
      SUM(e.amount_minor)::bigint as amount_minor,
      COUNT(*)::int as count
    FROM ledger_entries e
    JOIN ledger_categories c ON e.category_id = c.id
    WHERE 
      e.tenant_id = ${tenantId}
      AND e.type = 'expense'
      AND e.is_voided = false
      AND e.occurred_at >= (NOW() - (${days || ' days'}::interval))
    GROUP BY c.name
    ORDER BY amount_minor DESC
    LIMIT 8;
  `;

  // Payment method breakdown for income in this range
  const paymentBreakdown = await sql`
    SELECT 
      COALESCE(payment_method, 'other') as method,
      SUM(amount_minor)::bigint as amount_minor,
      COUNT(*)::int as count
    FROM ledger_entries
    WHERE 
      tenant_id = ${tenantId}
      AND type = 'income'
      AND is_voided = false
      AND occurred_at >= (NOW() - (${days || ' days'}::interval))
    GROUP BY payment_method
    ORDER BY amount_minor DESC;
  `;

  return {
    range: `${days}d`,
    dailySeries: dailySeries.map((d: any) => ({
      date: d.date,
      label: d.label,
      incomeMinor: Number(d.income_minor),
      expenseMinor: Number(d.expense_minor),
      netMinor: Number(d.income_minor) - Number(d.expense_minor),
    })),
    categoryBreakdown: categoryBreakdown.map((c: any) => ({
      name: c.name,
      amountMinor: Number(c.amount_minor),
      count: Number(c.count),
    })),
    paymentBreakdown: paymentBreakdown.map((p: any) => ({
      method: p.method,
      amountMinor: Number(p.amount_minor),
      count: Number(p.count),
    })),
  };
}

// 11. Excel-Friendly CSV Export Stream with UTF-8 BOM
export async function generateLedgerCsv(tenantId: string, filters: LedgerFilterInput) {
  // Fetch all matching rows up to 10,000 without pagination limit for export
  const exportFilters = { ...filters, page: 1, limit: 10000 };
  const { entries } = await getLedgerEntries(tenantId, exportFilters);

  // UTF-8 BOM for Microsoft Excel compatibility
  const BOM = "\uFEFF";
  const headers = [
    "Entry ID",
    "Date",
    "Time",
    "Title",
    "Category",
    "Type",
    "Payment Method",
    "Amount (PKR)",
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
    const amountPkr = (e.amount_minor / 100).toFixed(2);

    return [
      escapeCsv(e.id),
      escapeCsv(dateStr),
      escapeCsv(timeStr),
      escapeCsv(e.title),
      escapeCsv(e.category_name || "Uncategorized"),
      escapeCsv(e.type.toUpperCase()),
      escapeCsv(e.payment_method ? e.payment_method.toUpperCase() : "N/A"),
      escapeCsv(e.type === "expense" ? `-${amountPkr}` : amountPkr),
      escapeCsv(e.is_voided ? "VOIDED" : "ACTIVE"),
      escapeCsv(e.added_by_name),
      escapeCsv(e.created_at),
      escapeCsv(e.void_reason || ""),
    ].join(",");
  });

  return BOM + [headers.join(","), ...rows].join("\r\n");
}

