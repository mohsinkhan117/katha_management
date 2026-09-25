// lib/core/constants/app_strings/app_strings.dart

/// Centralized repository of all user-facing strings across the Katha Management app.
class AppStrings {
  AppStrings._();

  // ─── General & Common ──────────────────────────────────────────
  static const String appTitle = 'Katha Management';
  static const String currency = 'Rs';
  static const String currencyPrefix = 'Rs ';
  static const String percentSuffix = '%';
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String update = 'Update';
  static const String retry = 'Retry';
  static const String refresh = 'Refresh';
  static const String clear = 'Clear';
  static const String add = 'Add';
  static const String yes = 'Yes';
  static const String no = 'No';
  static const String all = 'All';
  static const String note = 'Note';
  static const String noteOptional = 'Note (optional)';
  static const String optional = 'Optional';
  static const String status = 'Status';
  static const String search = 'Search';
  static const String noPhoneOnFile = 'No phone on file';
  static const String noPhone = 'No phone';

  // ─── Navigation ────────────────────────────────────────────────
  static const String navHome = 'Home';
  static const String navDashboard = 'Dashboard';
  static const String navOrders = 'Orders';
  static const String navCustomers = 'Customers';
  static const String navParties = 'Parties';
  static const String navProducts = 'Products';
  static const String navSettings = 'Settings';

  // ─── Dashboard ─────────────────────────────────────────────────
  static const String dashboardTitle = 'Dashboard';
  static const String todaysSales = "Today's Sales";
  static const String todaysCollection = "Today's Collection";
  static const String receivables = 'Receivables';
  static const String topPendingParties = 'Top Pending Parties';
  static const String recentActivity = 'Recent Activity';
  static const String noPendingBalances = 'No pending balances';
  static const String noRecentActivity = 'No recent activity';
  static const String daysOverdueSuffix = 'd overdue';
  static const String openingBalanceLabel = 'Previous Due (Opening Balance)';
  static const String quickActionNewSale = 'New Sale';
  static const String quickActionNewOrder = 'New Order';
  static const String quickActionAddPayment = 'Add Payment';
  static const String quickActionAddParty = 'Add Party';
  static const String activityTypeSale = 'Sale';
  static const String activityTypePayment = 'Payment';
  static const String activityTypeOrder = 'Order Placed';

  // ─── Customers / Parties ───────────────────────────────────────
  static const String customersTitle = 'Customers';
  static const String addPartyTitle = 'Add Party';
  static const String searchCustomersHint = 'Search by name or phone';
  static const String noCustomersYet = 'No customers yet';
  static const String settled = 'Settled';
  static const String basicInfoSection = 'Basic Info';
  static const String partyNameLabel = 'Party name *';
  static const String partyPhoneLabel = 'Phone (optional)';
  static const String partyAddressLabel = 'Address (optional)';
  static const String categorySection = 'Category';
  static const String openingBalanceSection = 'Previous Due (Opening Balance)';
  static const String openingBalanceAmountLabel =
      'Unpaid Due Amount (optional)';
  static const String openingBalanceHelper =
      'Enter previous unpaid balance / due carried over from before this app';
  static const String openingBalanceInfoNote =
      'Previous unpaid balance carried over from before this app';
  static const String savePartyButton = 'Save Party';
  static const String updatePartyButton = 'Update Party';
  static const String editPartyTitle = 'Edit Party';
  static const String partyAddedSuccess = 'Party added';
  static const String partyUpdatedSuccess = 'Party updated successfully';
  static const String deletePartyTitle = 'Delete Party?';
  static const String deletePartyMessage =
      'Are you sure you want to delete this party? All related transaction history may be affected.';
  static const String deletePartyButton = 'Delete Party';
  static const String partyDeletedSuccess = 'Party deleted successfully';
  static const String partyDetailsSection = 'Party Details';
  static const String selectExistingCustomer = 'Select Existing Customer';
  static const String selectCustomer = 'Select Customer';
  static const String partyNameRequired = 'Party name is required';

