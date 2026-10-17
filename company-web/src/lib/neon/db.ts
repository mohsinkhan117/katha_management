import { neon, Pool } from "@neondatabase/serverless";

const databaseUrl = process.env.DATABASE_URL || "";

/**
 * Serverless SQL executor for single/batched queries using HTTP transport.
 * Works seamlessly in Server Components, Route Handlers, and Edge Functions.
 */
export const sql = neon(databaseUrl);

/**
 * Connection pool instance for transactions or session-level queries.
 */
export function getDbPool() {
  if (!databaseUrl) {
    throw new Error("DATABASE_URL is missing. Please ensure .env.local is configured.");
  }
  return new Pool({ connectionString: databaseUrl });
}

// Global singleton state across warm invocations to eliminate repeated DDL & redundant lookups
const globalForDb = globalThis as unknown as {
  __kathaSchemaInitPromise?: Promise<void> | null;
  __kathaSeededTenants?: Set<string>;
  __kathaTenantCache?: Map<string, { company: any; expiresAtMs: number }>;
  __kathaLastExpirySweepMs?: number;
};

if (!globalForDb.__kathaSeededTenants) {
  globalForDb.__kathaSeededTenants = new Set<string>();
}
if (!globalForDb.__kathaTenantCache) {
  globalForDb.__kathaTenantCache = new Map<string, { company: any; expiresAtMs: number }>();
}

const TENANT_CACHE_TTL_MS = 15_000; // 15 seconds fast cache for parallel API calls
const EXPIRY_SWEEP_INTERVAL_MS = 60_000; // Run expired trial sweep at most once per minute

export function getCachedTenantByEmail(email: string): any | null {
  const key = email.trim().toLowerCase();
  const entry = globalForDb.__kathaTenantCache?.get(key);
  if (!entry) return null;
  if (Date.now() > entry.expiresAtMs) {
    globalForDb.__kathaTenantCache?.delete(key);
    return null;
  }
  return entry.company;
}

export function setCachedTenantByEmail(email: string, company: any) {
  if (!email || !company) return;
  const key = email.trim().toLowerCase();
  globalForDb.__kathaTenantCache?.set(key, {
    company,
    expiresAtMs: Date.now() + TENANT_CACHE_TTL_MS,
  });
}

export function invalidateTenantCache(email?: string) {
  if (email) {
    globalForDb.__kathaTenantCache?.delete(email.trim().toLowerCase());
  } else {
    globalForDb.__kathaTenantCache?.clear();
  }
}

export function getSeededTenantsSet(): Set<string> {
  if (!globalForDb.__kathaSeededTenants) {
    globalForDb.__kathaSeededTenants = new Set<string>();
  }
  return globalForDb.__kathaSeededTenants;
}

/**
 * Ensures all application and ledger tables/indexes exist ONCE per server process lifecycle.
 * Concurrent requests share the same in-flight promise, reducing 15+ sequential DDL queries per request to 0.
 */
