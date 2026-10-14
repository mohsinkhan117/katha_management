import { neon } from "@neondatabase/serverless";
import * as fs from "fs";
import * as path from "path";

// Read .env.local
const envContent = fs.readFileSync(".env.local", "utf-8");
let dbUrl = "";
let branch = "";

for (const line of envContent.split("\n")) {
  if (line.startsWith("DATABASE_URL=")) {
    dbUrl = line.substring("DATABASE_URL=".length).trim().replace(/^["']|["']$/g, "");
  }
  if (line.startsWith("NEON_BRANCH=")) {
    branch = line.substring("NEON_BRANCH=".length).trim().replace(/^["']|["']$/g, "");
  }
}

if (!dbUrl) {
  console.error("❌ Error: DATABASE_URL not found in .env.local");
  process.exit(1);
}

console.log(`Connecting to Neon Postgres (branch: ${branch || "production"})...`);

const sql = neon(dbUrl);

try {
  const result = await sql`
    SELECT 
      current_database() as database,
      current_user as user,
      version() as pg_version,
      NOW() as current_time;
  `;
  console.log("✅ Neon Postgres connected successfully!");
  console.log("Telemetry details:", JSON.stringify(result[0], null, 2));

  // Test table existence
  const tables = await sql`
    SELECT table_schema, table_name 
    FROM information_schema.tables 
    WHERE table_schema = 'public'
    ORDER BY table_name;
  `;
  console.log(`Discovered ${tables.length} tables in public schema:`, tables.map(t => t.table_name));

  process.exit(0);
} catch (err) {
  console.error("❌ Neon Postgres query failed:", err.message);
  process.exit(1);
}

