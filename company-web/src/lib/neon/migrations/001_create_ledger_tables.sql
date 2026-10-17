-- Migration: 001_create_ledger_tables.sql
-- Description: Multi-tenant append-only party/hotel item purchase & expense khata ledger

-- 1. Ledger Categories Table
CREATE TABLE IF NOT EXISTS ledger_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id VARCHAR(64) NOT NULL,
  name VARCHAR(128) NOT NULL,
  type VARCHAR(16) NOT NULL CHECK (type IN ('income', 'expense')),
  is_default BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_tenant_category_name UNIQUE (tenant_id, name)
);

CREATE INDEX IF NOT EXISTS idx_ledger_categories_tenant ON ledger_categories (tenant_id, type);

-- 2. Ledger Entries Table (Append-only, minor units, item quantity & cost price tracking, voiding audit)
CREATE TABLE IF NOT EXISTS ledger_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id VARCHAR(64) NOT NULL,
  type VARCHAR(16) NOT NULL DEFAULT 'expense' CHECK (type IN ('income', 'expense')),
  title VARCHAR(255) NOT NULL,
  category_id UUID NOT NULL REFERENCES ledger_categories(id),
  quantity NUMERIC(12, 2) NOT NULL DEFAULT 1,
  unit VARCHAR(32) NOT NULL DEFAULT 'pcs',
  unit_cost_minor BIGINT,
  amount_minor BIGINT NOT NULL CHECK (amount_minor > 0),
  vendor_name VARCHAR(255),
  currency CHAR(3) NOT NULL DEFAULT 'PKR',
  payment_method VARCHAR(16) CHECK (payment_method IN ('cash', 'card', 'online', 'other')),
  occurred_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  added_by VARCHAR(128) NOT NULL,
  added_by_name VARCHAR(255) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  is_voided BOOLEAN NOT NULL DEFAULT false,
  voided_at TIMESTAMP WITH TIME ZONE,
  voided_by VARCHAR(128),
  void_reason TEXT
);

-- Ensure columns exist on upgraded databases
ALTER TABLE ledger_entries ADD COLUMN IF NOT EXISTS quantity NUMERIC(12, 2) NOT NULL DEFAULT 1;
ALTER TABLE ledger_entries ADD COLUMN IF NOT EXISTS unit VARCHAR(32) NOT NULL DEFAULT 'pcs';
ALTER TABLE ledger_entries ADD COLUMN IF NOT EXISTS unit_cost_minor BIGINT;
ALTER TABLE ledger_entries ADD COLUMN IF NOT EXISTS vendor_name VARCHAR(255);

-- Optimized Multi-tenant Indexes
CREATE INDEX IF NOT EXISTS idx_ledger_entries_tenant_occurred ON ledger_entries (tenant_id, occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_ledger_entries_tenant_category ON ledger_entries (tenant_id, category_id);
CREATE INDEX IF NOT EXISTS idx_ledger_entries_tenant_type_occurred ON ledger_entries (tenant_id, type, occurred_at);
CREATE INDEX IF NOT EXISTS idx_ledger_entries_tenant_void ON ledger_entries (tenant_id, is_voided);
