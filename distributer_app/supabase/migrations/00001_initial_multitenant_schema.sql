-- =============================================================================
-- Katha Management v2.0 - Multi-Tenant B2B SaaS Schema (Supabase PostgreSQL)
-- Panels:
--   1. Super Admin Panel (/admin-web) -> Manages Companies & Subscriptions
--   2. Company Panel (/company-web)   -> Manages Products, Territories, Distributors, Orders
--   3. Distributor App (Flutter)      -> Field Sales, Offline Khata, Orders (via PowerSync)
-- =============================================================================

create extension if not exists "pgcrypto";

-- 1. COMPANIES (Tenants managed by Super Admin)
create table if not exists public.companies (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text unique not null,
  plan_tier text not null default 'PREMIUM' check (plan_tier in ('FREE', 'PREMIUM', 'ENTERPRISE')),
  subscription_status text not null default 'ACTIVE' check (subscription_status in ('TRIAL', 'ACTIVE', 'PAST_DUE', 'SUSPENDED')),
  max_distributors int not null default 10,
  subscription_expires_at timestamptz,
  created_by_super_admin uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 2. USER PROFILES (RBAC across Super Admin, Company Admin, Distributor)
create table if not exists public.user_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  company_id uuid references public.companies(id) on delete set null,
  role text not null check (role in ('SUPER_ADMIN', 'COMPANY_ADMIN', 'DISTRIBUTOR', 'FREE_STANDALONE')),
  full_name text not null,
  phone text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 3. TERRITORIES (Managed by Company Admin)
create table if not exists public.territories (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  name text not null,
  region_code text,
  created_at timestamptz not null default now()
);

-- 4. DISTRIBUTOR TERRITORIES (Many-to-Many assignment)
create table if not exists public.distributor_territories (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  distributor_id uuid not null references public.user_profiles(id) on delete cascade,
  territory_id uuid not null references public.territories(id) on delete cascade,
  assigned_at timestamptz not null default now(),
  unique (distributor_id, territory_id)
);

-- 5. INVITE TOKENS (Issued by Company Admin to onboard Distributors)
create table if not exists public.invite_tokens (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  territory_id uuid references public.territories(id) on delete set null,
  token_hash text not null unique,
  token_prefix text not null,
  status text not null default 'PENDING' check (status in ('PENDING', 'CLAIMED', 'REVOKED', 'EXPIRED')),
  failed_attempts int not null default 0,
  claimed_by uuid references public.user_profiles(id) on delete set null,
  expires_at timestamptz not null,
  created_at timestamptz not null default now()
);

-- Enable Row Level Security (RLS) on all tables
alter table public.companies enable row level security;
alter table public.user_profiles enable row level security;
alter table public.territories enable row level security;
alter table public.distributor_territories enable row level security;
alter table public.invite_tokens enable row level security;

