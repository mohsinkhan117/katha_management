"use client";

import React, { createContext, useContext, useState, useEffect, useCallback } from "react";
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
  is_active?: boolean;
  is_expired?: boolean;
  days_remaining?: number | null;
  trial_started_at?: string | null;
  expires_at?: string | null;
}

export interface ProductSize {
  id?: string;
  productId?: string;
  label: string;
  price: number;
  discountPercentage?: number;
  finalPrice: number;
  costPrice?: number;
  sortOrder?: number;
}

export interface ProductItem {
  id: string;
  name: string;
  sku: string;
  category: string;
  unit?: string;
  description?: string;
  imageUrl?: string;
  retailPrice: number;
  unitPrice: number;
  discountPercentage: number;
  finalPrice: number;
  costPrice?: number;
  stockQuantity: number;
  status: "inStock" | "outOfStock";
  isActive: boolean;
  sizes?: ProductSize[];
  createdAt?: string;
}

export interface TenantDataPayload {
  metrics: {
    totalOrders: number;
    totalSales: number;
    totalPaid: number;
    totalProfit: number;
    outstandingReceivables?: number;
    recoveryRate?: number;
  };
  orderStatuses?: Array<{
    status: "Delivered" | "In Transit" | "Pending" | "Cancelled";
    count: number;
    percentage: number;
    color: string;
  }>;
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
  products?: ProductItem[];
  parties?: Array<{
    id: string;
    name: string;
    ownerName?: string;
    phone?: string;
    territory?: string;
    balance?: number;
    createdAt?: string;
  }>;
}

interface TenantContextType {
  activeTenant: TenantInfo | null;
  availableTenants: TenantInfo[];
  tenantData: TenantDataPayload | null;
  hasAccess: boolean;
  isDeactivated: boolean;
  deactivationReason: string | null;
  isCustomTenant: boolean;
  isLoading: boolean;
  switchTenant: (slugOrId: string) => void;
  refreshTenantData: () => Promise<void>;
  updateTenantProfile: (data: { name?: string; phone?: string; address?: string; adminEmail?: string }) => Promise<{ success: boolean; error?: string }>;
  createOrder: (order: { partyName: string; distributorName?: string; totalAmount: number; paidAmount?: number; status?: string; itemsCount?: number }) => Promise<{ success: boolean; error?: string }>;
  recordCollection: (collection: { orderId?: string; partyName?: string; amount: number }) => Promise<{ success: boolean; error?: string }>;
  createProduct: (product: {
    name: string;
    sku?: string;
    category?: string;
    unit?: string;
    description?: string;
    imageUrl?: string;
    retailPrice?: number;
    unitPrice?: number;
    discountPercentage?: number;
    finalPrice?: number;
    costPrice?: number;
    stockQuantity?: number;
    status?: "inStock" | "outOfStock";
    sizes?: Array<{
      label: string;
      price: number;
      discountPercentage?: number;
      finalPrice?: number;
      costPrice?: number;
    }>;
  }) => Promise<{ success: boolean; error?: string }>;
  deleteProduct: (productId: string) => Promise<{ success: boolean; error?: string }>;
  issueToken: (tokenData: { territoryName?: string; distributorName?: string; phone?: string }) => Promise<{ success: boolean; token?: any; error?: string }>;
}

const TenantContext = createContext<TenantContextType>({
  activeTenant: null,
  availableTenants: [],
  tenantData: null,
  hasAccess: true,
  isDeactivated: false,
  deactivationReason: null,
  isCustomTenant: false,
  isLoading: true,
  switchTenant: () => {},
  refreshTenantData: async () => {},
  updateTenantProfile: async () => ({ success: false }),
  createOrder: async () => ({ success: false }),
  recordCollection: async () => ({ success: false }),
  createProduct: async () => ({ success: false }),
  deleteProduct: async () => ({ success: false }),
  issueToken: async () => ({ success: false }),
});

