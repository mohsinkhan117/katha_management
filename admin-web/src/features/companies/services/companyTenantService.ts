// Equivalent to Flutter's CompanyRepository — Used by Super Admin to manage tenant companies.

import { createClient } from "@/lib/supabase/client";
import type { Company } from "@shared-types/database.types";

export const companyTenantService = {
  async getAllCompanies(): Promise<Company[]> {
    const supabase = createClient();
    const { data, error } = await supabase
      .from("companies")
      .select("*")
      .order("created_at", { ascending: false });

    if (error) throw new Error(error.message);
    return (data as Company[]) ?? [];
  },
};

