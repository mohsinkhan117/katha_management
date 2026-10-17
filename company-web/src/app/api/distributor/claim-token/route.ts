import { NextRequest, NextResponse } from "next/server";
import { sql, ensureAppSchema } from "@/lib/neon/db";

/**
 * Validates and claims a 12-character distributor onboarding invite token.
 *
 * Security & Performance:
 * - Strictly validates token against Neon PostgreSQL (never falls back to demo/pre-created tenants).
 * - Verifies token is unclaimed, not expired, and belongs to an active, non-expired company tenant.
 * - Atomically marks token claimed to prevent race conditions.
 */
export async function POST(req: NextRequest) {
  try {
    const [, body] = await Promise.all([
      ensureAppSchema(),
      req.json().catch(() => ({})),
    ]);

    const { inviteToken, distributorName, phoneNumber, deviceId } = body;

    if (!inviteToken || typeof inviteToken !== "string") {
      return NextResponse.json(
        { success: false, error: "Invite token is required." },
        { status: 400 }
      );
    }

    const cleanToken = inviteToken.trim().toUpperCase();

    // Verify token format: e.g. KTH-XXXX-XXXX
    const tokenRegex = /^KTH-[A-Z0-9]{4}-[A-Z0-9]{4}$/;
    if (!tokenRegex.test(cleanToken)) {
      return NextResponse.json(
        {
          success: false,
          error: "Invalid token format. Format must match KTH-XXXX-XXXX.",
        },
        { status: 400 }
      );
    }

    // 1. Query the invite token joined with its parent company in a single fast lookup
    const rows = await sql`
      SELECT 
        t.id,
        t.token,
        t.company_id,
        t.territory_id,
        t.territory_name,
        t.is_claimed,
        t.distributor_name,
        t.phone,
        t.expires_at,
        c.name as company_name,
        c.is_active as company_is_active,
        c.expires_at as company_expires_at
      FROM distributor_invite_tokens t
      JOIN companies c ON c.id = t.company_id
      WHERE t.token = ${cleanToken}
      LIMIT 1;
    `;

    if (!rows || rows.length === 0) {
      return NextResponse.json(
        { success: false, error: "Invite token not found or invalid." },
        { status: 404 }
      );
    }

    const tokenRecord = rows[0];

    // 2. Verify parent company tenant is active and within its subscription / 1-month trial window
    const companyExpired =
      tokenRecord.company_expires_at &&
      new Date(tokenRecord.company_expires_at).getTime() < Date.now();
    if (!tokenRecord.company_is_active || companyExpired) {
      return NextResponse.json(
        {
          success: false,
          error: "The issuing company tenant is currently inactive or its subscription has expired.",
        },
        { status: 403 }
      );
    }

    // 3. Verify token has not already been claimed or expired
    if (tokenRecord.is_claimed) {
      return NextResponse.json(
        { success: false, error: "This invite token has already been claimed." },
        { status: 409 }
      );
    }

    if (tokenRecord.expires_at && new Date(tokenRecord.expires_at).getTime() < Date.now()) {
      return NextResponse.json(
        { success: false, error: "This invite token has expired. Ask your company admin to issue a new token." },
        { status: 410 }
      );
    }

    // 4. Atomically mark token as claimed
    const claimedRows = await sql`
      UPDATE distributor_invite_tokens
      SET 
        is_claimed = true,
        claimed_at = NOW(),
        device_id = ${deviceId || null},
        distributor_name = COALESCE(${distributorName?.trim() || null}, distributor_name),
        phone = COALESCE(${phoneNumber?.trim() || null}, phone)
      WHERE id = ${tokenRecord.id} AND is_claimed = false
      RETURNING id, distributor_name, phone, territory_id, territory_name;
    `;

    if (!claimedRows || claimedRows.length === 0) {
      return NextResponse.json(
        { success: false, error: "This invite token has already been claimed." },
        { status: 409 }
      );
    }

    const claimed = claimedRows[0];

    return NextResponse.json({
      success: true,
      message: "Invite token successfully claimed.",
      data: {
        distributorId: claimed.id,
        companyId: tokenRecord.company_id,
        companyName: tokenRecord.company_name,
        territoryId: claimed.territory_id || "terr_general",
        territoryName: claimed.territory_name || "General Zone",
        distributorName: claimed.distributor_name || "Field Agent",
        phoneNumber: claimed.phone || "",
        token: cleanToken,
        status: "active",
      },
    });
  } catch (error: any) {
    return NextResponse.json(
      { success: false, error: error.message || "Internal server error" },
      { status: 500 }
    );
  }
}


