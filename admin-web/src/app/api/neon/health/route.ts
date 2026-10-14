import { NextResponse } from "next/server";
import { checkNeonConnection } from "@/lib/neon/db";

export async function GET() {
  const result = await checkNeonConnection();

  if (!result.connected) {
    return NextResponse.json(
      {
        status: "error",
        message: "Failed to connect to Neon Postgres",
        error: result.error,
        branch: result.branch,
      },
      { status: 500 }
    );
  }

  return NextResponse.json({
    status: "ok",
    message: "Neon Postgres connected successfully",
    branch: result.branch,
    server: result.details,
    timestamp: new Date().toISOString(),
  });
}

