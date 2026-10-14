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

