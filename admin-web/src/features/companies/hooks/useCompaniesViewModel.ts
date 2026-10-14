"use client";

// Equivalent to a Flutter ChangeNotifier ViewModel for the Super Admin Companies screen.

import { useState, useCallback } from "react";
import type { Company } from "@shared-types/database.types";
import { companyTenantService } from "../services/companyTenantService";

export function useCompaniesViewModel() {
  const [companies, setCompanies] = useState<Company[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const loadCompanies = useCallback(async () => {
    setIsLoading(true);
    setErrorMessage(null);
    try {
      const list = await companyTenantService.getAllCompanies();
      setCompanies(list);
    } catch (err: any) {
      setErrorMessage(err.message ?? "Failed to load tenant companies");
    } finally {
      setIsLoading(false);
    }
  }, []);

  return {
    companies,
    isLoading,
    errorMessage,
    loadCompanies,
  };
}

