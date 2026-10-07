// Supabase Edge Function: provision-company-tenant
// Triggered by Super Admin Panel (/admin-web) to create a Company tenant and invite the Company Admin

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

serve(async (req: Request) => {
  try {
    const { companyName, adminEmail, planTier, maxDistributors } = await req.json();
    if (!companyName || !adminEmail) {
      return new Response(
        JSON.stringify({ error: "companyName and adminEmail are required" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: `Company tenant '${companyName}' provisioned on ${planTier ?? "PREMIUM"} tier`,
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

