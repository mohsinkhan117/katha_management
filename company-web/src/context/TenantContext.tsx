"use client";

import React, { createContext, useContext, useState, useEffect } from "react";

export interface TenantInfo {
  id: string;
  name: string;
  slug: string;
  admin_email: string;
  phone?: string;
  address?: string;
  plan_tier: string;
}

interface TenantContextType {
  activeTenant: TenantInfo | null;
  availableTenants: TenantInfo[];
  isLoading: boolean;
  switchTenant: (slugOrId: string) => void;
}

const TenantContext = createContext<TenantContextType>({
  activeTenant: null,
  availableTenants: [],
  isLoading: true,
  switchTenant: () => {},
});

const DEFAULT_FALLBACK_TENANT: TenantInfo = {
  id: "comp_apex_agro_01",
  name: "Apex Agro Chemical Ltd.",
  slug: "apex-agro",
  admin_email: "admin@apexagro.com",
  phone: "+92 42 35789000",
  address: "Plot 42, Industrial Estate, Kot Lakhpat, Lahore",
  plan_tier: "enterprise",
};

export function TenantProvider({ children }: { children: React.ReactNode }) {
  const [activeTenant, setActiveTenant] = useState<TenantInfo | null>(null);
  const [availableTenants, setAvailableTenants] = useState<TenantInfo[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    async function loadTenants() {
      try {
        setIsLoading(true);
        const res = await fetch("/api/tenant");
        const json = await res.json();

        if (json.success && json.companies && json.companies.length > 0) {
          setAvailableTenants(json.companies);
          // Check localStorage for previously selected tenant
          const savedSlug = typeof window !== "undefined" ? localStorage.getItem("katha_selected_tenant_slug") : null;
          const matched = savedSlug 
            ? json.companies.find((c: TenantInfo) => c.slug === savedSlug || c.id === savedSlug) 
            : null;
          setActiveTenant(matched || json.companies[0]);
        } else {
          setAvailableTenants([DEFAULT_FALLBACK_TENANT]);
          setActiveTenant(DEFAULT_FALLBACK_TENANT);
        }
      } catch (err) {
        console.error("Failed to load tenants:", err);
        setAvailableTenants([DEFAULT_FALLBACK_TENANT]);
        setActiveTenant(DEFAULT_FALLBACK_TENANT);
      } finally {
        setIsLoading(false);
      }
    }

    loadTenants();
  }, []);

  const switchTenant = (slugOrId: string) => {
    const found = availableTenants.find((c) => c.slug === slugOrId || c.id === slugOrId);
    if (found) {
      setActiveTenant(found);
      if (typeof window !== "undefined") {
        localStorage.setItem("katha_selected_tenant_slug", found.slug);
      }
    }
  };

  return (
    <TenantContext.Provider
      value={{
        activeTenant: activeTenant || DEFAULT_FALLBACK_TENANT,
        availableTenants,
        isLoading,
        switchTenant,
      }}
    >
      {children}
    </TenantContext.Provider>
  );
}

export function useTenant() {
  return useContext(TenantContext);
}