  // ─── Orders ────────────────────────────────────────────────────
  static const String ordersTitle = 'Orders';
  static const String tabPending = 'Pending';
  static const String tabDone = 'Done';
  static const String searchOrdersHint =
      'Search orders by party, item, or note...';
  static const String noPendingOrders = 'No pending orders';
  static const String noDoneOrders = 'No completed/cancelled orders';
  static const String newOrderButton = 'New Order';
  static const String editOrderTitle = 'Edit Order';
  static const String updateOrderButton = 'Update Order';
  static const String orderConvertedToSale = 'Order converted to Sale invoice';
  static const String orderedPrefix = 'Ordered: ';
  static const String updatedPrefix = 'Updated: ';
  static const String deliveryByPrefix = 'Delivery by: ';
  static const String viewItems = 'View items';
  static const String hideItems = 'Hide items';
  static const String cancelOrderTooltip = 'Cancel order';
  static const String cancelOrderTitle = 'Cancel Order?';
  static const String cancelOrderMessage =
      'Are you sure you want to cancel this order?';
  static const String yesCancel = 'Yes, Cancel';
  static const String deleteOrderTitle = 'Delete Order?';
  static const String deleteOrderMessage =
      'Are you sure you want to permanently delete this order?';
  static const String deleteOrderButton = 'Delete';
  static const String orderDeletedSuccess = 'Order deleted successfully';
  static const String cannotEditDeliveredOrPaidOrder =
      'Orders that are Delivered or Paid cannot be modified.';
  static const String convertedToSaleBadge = 'Converted to Sale';
  static const String convertToSaleButton = 'Convert to Sale';
  static const String changeStatusTooltip = 'Change Status';
  static const String expectedDeliveryDateLabel = 'Expected Delivery Date';
  static const String expectedDeliveryPrefix = 'Expected Delivery: ';
  static const String expectedDeliveryDateOptional =
      'Expected delivery date (optional)';
  static const String deliveryDateOptional = 'Delivery date (optional)';
  static const String changePartyTooltip = 'Change Party';
  static const String newOrderPlacedStatusInfo =
      'New orders will be created with status: Placed';
  static const String selectExpectedDeliveryDateHint =
      'Select expected delivery date';
  static const String estimatedTotalLabel = 'Estimated Total';
  static const String orderPlacedSuccess = 'Order placed successfully';
  static const String placeOrderButton = 'Place Order';
  static const String orderSavedSuccess = 'Order saved successfully';
  static const String orderUpdatedSuccess = 'Order updated successfully';
  static const String markDelivered = 'Mark Delivered';
  static const String markPaid = 'Mark Paid';
  static const String orderPaidSuccess =
      'Order marked as Paid and balance settled';
  static const String itemSingular = 'item';
  static const String itemsPlural = 'items';

