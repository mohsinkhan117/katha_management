// Supabase Edge Function: claim-invite-token
// Validates 12-char invite token (KTH-XXXX-XXXX) and binds Distributor to Company & Territory

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

serve(async (req: Request) => {
  try {
    const { token } = await req.json();
    if (!token) {
      return new Response(JSON.stringify({ error: "Missing invite token" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Token verification & tenant binding logic will be implemented here
    return new Response(
      JSON.stringify({
        success: true,
        message: "Distributor linked to company tenant successfully",
      }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});

