import { z } from "zod";

export const LedgerTypeEnum = z.enum(["income", "expense"]);
export type LedgerType = z.infer<typeof LedgerTypeEnum>;

export const PaymentMethodEnum = z.enum(["cash", "card", "online", "other"]);
export type PaymentMethod = z.infer<typeof PaymentMethodEnum>;

// Entry Creation Validator
export const CreateLedgerEntrySchema = z.object({
  type: LedgerTypeEnum,
  title: z.string().trim().min(2, "Title must be at least 2 characters").max(255),
  categoryId: z.string().uuid("Invalid category ID format"),
  amountMinor: z.number().int("Amount must be in integer minor units").positive("Amount must be greater than 0"),
  currency: z.string().length(3).default("PKR"),
  paymentMethod: PaymentMethodEnum.optional().nullable(),
  occurredAt: z.string().datetime().optional(), // ISO string, defaults to now()
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
  type: LedgerTypeEnum,
});
export type CreateLedgerCategoryInput = z.infer<typeof CreateLedgerCategorySchema>;

// Query Filters Validator
export const LedgerFilterSchema = z.object({
  from: z.string().optional(),
  to: z.string().optional(),
  type: LedgerTypeEnum.optional(),
  categoryId: z.string().optional(),
  addedBy: z.string().optional(),
  search: z.string().optional(),
  sort: z.enum(["occurred_at:asc", "occurred_at:desc", "amount_minor:asc", "amount_minor:desc"]).default("occurred_at:desc"),
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().min(1).max(100).default(50),
});
export type LedgerFilterInput = z.infer<typeof LedgerFilterSchema>;

