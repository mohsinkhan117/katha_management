import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  CreateLedgerEntrySchema,
  VoidLedgerEntrySchema,
  CreateLedgerCategorySchema,
  LedgerFilterSchema,
} from "../schemas.ts";

describe("Commercial Ledger - Multi-Tenant Security, Item Tracking & Date/Month/Year Filters", () => {
  const TENANT_A_ID = "00000000-0000-0000-0000-000000000001";
  const TENANT_B_ID = "00000000-0000-0000-0000-000000000002";

  it("Zod Schema: strictly rejects non-positive or float amounts", () => {
    const zeroResult = CreateLedgerEntrySchema.safeParse({
      title: "Chicken",
      type: "expense",
      categoryId: "a1b2c3d4-e5f6-4a1b-8c2d-3e4f5a6b7c8d",
      quantity: 100,
      unit: "pcs",
      amountMinor: 0,
    });
    assert.strictEqual(zeroResult.success, false);

    const negativeResult = CreateLedgerEntrySchema.safeParse({
      title: "Chicken",
      type: "expense",
      categoryId: "a1b2c3d4-e5f6-4a1b-8c2d-3e4f5a6b7c8d",
      quantity: 100,
      unit: "pcs",
      amountMinor: -500,
    });
    assert.strictEqual(negativeResult.success, false);

    const validHotelPurchase = CreateLedgerEntrySchema.safeParse({
      title: "Chicken",
      type: "expense",
      categoryId: "a1b2c3d4-e5f6-4a1b-8c2d-3e4f5a6b7c8d",
      quantity: 100,
      unit: "pcs",
      unitCostMinor: 45000, // Rs. 450 per chicken
      amountMinor: 4500000, // Rs. 45,000 total cost
      vendorName: "Al-Fatah Poultry",
    });
    assert.strictEqual(validHotelPurchase.success, true);
    if (validHotelPurchase.success) {
      assert.strictEqual(validHotelPurchase.data.quantity, 100);
      assert.strictEqual(validHotelPurchase.data.unit, "pcs");
      assert.strictEqual(validHotelPurchase.data.amountMinor, 4500000);
    }
  });

  it("Zod Schema: supports Date, Month, and Year filters", () => {
    const filterResult = LedgerFilterSchema.safeParse({
      date: "2026-10-17",
      month: "10",
      year: "2026",
      period: "monthly",
    });
    assert.strictEqual(filterResult.success, true);
    if (filterResult.success) {
      assert.strictEqual(filterResult.data.date, "2026-10-17");
      assert.strictEqual(filterResult.data.month, 10);
      assert.strictEqual(filterResult.data.year, 2026);
    }
  });

  it("Zod Schema: voiding strictly requires at least 3 characters reason", () => {
    const invalidShort = VoidLedgerEntrySchema.safeParse({ reason: "no" });
    assert.strictEqual(invalidShort.success, false);

    const invalidEmpty = VoidLedgerEntrySchema.safeParse({ reason: "   " });
    assert.strictEqual(invalidEmpty.success, false);

    const validReason = VoidLedgerEntrySchema.safeParse({
      reason: "Recorded duplicate transaction by mistake",
    });
    assert.strictEqual(validReason.success, true);
  });

  it("Multi-Tenant Isolation: Simulated store guarantees tenant filtering", () => {
    interface SimulatedEntry {
      id: string;
      tenant_id: string;
      title: string;
      quantity: number;
      unit: string;
      type: "income" | "expense";
      amount_minor: bigint;
      is_voided: boolean;
      void_reason?: string;
    }

    const mockDatabase: SimulatedEntry[] = [
      {
        id: "entry-a-1",
        tenant_id: TENANT_A_ID,
        title: "Chicken",
        quantity: 100,
        unit: "pcs",
        type: "expense",
        amount_minor: 4500000n,
        is_voided: false,
      },
      {
        id: "entry-a-2",
        tenant_id: TENANT_A_ID,
        title: "Basmati Rice",
        quantity: 50,
        unit: "kg",
        type: "expense",
        amount_minor: 1500000n,
        is_voided: false,
      },
      {
        id: "entry-b-1",
        tenant_id: TENANT_B_ID,
        title: "Tenant B Confidential Item",
        quantity: 20,
        unit: "kg",
        type: "expense",
        amount_minor: 999900n,
        is_voided: false,
      },
    ];

    function queryEntriesForTenant(tenantId: string) {
      return mockDatabase.filter((e) => e.tenant_id === tenantId);
    }

    function voidEntryForTenant(tenantId: string, entryId: string, reason: string) {
      const entry = mockDatabase.find(
        (e) => e.id === entryId && e.tenant_id === tenantId
      );
      if (!entry) {
        throw new Error("Ledger entry not found or unauthorized");
      }
      entry.is_voided = true;
      entry.void_reason = reason;
      return entry;
    }

    const tenantAEntries = queryEntriesForTenant(TENANT_A_ID);
    assert.strictEqual(tenantAEntries.length, 2);
    assert.ok(tenantAEntries.every((e) => e.tenant_id === TENANT_A_ID));
    assert.strictEqual(
      tenantAEntries.some((e) => e.id === "entry-b-1"),
      false,
      "Tenant A must never see Tenant B's data"
    );

    assert.throws(
      () => {
        voidEntryForTenant(TENANT_A_ID, "entry-b-1", "Malicious void attempt");
      },
      /Ledger entry not found or unauthorized/,
      "Tenant A must NOT be allowed to void Tenant B's entries"
    );

    const voidedEntry = voidEntryForTenant(
      TENANT_A_ID,
      "entry-a-2",
      "Entered wrong quantity"
    );
    assert.strictEqual(voidedEntry.is_voided, true);

    const activeEntriesA = queryEntriesForTenant(TENANT_A_ID).filter((e) => !e.is_voided);
    const totalExpenseMinor = activeEntriesA.reduce((sum, e) => sum + e.amount_minor, 0n);
    assert.strictEqual(totalExpenseMinor, 4500000n);
  });
});
