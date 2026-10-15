"use client";

import React, { createContext, useContext, useState, useEffect } from "react";
import { useUser } from "@stackframe/stack";

export interface TenantInfo {
  id: string;
  name: string;
  slug: string;
  admin_email: string;
  phone?: string;
  address?: string;
  plan_tier: string;
  max_distributors?: number;
}

export interface TenantDataPayload {
  metrics: {
    totalOrders: number;
    totalSales: number;
    totalPaid: number;
    totalProfit: number;
  };
  distributors: Array<{
    id: string;
    inviteToken: string;
    name: string;
    phone: string;
    territory: string;
    isClaimed: boolean;
    createdAt?: string;
  }>;
  orders: Array<{
    id: string;
    orderNumber: string;
    partyName: string;
    distributorName: string;
    itemsCount: number;
    totalAmount: number;
    paidAmount: number;
    status: string;
    date: string;
  }>;
}

interface TenantContextType {
  activeTenant: TenantInfo | null;
  availableTenants: TenantInfo[];
  tenantData: TenantDataPayload | null;
  hasAccess: boolean;
  isCustomTenant: boolean;
  isLoading: boolean;
  switchTenant: (slugOrId: string) => void;
  refreshTenantData: () => Promise<void>;
}

const TenantContext = createContext<TenantContextType>({
  activeTenant: null,
  availableTenants: [],
  tenantData: null,
  hasAccess: true,
  isCustomTenant: false,
  isLoading: true,
  switchTenant: () => {},
  refreshTenantData: async () => {},
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
  const user = useUser();
  const [activeTenant, setActiveTenant] = useState<TenantInfo | null>(null);
  const [availableTenants, setAvailableTenants] = useState<TenantInfo[]>([]);
  const [tenantData, setTenantData] = useState<TenantDataPayload | null>(null);
  const [hasAccess, setHasAccess] = useState<boolean>(true);
  const [isCustomTenant, setIsCustomTenant] = useState<boolean>(false);
  const [isLoading, setIsLoading] = useState(true);

  // 1. Fetch available tenants list and bind strictly to logged-in user
  useEffect(() => {
    async function loadTenants() {
      try {
        setIsLoading(true);
        const res = await fetch("/api/tenant");
        const json = await res.json();

        let companies: TenantInfo[] = [];
        if (json.success && json.companies && json.companies.length > 0) {
          companies = json.companies;
        } else {
          companies = [DEFAULT_FALLBACK_TENANT];
        }

        const userEmail = user?.primaryEmail?.toLowerCase();
        const isSuperAdmin = Boolean(
          userEmail &&
            (userEmail.includes("superadmin") ||
              userEmail.endsWith("@katha.com") ||
              userEmail === "admin@katha.com")
        );

        if (isSuperAdmin) {
          // Super admin can access and switch between all active companies
          setAvailableTenants(companies);
          const savedSlug =
            typeof window !== "undefined"
              ? localStorage.getItem("katha_selected_tenant_slug")
              : null;
          const matched = savedSlug
            ? companies.find((c) => c.slug === savedSlug || c.id === savedSlug)
            : undefined;
          const chosen = matched || companies[0] || DEFAULT_FALLBACK_TENANT;
          setActiveTenant(chosen);
          setHasAccess(true);
          setIsCustomTenant(chosen.slug !== "apex-agro");
        } else if (userEmail) {
          // Tenant user: Find matching tenant by admin_email
          const matched = companies.find(
            (c) => c.admin_email?.toLowerCase() === userEmail
          );

          if (matched) {
            // Strictly isolate to this tenant only. User cannot see or switch to other tenants.
            setAvailableTenants([matched]);
            setActiveTenant(matched);
            setHasAccess(true);
            setIsCustomTenant(matched.slug !== "apex-agro");
          } else {
            // User does not belong to any active company
            // As required: only if it does not have any access should it see dummy data
            setAvailableTenants([DEFAULT_FALLBACK_TENANT]);
            setActiveTenant(DEFAULT_FALLBACK_TENANT);
            setHasAccess(false);
            setIsCustomTenant(false);
          }
        } else {
          // Not logged in: Show sandbox demo with no access
          setAvailableTenants([DEFAULT_FALLBACK_TENANT]);
          setActiveTenant(DEFAULT_FALLBACK_TENANT);
          setHasAccess(false);
          setIsCustomTenant(false);
        }
      } catch (err) {
        console.error("Failed to load tenants:", err);
        setAvailableTenants([DEFAULT_FALLBACK_TENANT]);
        setActiveTenant(DEFAULT_FALLBACK_TENANT);
        setHasAccess(false);
        setIsCustomTenant(false);
      } finally {
        setIsLoading(false);
      }
    }

    loadTenants();
  }, [user]);

  // 2. Fetch active tenant's real database records
  const fetchActiveTenantData = async () => {
    if (!activeTenant) return;

    try {
      const res = await fetch(`/api/tenant/data?companyId=${encodeURIComponent(activeTenant.id)}&slug=${encodeURIComponent(activeTenant.slug)}`);
      const json = await res.json();

      if (json.success) {
        setHasAccess(json.hasAccess ?? true);
        setIsCustomTenant(json.isCustomTenant ?? (activeTenant.slug !== "apex-agro"));
        setTenantData({
          metrics: json.metrics || { totalOrders: 0, totalSales: 0, totalPaid: 0, totalProfit: 0 },
          distributors: json.distributors || [],
          orders: json.orders || [],
        });
      }
    } catch (err) {
      console.error("Failed to fetch tenant data:", err);
    }
  };

  useEffect(() => {
    if (activeTenant) {
      fetchActiveTenantData();
    }
  }, [activeTenant]);

  const switchTenant = (slugOrId: string) => {
    const found = availableTenants.find(
      (c) => c.slug === slugOrId || c.id === slugOrId
    );
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
        tenantData,
        hasAccess,
        isCustomTenant,
        isLoading,
        switchTenant,
        refreshTenantData: fetchActiveTenantData,
      }}
    >
      {children}
    </TenantContext.Provider>
  );
}

export function useTenant() {
  return useContext(TenantContext);
}
