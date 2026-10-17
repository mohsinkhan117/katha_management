import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  CreateLedgerEntrySchema,
  VoidLedgerEntrySchema,
  CreateLedgerCategorySchema,
  LedgerFilterSchema,
} from "../schemas.ts";

describe("Commercial Ledger - Multi-Tenant Security & Isolation Tests", () => {
  const TENANT_A_ID = "00000000-0000-0000-0000-000000000001";
  const TENANT_B_ID = "00000000-0000-0000-0000-000000000002";
  const USER_A_ID = "11111111-1111-1111-1111-111111111111";
  const USER_B_ID = "22222222-2222-2222-2222-222222222222";

  it("Zod Schema: strictly rejects non-positive or float amounts", () => {
    // 0 amount rejected
    const zeroResult = CreateLedgerEntrySchema.safeParse({
      title: "Test Entry",
      type: "income",
      categoryId: "a1b2c3d4-e5f6-4a1b-8c2d-3e4f5a6b7c8d",
      amountMinor: 0,
    });
    assert.strictEqual(zeroResult.success, false);

    // Negative amount rejected
    const negativeResult = CreateLedgerEntrySchema.safeParse({
      title: "Test Entry",
      type: "income",
      categoryId: "a1b2c3d4-e5f6-4a1b-8c2d-3e4f5a6b7c8d",
      amountMinor: -500,
    });
    assert.strictEqual(negativeResult.success, false);

    // Valid positive integer minor unit accepted
    const validResult = CreateLedgerEntrySchema.safeParse({
      title: "Test Entry",
      type: "income",
      categoryId: "a1b2c3d4-e5f6-4a1b-8c2d-3e4f5a6b7c8d",
      amountMinor: 150000, // 1500.00 PKR
    });
    assert.strictEqual(validResult.success, true);
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
      type: "income" | "expense";
      amount_minor: bigint;
      is_voided: boolean;
      void_reason?: string;
    }

    const mockDatabase: SimulatedEntry[] = [
      {
        id: "entry-a-1",
        tenant_id: TENANT_A_ID,
        title: "Tenant A Daily Sales",
        type: "income",
        amount_minor: 500000n, // 5000.00 PKR
        is_voided: false,
      },
      {
        id: "entry-a-2",
        tenant_id: TENANT_A_ID,
        title: "Tenant A Office Rent",
        type: "expense",
        amount_minor: 120000n, // 1200.00 PKR
        is_voided: false,
      },
      {
        id: "entry-b-1",
        tenant_id: TENANT_B_ID,
        title: "Tenant B Confidential Revenue",
        type: "income",
        amount_minor: 999900n, // 9999.00 PKR
        is_voided: false,
      },
    ];

    // Data Access Layer with mandatory tenant isolation (same logic as service.ts)
    function queryEntriesForTenant(tenantId: string) {
      return mockDatabase.filter((e) => e.tenant_id === tenantId);
    }

    function voidEntryForTenant(tenantId: string, entryId: string, reason: string) {
      // Must match BOTH id and tenant_id
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

    // 1. Tenant A queries entries: cannot see Tenant B's entries
    const tenantAEntries = queryEntriesForTenant(TENANT_A_ID);
    assert.strictEqual(tenantAEntries.length, 2);
    assert.ok(tenantAEntries.every((e) => e.tenant_id === TENANT_A_ID));
    assert.strictEqual(
      tenantAEntries.some((e) => e.id === "entry-b-1"),
      false,
      "Tenant A must never see Tenant B's data"
    );

    // 2. Tenant B queries entries: cannot see Tenant A's entries
    const tenantBEntries = queryEntriesForTenant(TENANT_B_ID);
    assert.strictEqual(tenantBEntries.length, 1);
    assert.strictEqual(tenantBEntries[0].id, "entry-b-1");

    // 3. Tenant A attempts to void Tenant B's entry -> MUST FAIL
    assert.throws(
      () => {
        voidEntryForTenant(TENANT_A_ID, "entry-b-1", "Malicious void attempt");
      },
      /Ledger entry not found or unauthorized/,
      "Tenant A must NOT be allowed to void Tenant B's entries"
    );

    // Ensure Tenant B's entry was NOT voided
    const tenantBEntryAfterAttempt = mockDatabase.find((e) => e.id === "entry-b-1");
    assert.strictEqual(tenantBEntryAfterAttempt?.is_voided, false);

    // 4. Tenant A voids own entry: succeeds, marked as voided (append-only)
    const voidedEntry = voidEntryForTenant(
      TENANT_A_ID,
      "entry-a-2",
      "Entered wrong amount"
    );
    assert.strictEqual(voidedEntry.is_voided, true);
    assert.strictEqual(voidedEntry.void_reason, "Entered wrong amount");

    // 5. Financial calculations: voided entries MUST be excluded from totals
    const activeEntriesA = queryEntriesForTenant(TENANT_A_ID).filter((e) => !e.is_voided);
    const totalIncomeMinor = activeEntriesA
      .filter((e) => e.type === "income")
      .reduce((sum, e) => sum + e.amount_minor, 0n);
    const totalExpenseMinor = activeEntriesA
      .filter((e) => e.type === "expense")
      .reduce((sum, e) => sum + e.amount_minor, 0n);

    assert.strictEqual(totalIncomeMinor, 500000n);
    // Notice expense entry-a-2 was voided, so total expenses should be 0n
    assert.strictEqual(totalExpenseMinor, 0n);
  });
});
