import { z } from "zod";

export const LedgerTypeEnum = z.enum(["income", "expense"]);
export type LedgerType = z.infer<typeof LedgerTypeEnum>;

export const PaymentMethodEnum = z.enum(["cash", "card", "online", "other"]);
export type PaymentMethod = z.infer<typeof PaymentMethodEnum>;

export const LedgerPeriodEnum = z.enum(["daily", "weekly", "monthly", "yearly", "all", "custom"]);
export type LedgerPeriod = z.infer<typeof LedgerPeriodEnum>;

// Entry Creation Validator (Hotel / Party Item & Expense Purchase Tracking)
export const CreateLedgerEntrySchema = z.object({
  type: LedgerTypeEnum.default("expense"),
  title: z.string().trim().min(1, "Item name / title is required").max(255),
  categoryId: z.string().trim().optional().nullable(),
  categoryName: z.string().trim().optional().nullable(),
  quantity: z.coerce.number().positive("Quantity must be greater than 0").default(1),
  unit: z.string().trim().min(1).max(32).default("pcs"),
  unitCostMinor: z.coerce.number().int().nonnegative().optional().nullable(),
  amountMinor: z.number().int("Cost must be in integer minor units").positive("Total cost must be greater than 0"),
  vendorName: z.string().trim().max(255).optional().nullable(),
  currency: z.string().length(3).default("PKR"),
  paymentMethod: PaymentMethodEnum.optional().nullable(),
  occurredAt: z.string().optional(), // ISO string, defaults to now()
});
export type CreateLedgerEntryInput = z.infer<typeof CreateLedgerEntrySchema>;

// Entry Void Validator
export const VoidLedgerEntrySchema = z.object({
  reason: z.string().trim().min(3, "Void reason must be at least 3 characters").max(500),
});
export type VoidLedgerEntryInput = z.infer<typeof VoidLedgerEntrySchema>;

// Category Creation Validator
export const CreateLedgerCategorySchema = z.object({
  name: z.string().trim().min(2, "Category name must be at least 2 characters").max(128),
  type: LedgerTypeEnum.default("expense"),
});
export type CreateLedgerCategoryInput = z.infer<typeof CreateLedgerCategorySchema>;

// Query Filters Validator (Supports specific Date, Month, Year, Daily/Weekly/Monthly/Yearly views)
export const LedgerFilterSchema = z.object({
  period: LedgerPeriodEnum.optional(),
  date: z.string().optional(), // YYYY-MM-DD
  month: z.coerce.number().int().min(1).max(12).optional(), // 1 - 12
  year: z.coerce.number().int().min(2000).max(2100).optional(), // e.g. 2026
  from: z.string().optional(),
  to: z.string().optional(),
  type: LedgerTypeEnum.optional(),
  categoryId: z.string().optional(),
  addedBy: z.string().optional(),
  search: z.string().optional(),
  includeVoided: z.string().optional(),
  sort: z.string().optional().default("occurred_at:desc"),
  page: z.coerce.number().int().positive().default(1),
  offset: z.coerce.number().int().nonnegative().optional(),
  limit: z.coerce.number().int().min(1).max(10000).default(50),
});
export type LedgerFilterInput = z.infer<typeof LedgerFilterSchema>;