  // ─── Products & Catalog ─────────────────────────────────────────
  static const String productsTitle = 'Products';
  static const String addProductTitle = 'Add Product';
  static const String editProductTitle = 'Edit Product';
  static const String searchProductsHint = 'Search by name or SKU';
  static const String noProductsYet = 'No products yet';
  static const String lowStock = 'Low stock';
  static const String productNameLabel = 'Product name *';
  static const String descriptionOptional = 'Description (optional)';
  static const String skuLabel = 'SKU / Code';
  static const String categoryLabel = 'Category';
  static const String baseUnitLabel = 'Base unit (optional)';
  static const String baseUnitHelper =
      'e.g. piece, kg, box — what sizes below are variants of';
  static const String sellingPriceSection = 'Selling Price';
  static const String sellingPriceDescription =
      'What the customer sees and pays.';
  static const String retailPriceLabel = 'Retail price *';
  static const String discountLabel = 'Discount';
  static const String customerPays = 'Customer Pays';
  static const String costAndProfitMarginSection = 'Cost & Profit Margin';
  static const String costAndProfitMarginDescription =
      'What this product costs you to buy or produce. Used only to show your profit below — customers never see this.';
  static const String costPriceLabel = 'Cost price';
  static const String costPriceOptional = 'Cost price (optional)';
  static const String costPriceHelper =
      'Used to calculate profit margin for this size';
  static const String enterCostPriceHint =
      'Enter a cost price to see your profit margin here.';
  static const String stockQuantityLabel = 'Stock qty (optional)';
  static const String sellingBelowCost = 'Selling Below Cost';
  static const String profitMargin = 'Profit Margin';
  static const String perUnit = 'per unit';
  static const String statusSection = 'Status';
  static const String sizeVariantsSection = 'Size / Price Variants';
  static const String noSizeVariantsNote =
      'No size variants — product will use the retail price above';
  static const String sizeLabel = 'Size label';
  static const String sizeLabelHint = 'e.g. 1 Liter, 5Kg, Dozen';
  static const String priceLabel = 'Price';
  static const String sellingPricePrefix = 'Selling Price: Rs ';
  static const String marginPrefix = 'Margin: Rs ';
  static const String addSizeButton = 'Add Size';
  static const String updateProductButton = 'Update Product';
  static const String saveProductButton = 'Save Product';
  static const String productAddedSuccess = 'Product added';
  static const String productUpdatedSuccess = 'Product updated';
  static const String selectPackageSizeLabel = 'Select Package Size';

  // ─── New Sale & Order Form ─────────────────────────────────────
  static const String newSaleTitle = 'New Sale';
  static const String selectProductsSection = 'Select Products';
  static const String selectProductsInstruction =
      'Check products to add. Select size variants from dropdown and customize prices if needed.';
  static const String searchCatalogHint =
      'Search products by name, sku, or category...';
  static const String noProductsFoundInCatalog =
      'No products found in catalog. You can add one below.';
  static const String customItemSection = 'Custom / Non-Catalog Item';
  static const String customItemSubtitle =
      'For one-off items or products not yet in your inventory';
  static const String addCustomItemButton = 'Add Custom Item';
  static const String itemNameLabel = 'Item name *';
  static const String rateOrPriceLabel = 'Rate / Price (Rs) *';
  static const String quantityLabel = 'Quantity *';
  static const String discountPercentageLabel = 'Discount (%)';
  static const String paymentAndSettlementSection = 'Payment & Settlement';
  static const String paidAmountUpfrontLabel = 'Paid amount upfront (optional)';
  static const String paidAmountHelper =
      'Will automatically be credited & recorded to ledger';
  static const String saveSaleButton = 'Save Sale';
  static const String saleSavedSuccess = 'Sale saved successfully';
  static const String subtotalLabel = 'Subtotal';
  static const String discountAmountLabel = 'Discount';
  static const String taxLabel = 'Tax';
  static const String totalAmountLabel = 'Total Amount';
  static const String paidUpfrontLabel = 'Paid Upfront';
  static const String balanceDueLabel = 'Balance Due';

  // ─── Payments ──────────────────────────────────────────────────
  static const String paymentsTitle = 'Payments';
  static const String recordPaymentButton = 'Record Payment';
  static const String noPaymentsYet = 'No payments recorded yet.';
  static const String deletePaymentTitle = 'Delete payment?';
  static const String deletePaymentConfirm =
      'This will remove the payment and its allocations.';
  static const String paymentRecordedSuccess = 'Payment recorded successfully';
  static const String paymentModeLabel = 'Payment Mode';
  static const String amountRequiredLabel = 'Amount (Rs) *';
  static const String savePaymentButton = 'Save Payment';
  static const String enterValidPaymentAmount = 'Enter a valid payment amount';