export function TenantProvider({ children }: { children: React.ReactNode }) {
  const user = useUser();
  const [activeTenant, setActiveTenant] = useState<TenantInfo | null>(null);
  const [availableTenants, setAvailableTenants] = useState<TenantInfo[]>([]);
  const [tenantData, setTenantData] = useState<TenantDataPayload | null>(null);
  const [hasAccess, setHasAccess] = useState<boolean>(false);
  const [isDeactivated, setIsDeactivated] = useState<boolean>(false);
  const [deactivationReason, setDeactivationReason] = useState<string | null>(null);
  const [isCustomTenant, setIsCustomTenant] = useState<boolean>(true);
  const [isLoading, setIsLoading] = useState(true);

  // Fetch tenant data for active tenant
  const fetchTenantDataFor = useCallback(async (tenant: TenantInfo) => {
    try {
      const res = await fetch(
        `/api/tenant/data?companyId=${encodeURIComponent(tenant.id)}&slug=${encodeURIComponent(tenant.slug)}`,
        {
          credentials: "include",
          headers: {
            "x-tenant-id": tenant.id,
            "x-user-email": tenant.admin_email || "",
          },
        }
      );
      const json = await res.json();

      if (json.success) {
        setTenantData({
          metrics: json.metrics || { totalOrders: 0, totalSales: 0, totalPaid: 0, totalProfit: 0 },
          orderStatuses: json.orderStatuses || [],
          distributors: json.distributors || [],
          orders: json.orders || [],
          products: json.products || [],
          parties: json.parties || [],
        });
      }
    } catch (err) {
      console.error("Failed to fetch tenant data:", err);
    }
  }, []);

  const refreshTenantData = useCallback(async () => {
    if (activeTenant) {
      await fetchTenantDataFor(activeTenant);
    }
  }, [activeTenant, fetchTenantDataFor]);

  // Load / Sync Tenant ONLY when User is authenticated
  useEffect(() => {
    let isCancelled = false;

    async function syncUserTenant() {
      try {
        setIsLoading(true);
        const userEmail = user?.primaryEmail?.toLowerCase();
        const displayName = user?.displayName || (userEmail ? userEmail.split("@")[0] : null);

        if (!userEmail) {
          // Never auto-login to any pre-created tenant when not signed in
          if (!isCancelled) {
            setActiveTenant(null);
            setAvailableTenants([]);
            setTenantData(null);
            setHasAccess(false);
            setIsDeactivated(false);
            setDeactivationReason(null);
          }
          return;
        }

        // Logged-in user:
        // - If Super Admin provisioned a tenant for this email -> Sign-In binds strictly to that tenant
        // - If new Sign-Up -> Activates 1-Month Free Tier (expires after 30 days)
        const syncRes = await fetch("/api/tenant", {
          method: "POST",
          credentials: "include",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            email: userEmail,
            name: displayName ? `${displayName.charAt(0).toUpperCase() + displayName.slice(1)} Commercial` : undefined,
          }),
        });
        const syncJson = await syncRes.json();

        if (!isCancelled && syncJson.success && syncJson.company) {
          const company: TenantInfo = syncJson.company;
          const deactivated = Boolean(syncJson.isDeactivated || company.is_active === false || company.is_expired);
          setActiveTenant(company);
          setAvailableTenants([company]);
          setIsDeactivated(deactivated);
          setDeactivationReason(syncJson.deactivationReason || null);
          setHasAccess(!deactivated);
          setIsCustomTenant(true);
          if (!deactivated) {
            await fetchTenantDataFor(company);
          }
          return;
        }
      } catch (err) {
        console.error("Failed to initialize tenant context:", err);
        if (!isCancelled) {
          setActiveTenant(null);
          setAvailableTenants([]);
          setHasAccess(false);
        }
      } finally {
        if (!isCancelled) setIsLoading(false);
      }
    }

    syncUserTenant();

    return () => {
      isCancelled = true;
    };
  }, [user, fetchTenantDataFor]);

  const switchTenant = (slugOrId: string) => {
    const found = availableTenants.find(
      (c) => c.slug === slugOrId || c.id === slugOrId
    );
    if (found) {
      setActiveTenant(found);
      if (typeof window !== "undefined") {
        localStorage.setItem("katha_selected_tenant_slug", found.slug);
      }
      fetchTenantDataFor(found);
    }
  };

  // Update company profile in Neon DB and state
  const updateTenantProfile = async (data: { name?: string; phone?: string; address?: string; adminEmail?: string }) => {
    if (!activeTenant) return { success: false, error: "No active tenant" };

    try {
      const res = await fetch("/api/tenant", {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          id: activeTenant.id,
          ...data,
        }),
      });
      const json = await res.json();
      if (json.success && json.company) {
        const updated = json.company;
        setActiveTenant(updated);
        setAvailableTenants((prev) =>
          prev.map((c) => (c.id === updated.id ? updated : c))
        );
        return { success: true };
      }
      return { success: false, error: json.error || "Failed to update profile" };
    } catch (err: any) {
      return { success: false, error: err.message };
    }
  };

  // Create B2B Order in Neon DB
  const createOrder = async (order: { partyName: string; distributorName?: string; totalAmount: number; paidAmount?: number; status?: string; itemsCount?: number }) => {
    if (!activeTenant) return { success: false, error: "No active tenant" };

    try {
      const res = await fetch("/api/tenant/data", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          action: "create_order",
          companyId: activeTenant.id,
          ...order,
        }),
      });
      const json = await res.json();
      if (json.success) {
        await refreshTenantData();
        return { success: true };
      }
      return { success: false, error: json.error || "Failed to create order" };
    } catch (err: any) {
      return { success: false, error: err.message };
    }
  };

  // Record Collection in Neon DB
  const recordCollection = async (collection: { orderId?: string; partyName?: string; amount: number }) => {
    if (!activeTenant) return { success: false, error: "No active tenant" };

    try {
      const res = await fetch("/api/tenant/data", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          action: "record_collection",
          companyId: activeTenant.id,
          ...collection,
        }),
      });
      const json = await res.json();
      if (json.success) {
        await refreshTenantData();
        return { success: true };
      }
      return { success: false, error: json.error || "Failed to record collection" };
    } catch (err: any) {
      return { success: false, error: err.message };
    }
  };

  // Create Product SKU with Sizes in Neon DB
  const createProduct = async (product: {
    name: string;
    sku?: string;
    category?: string;
    unit?: string;
    description?: string;
    imageUrl?: string;
    retailPrice?: number;
    unitPrice?: number;
    discountPercentage?: number;
    finalPrice?: number;
    costPrice?: number;
    stockQuantity?: number;
    status?: "inStock" | "outOfStock";
    sizes?: Array<{
      label: string;
      price: number;
      discountPercentage?: number;
      finalPrice?: number;
      costPrice?: number;
    }>;
  }) => {
    if (!activeTenant) return { success: false, error: "No active tenant" };

    try {
      const res = await fetch("/api/tenant/data", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          action: "create_product",
          companyId: activeTenant.id,
          ...product,
        }),
      });
      const json = await res.json();
      if (json.success) {
        await refreshTenantData();
        return { success: true };
      }
      return { success: false, error: json.error || "Failed to add product" };
    } catch (err: any) {
      return { success: false, error: err.message };
    }
  };

  // Delete Product and associated sizes in Neon DB
  const deleteProduct = async (productId: string) => {
    if (!activeTenant) return { success: false, error: "No active tenant" };

    try {
      const res = await fetch("/api/tenant/data", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          action: "delete_product",
          companyId: activeTenant.id,
          productId,
        }),
      });
      const json = await res.json();
      if (json.success) {
        await refreshTenantData();
        return { success: true };
      }
      return { success: false, error: json.error || "Failed to delete product" };
    } catch (err: any) {
      return { success: false, error: err.message };
    }
  };

  // Issue Distributor Token in Neon DB
  const issueToken = async (tokenData: { territoryName?: string; distributorName?: string; phone?: string }) => {
    if (!activeTenant) return { success: false, error: "No active tenant" };

    try {
      const res = await fetch("/api/tenant/data", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          companyId: activeTenant.id,
          ...tokenData,
        }),
      });
      const json = await res.json();
      if (json.success && json.token) {
        await refreshTenantData();
        return { success: true, token: json.token };
      }
      return { success: false, error: json.error || "Failed to generate token" };
    } catch (err: any) {
      return { success: false, error: err.message };
    }
  };

  return (
    <TenantContext.Provider
      value={{
        activeTenant,
        availableTenants,
        tenantData,
        hasAccess,
        isDeactivated,
        deactivationReason,
        isCustomTenant,
        isLoading,
        switchTenant,
        refreshTenantData,
        updateTenantProfile,
        createOrder,
        recordCollection,
        createProduct,
        deleteProduct,
        issueToken,
      }}
    >
      {children}
    </TenantContext.Provider>
  );
}

export function useTenant() {
  const context = useContext(TenantContext);
  if (!context) {
    throw new Error("useTenant must be used within a TenantProvider");
  }
  return context;
}