export async function ensureAppSchema(): Promise<void> {
  if (!globalForDb.__kathaSchemaInitPromise) {
    globalForDb.__kathaSchemaInitPromise = (async () => {
      try {
        // 1. Create core tables in parallel
        await Promise.all([
          sql`
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
          `,
          sql`
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
          `,
          sql`
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
          `,
          sql`
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
          `,
          sql`
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
          `,
          sql`
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
          `,
          sql`
            CREATE TABLE IF NOT EXISTS ledger_categories (
              id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
              tenant_id VARCHAR(64) NOT NULL,
              name VARCHAR(128) NOT NULL,
              type VARCHAR(16) NOT NULL CHECK (type IN ('income', 'expense')),
              is_default BOOLEAN NOT NULL DEFAULT false,
              created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
              CONSTRAINT uq_tenant_category_name UNIQUE (tenant_id, name)
            );
          `,
        ]);

        // 2. Create ledger_entries (references ledger_categories) & apply combined ALTER migrations in parallel
        await Promise.all([
          sql`
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
          `,
          sql`
            ALTER TABLE companies
              ADD COLUMN IF NOT EXISTS trial_started_at TIMESTAMP WITH TIME ZONE,
              ADD COLUMN IF NOT EXISTS expires_at TIMESTAMP WITH TIME ZONE;
          `.catch(() => {}),
          sql`
            ALTER TABLE products
              ADD COLUMN IF NOT EXISTS unit VARCHAR(64) DEFAULT 'unit',
              ADD COLUMN IF NOT EXISTS description TEXT,
              ADD COLUMN IF NOT EXISTS image_url TEXT,
              ADD COLUMN IF NOT EXISTS retail_price NUMERIC(12, 2) DEFAULT 0,
              ADD COLUMN IF NOT EXISTS discount_percentage NUMERIC(5, 2) DEFAULT 0,
              ADD COLUMN IF NOT EXISTS final_price NUMERIC(12, 2) DEFAULT 0,
              ADD COLUMN IF NOT EXISTS cost_price NUMERIC(12, 2),
              ADD COLUMN IF NOT EXISTS status VARCHAR(32) DEFAULT 'inStock';
          `.catch(() => {}),
        ]);

        // 3. Ensure ledger_entries columns and all performance indexes in parallel
        await Promise.all([
          sql`
            ALTER TABLE ledger_entries
              ADD COLUMN IF NOT EXISTS quantity NUMERIC(12, 2) NOT NULL DEFAULT 1,
              ADD COLUMN IF NOT EXISTS unit VARCHAR(32) NOT NULL DEFAULT 'pcs',
              ADD COLUMN IF NOT EXISTS unit_cost_minor BIGINT,
              ADD COLUMN IF NOT EXISTS vendor_name VARCHAR(255);
          `.catch(() => {}),
          sql`CREATE INDEX IF NOT EXISTS idx_companies_admin_email_lower ON companies (LOWER(admin_email));`.catch(() => {}),
          sql`CREATE INDEX IF NOT EXISTS idx_orders_company_created ON orders (company_id, created_at DESC);`.catch(() => {}),
          sql`CREATE INDEX IF NOT EXISTS idx_products_company_created ON products (company_id, created_at DESC);`.catch(() => {}),
          sql`CREATE INDEX IF NOT EXISTS idx_product_sizes_company_product ON product_sizes (company_id, product_id, sort_order ASC);`.catch(() => {}),
          sql`CREATE INDEX IF NOT EXISTS idx_distributors_company_created ON distributor_invite_tokens (company_id, created_at DESC);`.catch(() => {}),
          sql`CREATE INDEX IF NOT EXISTS idx_parties_company_created ON parties (company_id, created_at DESC);`.catch(() => {}),
          sql`CREATE INDEX IF NOT EXISTS idx_ledger_categories_tenant ON ledger_categories (tenant_id, type);`.catch(() => {}),
          sql`CREATE INDEX IF NOT EXISTS idx_ledger_entries_tenant_occurred ON ledger_entries (tenant_id, occurred_at DESC);`.catch(() => {}),
          sql`CREATE INDEX IF NOT EXISTS idx_ledger_entries_tenant_category ON ledger_entries (tenant_id, category_id);`.catch(() => {}),
          sql`CREATE INDEX IF NOT EXISTS idx_ledger_entries_tenant_type_occurred ON ledger_entries (tenant_id, type, occurred_at);`.catch(() => {}),
          sql`CREATE INDEX IF NOT EXISTS idx_ledger_entries_tenant_void ON ledger_entries (tenant_id, is_voided);`.catch(() => {}),
        ]);
      } catch (err) {
        globalForDb.__kathaSchemaInitPromise = null;
        throw err;
      }
    })();
  }

  await globalForDb.__kathaSchemaInitPromise;

  // Throttled background sweep for expired 1-month trials (runs at most once per 60s, non-blocking)
  const now = Date.now();
  if (!globalForDb.__kathaLastExpirySweepMs || now - globalForDb.__kathaLastExpirySweepMs > EXPIRY_SWEEP_INTERVAL_MS) {
    globalForDb.__kathaLastExpirySweepMs = now;
    sql`
      UPDATE companies
      SET is_active = false, updated_at = NOW()
      WHERE is_active = true
        AND expires_at IS NOT NULL
        AND expires_at < NOW();
    `.catch(() => {});
  }
}

