export type Timeframe = "daily" | "weekly" | "monthly";

export interface MetricSummary {
  title: string;
  value: string;
  numericValue: number;
  changePercent: number;
  isPositive: boolean;
  comparedTo: string;
  subText: string;
  secondaryMetric?: {
    label: string;
    value: string;
  };
}

export interface DashboardMetrics {
  sales: MetricSummary;
  profit: MetricSummary;
  collections: MetricSummary;
  orders: MetricSummary;
}

export interface ChartDataPoint {
  label: string;
  sales: number;
  profit: number;
  collections: number;
  orders: number;
}

export interface OrderStatusStat {
  status: "Delivered" | "In Transit" | "Pending" | "Cancelled";
  count: number;
  percentage: number;
  color: string;
}

export interface TopProduct {
  id: string;
  name: string;
  sku: string;
  category: string;
  unitsSold: number;
  revenue: number;
  marginPercent: number;
}

export interface RecentTransaction {
  id: string;
  orderNumber: string;
  partyName: string;
  distributorName: string;
  amount: number;
  status: "Completed" | "Pending" | "Processing" | "Credit Ledger";
  type: "Order" | "Collection";
  time: string;
}

export interface DashboardDataset {
  periodLabel: string;
  dateRange: string;
  metrics: DashboardMetrics;
  chartData: ChartDataPoint[];
  orderStatuses: OrderStatusStat[];
  collectionsBreakdown: {
    cash: number;
    bankTransfer: number;
    cheque: number;
    outstandingReceivables: number;
    collectionEfficiency: number;
  };
  topProducts: TopProduct[];
  recentTransactions: RecentTransaction[];
}

