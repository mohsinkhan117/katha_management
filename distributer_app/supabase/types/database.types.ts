export type UserRole =
  | 'SUPER_ADMIN'
  | 'COMPANY_ADMIN'
  | 'DISTRIBUTOR'
  | 'FREE_STANDALONE';

export type SubscriptionPlan = 'FREE' | 'PREMIUM' | 'ENTERPRISE';
export type SubscriptionStatus = 'TRIAL' | 'ACTIVE' | 'PAST_DUE' | 'SUSPENDED';

export interface Company {
  id: string;
  name: string;
  slug: string;
  plan_tier: SubscriptionPlan;
  subscription_status: SubscriptionStatus;
  max_distributors: number;
  subscription_expires_at: string | null;
  created_at: string;
}

export interface UserProfile {
  id: string;
  company_id: string | null;
  role: UserRole;
  full_name: string;
  phone: string | null;
  is_active: boolean;
  created_at: string;
}

export interface Territory {
  id: string;
  company_id: string;
  name: string;
  region_code: string | null;
  created_at: string;
}

export interface InviteToken {
  id: string;
  company_id: string;
  territory_id: string | null;
  token_prefix: string;
  status: 'PENDING' | 'CLAIMED' | 'REVOKED' | 'EXPIRED';
  expires_at: string;
  created_at: string;
}