/**
 * Fetches all tenant operational data (distributors, orders, products, sizes, parties)
 * concurrently in a single parallel Promise.all batch and computes real-time metrics.
 */
export async function fetchTenantDashboardPayload(companyId: string) {
  const [distributors, orders, rawProducts, rawSizes, parties] = await Promise.all([
    sql`
      SELECT 
        id,
        token as "inviteToken",
        COALESCE(distributor_name, 'Pending Claim') as name,
        COALESCE(phone, 'Unassigned') as phone,
        COALESCE(territory_name, 'General Zone') as territory,
        is_claimed as "isClaimed",
        created_at as "createdAt"
      FROM distributor_invite_tokens
      WHERE company_id = ${companyId}
      ORDER BY created_at DESC;
    `,
    sql`
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
      WHERE company_id = ${companyId}
      ORDER BY created_at DESC;
    `,
    sql`
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
      WHERE company_id = ${companyId}
      ORDER BY created_at DESC;
    `,
    sql`
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
      WHERE company_id = ${companyId}
      ORDER BY sort_order ASC, price ASC;
    `,
    sql`
      SELECT 
        id,
        name,
        owner_name as "ownerName",
        phone,
        territory,
        balance,
        created_at as "createdAt"
      FROM parties
      WHERE company_id = ${companyId}
      ORDER BY created_at DESC;
    `,
  ]);

  // O(N) grouping of product sizes by productId
  const sizesByProductId = new Map<string, any[]>();
  for (const s of rawSizes) {
    const pid = s.productId as string;
    let list = sizesByProductId.get(pid);
    if (!list) {
      list = [];
      sizesByProductId.set(pid, list);
    }
    list.push(s);
  }

  const products = rawProducts.map((p: any) => ({
    ...p,
    sizes: sizesByProductId.get(p.id) || [],
  }));

  // Single-pass O(N) metrics & status aggregation
  const totalOrdersCount = orders.length;
  let totalSalesNum = 0;
  let totalPaidNum = 0;
  let deliveredCount = 0;
  let inTransitCount = 0;
  let pendingCount = 0;
  let cancelledCount = 0;

  for (const o of orders) {
    totalSalesNum += Number(o.totalAmount || 0);
    totalPaidNum += Number(o.paidAmount || 0);
    if (o.status === "Delivered" || o.status === "Completed") deliveredCount++;
    else if (o.status === "In Transit") inTransitCount++;
    else if (o.status === "Pending") pendingCount++;
    else if (o.status === "Cancelled") cancelledCount++;
  }

  const totalProfitNum = Math.round(totalSalesNum * 0.22);
  const totalCalculated = totalOrdersCount || 1;
  const orderStatuses = [
    { status: "Delivered", count: deliveredCount, percentage: Number(((deliveredCount / totalCalculated) * 100).toFixed(1)), color: "bg-emerald-500" },
    { status: "In Transit", count: inTransitCount, percentage: Number(((inTransitCount / totalCalculated) * 100).toFixed(1)), color: "bg-blue-500" },
    { status: "Pending", count: pendingCount, percentage: Number(((pendingCount / totalCalculated) * 100).toFixed(1)), color: "bg-amber-500" },
    { status: "Cancelled", count: cancelledCount, percentage: Number(((cancelledCount / totalCalculated) * 100).toFixed(1)), color: "bg-rose-500" },
  ];

  const outstandingReceivables = Math.max(0, totalSalesNum - totalPaidNum);
  const recoveryRate = totalSalesNum > 0 ? Number(((totalPaidNum / totalSalesNum) * 100).toFixed(1)) : 0;

  return {
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
  };
}

/**
 * Verifies live connection to Neon Postgres and returns server telemetry.
 */
export async function checkNeonConnection() {
  try {
    const rows = await sql`
      SELECT 
        NOW() as server_time,
        current_database() as database_name,
        current_user as db_user,
        version() as postgres_version;
    `;
    return {
      connected: true,
      branch: process.env.NEON_BRANCH || "production",
      details: rows[0],
    };
  } catch (err: any) {
    return {
      connected: false,
      branch: process.env.NEON_BRANCH || "production",
      error: err.message,
    };
  }
}