  // ─── Party History & PDF ───────────────────────────────────────
  static const String partyHistoryTitle = 'Party History';
  static const String exportPrintPdfTooltip = 'Export & Print PDF Statement';
  static const String sharePdfTooltip = 'Share PDF Statement';
  static const String netBalanceLabel = 'Net Balance';
  static const String totalSalesStat = 'Total Sales';
  static const String paymentsStat = 'Payments';
  static const String balanceDueStat = 'Balance Due';
  static const String ordersStat = 'Orders';
  static const String daysSinceOldestUnpaidSale =
      'days since oldest unpaid sale invoice';
  static const String filterAll = 'All';
  static const String filterOrders = 'Orders';
  static const String filterSales = 'Sales';
  static const String filterPayments = 'Payments';
  static const String noTransactionsRecorded =
      'No transactions or orders recorded yet';
  static const String orderItemsLabel = 'Order Items:';
  static const String saleItemsLabel = 'Sale Items:';
  static const String paidPrefix = 'Paid: Rs ';
  static const String duePrefix = 'Due: Rs ';
  static const String datePrefix = 'Date: ';
  static const String paymentModePrefix = 'Payment Mode: ';
  static const String actionSale = 'Sale';
  static const String actionOrder = 'Order';
  static const String actionPay = 'Pay';

  // ─── Payment Collection & Order Advance ───────────────────────
  static const String advancePaymentSection = 'Advance Payment (Optional)';
  static const String advancePaidLabel = 'Advance Paid';
  static const String advancePaidHelper =
      'Advance / token amount collected with this order';
  static const String collectPayment = 'Collect Payment';
  static const String receivePayment = 'Receive Payment';
  static const String collectAdvancePayment = 'Collect Advance';
  static const String paymentCollectedSuccess =
      'Payment collected successfully';
  static const String paymentStatusUnpaid = 'Unpaid';
  static const String paymentStatusPartial = 'Partial';
  static const String paymentStatusPaid = 'Paid';
  static const String paymentStatusAdvancePaid = 'Advance Paid';
  static const String quickFullPaid = 'Full Paid';
  static const String quickHalfPaid = 'Half Paid';
  static const String quickUnpaid = 'Unpaid (Credit)';
  static const String quickToken500 = 'Rs 500 Advance';
  static const String quickToken1000 = 'Rs 1,000 Advance';
  static const String amountToCollect = 'Amount to Collect *';
  static const String advancePrefix = 'Adv: Rs ';
  static const String collectPaymentDescription =
      'Record payment received and update customer ledger balance.';

  // ─── Settings & Hotel Profile ──────────────────────────────────
  static const String settingsTitle = 'Settings & Hotel Profile';
  static const String hotelBusinessProfileSection = 'Hotel / Business Profile';
  static const String businessLogoLabel = 'Business Logo';
  static const String businessLogoHelper =
      'Used on printed receipts & invoices';
  static const String uploadButton = 'Upload';
  static const String changeButton = 'Change';
  static const String hotelBusinessNameLabel = 'Hotel / Business Name *';
  static const String taglineLabel = 'Tagline / Slogan';
  static const String contactPhoneLabel = 'Contact Phone';
  static const String emailAddressLabel = 'Email Address';
  static const String locationAddressLabel = 'Location / Address';
  static const String ntnTaxNumberLabel = 'NTN / Tax Registration No.';
  static const String invoiceAndAccountingSection = 'Invoice & Accounting';
  static const String currencyLabel = 'Currency';
  static const String currencyHint = 'Rs, \$, AED';
  static const String taxRateLabel = 'Tax Rate (%)';
  static const String enableTaxTitle = 'Enable Tax Calculation on Sales';
  static const String enableTaxSubtitle =
      'Automatically compute tax on invoices & receipts';
  static const String invoiceFooterNoteLabel = 'Invoice Footer Note';
  static const String invoiceFooterNoteHint =
      'e.g. Thank you for your business! Visit again.';
  static const String saveSettingsButton = 'Save Settings';
  static const String settingsSavedSuccess = 'Settings saved successfully';
}
