// lib/core/constants/app_strings/app_strings.dart

import 'package:flutter/widgets.dart';
import 'package:katha_management/l10n/app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

/// Centralized repository of all user-facing strings across the Katha Management app.
/// Delegates dynamically to the active [AppLocalizations] instance.
class AppStrings {
  AppStrings._();

  static AppLocalizations? _localizations;

  /// Update the current active localizations instance.
  /// Called automatically on MaterialApp rebuild.
  static void updateLocale(AppLocalizations? localizations) {
    if (localizations != null) {
      _localizations = localizations;
    }
  }

  static AppLocalizations? get current => _localizations;

  static AppLocalizations of(BuildContext context) =>
      AppLocalizations.of(context)!;

  // ─── General & Common ──────────────────────────────────────────
  static String get appTitle => _localizations?.appTitle ?? 'Katha Management';
  static String get currency => _localizations?.currency ?? 'Rs';
  static String get currencyPrefix => _localizations?.currencyPrefix ?? 'Rs ';
  static String get percentSuffix => _localizations?.percentSuffix ?? '%';
  static String get save => _localizations?.save ?? 'Save';
  static String get cancel => _localizations?.cancel ?? 'Cancel';
  static String get delete => _localizations?.delete ?? 'Delete';
  static String get edit => _localizations?.edit ?? 'Edit';
  static String get update => _localizations?.update ?? 'Update';
  static String get retry => _localizations?.retry ?? 'Retry';
  static String get refresh => _localizations?.refresh ?? 'Refresh';
  static String get clear => _localizations?.clear ?? 'Clear';
  static String get add => _localizations?.add ?? 'Add';
  static String get yes => _localizations?.yes ?? 'Yes';
  static String get no => _localizations?.no ?? 'No';
  static String get all => _localizations?.all ?? 'All';
  static String get note => _localizations?.note ?? 'Note';
  static String get noteOptional =>
      _localizations?.noteOptional ?? 'Note (optional)';
  static String get optional => _localizations?.optional ?? 'Optional';
  static String get status => _localizations?.status ?? 'Status';
  static String get search => _localizations?.search ?? 'Search';
  static String get noPhoneOnFile =>
      _localizations?.noPhoneOnFile ?? 'No phone on file';
  static String get noPhone => _localizations?.noPhone ?? 'No phone';

  // ─── Navigation ────────────────────────────────────────────────
  static String get navHome => _localizations?.navHome ?? 'Home';
  static String get navDashboard =>
      _localizations?.navDashboard ?? 'Dashboard';
  static String get navOrders => _localizations?.navOrders ?? 'Orders';
  static String get navCustomers =>
      _localizations?.navCustomers ?? 'Customers';
  static String get navParties => _localizations?.navParties ?? 'Parties';
  static String get navProducts => _localizations?.navProducts ?? 'Products';
  static String get navSettings => _localizations?.navSettings ?? 'Settings';

  // ─── Dashboard ─────────────────────────────────────────────────
  static String get dashboardTitle =>
      _localizations?.dashboardTitle ?? 'Dashboard';
  static String get todaysSales =>
      _localizations?.todaysSales ?? "Today's Sales";
  static String get todaysCollection =>
      _localizations?.todaysCollection ?? "Today's Collection";
  static String get receivables =>
      _localizations?.receivables ?? 'Receivables';
  static String get topPendingParties =>
      _localizations?.topPendingParties ?? 'Top Pending Parties';
  static String get recentActivity =>
      _localizations?.recentActivity ?? 'Recent Activity';
  static String get noPendingBalances =>
      _localizations?.noPendingBalances ?? 'No pending balances';
  static String get noRecentActivity =>
      _localizations?.noRecentActivity ?? 'No recent activity';
  static String get daysOverdueSuffix =>
      _localizations?.daysOverdueSuffix ?? 'd overdue';
  static String get openingBalanceLabel =>
      _localizations?.openingBalanceLabel ?? 'Previous Due (Opening Balance)';
  static String get quickActionNewSale =>
      _localizations?.quickActionNewSale ?? 'New Sale';
  static String get quickActionNewOrder =>
      _localizations?.quickActionNewOrder ?? 'New Order';
  static String get quickActionAddPayment =>
      _localizations?.quickActionAddPayment ?? 'Add Payment';
  static String get quickActionAddParty =>
      _localizations?.quickActionAddParty ?? 'Add Party';
  static String get activityTypeSale =>
      _localizations?.activityTypeSale ?? 'Sale';
  static String get activityTypePayment =>
      _localizations?.activityTypePayment ?? 'Payment';
  static String get activityTypeOrder =>
      _localizations?.activityTypeOrder ?? 'Order Placed';

  // ─── Customers / Parties ───────────────────────────────────────
  static String get customersTitle =>
      _localizations?.customersTitle ?? 'Customers';
  static String get addPartyTitle =>
      _localizations?.addPartyTitle ?? 'Add Party';
  static String get searchCustomersHint =>
      _localizations?.searchCustomersHint ?? 'Search by name or phone';
  static String get noCustomersYet =>
      _localizations?.noCustomersYet ?? 'No customers yet';
  static String get settled => _localizations?.settled ?? 'Settled';
  static String get basicInfoSection =>
      _localizations?.basicInfoSection ?? 'Basic Info';
  static String get partyNameLabel =>
      _localizations?.partyNameLabel ?? 'Party name *';
  static String get partyPhoneLabel =>
      _localizations?.partyPhoneLabel ?? 'Phone (optional)';
  static String get partyAddressLabel =>
      _localizations?.partyAddressLabel ?? 'Address (optional)';
  static String get categorySection =>
      _localizations?.categorySection ?? 'Category';
  static String get openingBalanceSection =>
      _localizations?.openingBalanceSection ?? 'Previous Due (Opening Balance)';
  static String get openingBalanceAmountLabel =>
      _localizations?.openingBalanceAmountLabel ??
      'Unpaid Due Amount (optional)';
  static String get openingBalanceHelper =>
      _localizations?.openingBalanceHelper ??
      'Enter previous unpaid balance / due carried over from before this app';
  static String get openingBalanceInfoNote =>
      _localizations?.openingBalanceInfoNote ??
      'Previous unpaid balance carried over from before this app';
  static String get savePartyButton =>
      _localizations?.savePartyButton ?? 'Save Party';
  static String get updatePartyButton =>
      _localizations?.updatePartyButton ?? 'Update Party';
  static String get editPartyTitle =>
      _localizations?.editPartyTitle ?? 'Edit Party';
  static String get partyAddedSuccess =>
      _localizations?.partyAddedSuccess ?? 'Party added';
  static String get partyUpdatedSuccess =>
      _localizations?.partyUpdatedSuccess ?? 'Party updated successfully';
  static String get deletePartyTitle =>
      _localizations?.deletePartyTitle ?? 'Delete Party?';
  static String get deletePartyMessage =>
      _localizations?.deletePartyMessage ??
      'Are you sure you want to delete this party? All related transaction history may be affected.';
  static String get deletePartyButton =>
      _localizations?.deletePartyButton ?? 'Delete Party';
  static String get partyDeletedSuccess =>
      _localizations?.partyDeletedSuccess ?? 'Party deleted successfully';
  static String get partyDetailsSection =>
      _localizations?.partyDetailsSection ?? 'Party Details';
  static String get selectExistingCustomer =>
      _localizations?.selectExistingCustomer ?? 'Select Existing Customer';
  static String get selectCustomer =>
      _localizations?.selectCustomer ?? 'Select Customer';
  static String get partyNameRequired =>
      _localizations?.partyNameRequired ?? 'Party name is required';

  // ─── Orders ────────────────────────────────────────────────────
  static String get ordersTitle => _localizations?.ordersTitle ?? 'Orders';
  static String get tabPending => _localizations?.tabPending ?? 'Pending';
  static String get tabDone => _localizations?.tabDone ?? 'Done';
  static String get searchOrdersHint =>
      _localizations?.searchOrdersHint ??
      'Search orders by party, item, or note...';
  static String get noPendingOrders =>
      _localizations?.noPendingOrders ?? 'No pending orders';
  static String get noDoneOrders =>
      _localizations?.noDoneOrders ?? 'No completed/cancelled orders';
  static String get newOrderButton =>
      _localizations?.newOrderButton ?? 'New Order';
  static String get editOrderTitle =>
      _localizations?.editOrderTitle ?? 'Edit Order';
  static String get updateOrderButton =>
      _localizations?.updateOrderButton ?? 'Update Order';
  static String get orderConvertedToSale =>
      _localizations?.orderConvertedToSale ?? 'Order converted to Sale invoice';
  static String get orderedPrefix =>
      _localizations?.orderedPrefix ?? 'Ordered: ';
  static String get updatedPrefix =>
      _localizations?.updatedPrefix ?? 'Updated: ';
  static String get deliveryByPrefix =>
      _localizations?.deliveryByPrefix ?? 'Delivery by: ';
  static String get viewItems => _localizations?.viewItems ?? 'View items';
  static String get hideItems => _localizations?.hideItems ?? 'Hide items';
  static String get cancelOrderTooltip =>
      _localizations?.cancelOrderTooltip ?? 'Cancel order';
  static String get cancelOrderTitle =>
      _localizations?.cancelOrderTitle ?? 'Cancel Order?';
  static String get cancelOrderMessage =>
      _localizations?.cancelOrderMessage ??
      'Are you sure you want to cancel this order?';
  static String get yesCancel => _localizations?.yesCancel ?? 'Yes, Cancel';
  static String get deleteOrderTitle =>
      _localizations?.deleteOrderTitle ?? 'Delete Order?';
  static String get deleteOrderMessage =>
      _localizations?.deleteOrderMessage ??
      'Are you sure you want to permanently delete this order?';
  static String get deleteOrderButton =>
      _localizations?.deleteOrderButton ?? 'Delete';
  static String get orderDeletedSuccess =>
      _localizations?.orderDeletedSuccess ?? 'Order deleted successfully';
  static String get cannotEditDeliveredOrPaidOrder =>
      _localizations?.cannotEditDeliveredOrPaidOrder ??
      'Orders that are Delivered or Paid cannot be modified.';
  static String get convertedToSaleBadge =>
      _localizations?.convertedToSaleBadge ?? 'Converted to Sale';
  static String get convertToSaleButton =>
      _localizations?.convertToSaleButton ?? 'Convert to Sale';
  static String get changeStatusTooltip =>
      _localizations?.changeStatusTooltip ?? 'Change Status';
  static String get expectedDeliveryDateLabel =>
      _localizations?.expectedDeliveryDateLabel ?? 'Expected Delivery Date';
  static String get expectedDeliveryPrefix =>
      _localizations?.expectedDeliveryPrefix ?? 'Expected Delivery: ';
  static String get expectedDeliveryDateOptional =>
      _localizations?.expectedDeliveryDateOptional ??
      'Expected delivery date (optional)';
  static String get deliveryDateOptional =>
      _localizations?.deliveryDateOptional ?? 'Delivery date (optional)';
  static String get changePartyTooltip =>
      _localizations?.changePartyTooltip ?? 'Change Party';
  static String get newOrderPlacedStatusInfo =>
      _localizations?.newOrderPlacedStatusInfo ??
      'New orders will be created with status: Placed';
  static String get selectExpectedDeliveryDateHint =>
      _localizations?.selectExpectedDeliveryDateHint ??
      'Select expected delivery date';
  static String get estimatedTotalLabel =>
      _localizations?.estimatedTotalLabel ?? 'Estimated Total';
  static String get orderPlacedSuccess =>
      _localizations?.orderPlacedSuccess ?? 'Order placed successfully';
  static String get placeOrderButton =>
      _localizations?.placeOrderButton ?? 'Place Order';
  static String get orderSavedSuccess =>
      _localizations?.orderSavedSuccess ?? 'Order saved successfully';
  static String get orderUpdatedSuccess =>
      _localizations?.orderUpdatedSuccess ?? 'Order updated successfully';
  static String get markDelivered =>
      _localizations?.markDelivered ?? 'Mark Delivered';
  static String get markPaid => _localizations?.markPaid ?? 'Mark Paid';
  static String get orderPaidSuccess =>
      _localizations?.orderPaidSuccess ??
      'Order marked as Paid and balance settled';
  static String get itemSingular => _localizations?.itemSingular ?? 'item';
  static String get itemsPlural => _localizations?.itemsPlural ?? 'items';

  // ─── Products & Catalog ─────────────────────────────────────────
  static String get productsTitle =>
      _localizations?.productsTitle ?? 'Products';
  static String get addProductTitle =>
      _localizations?.addProductTitle ?? 'Add Product';
  static String get editProductTitle =>
      _localizations?.editProductTitle ?? 'Edit Product';
  static String get searchProductsHint =>
      _localizations?.searchProductsHint ?? 'Search by name or SKU';
  static String get noProductsYet =>
      _localizations?.noProductsYet ?? 'No products yet';
  static String get lowStock => _localizations?.lowStock ?? 'Low stock';
  static String get productNameLabel =>
      _localizations?.productNameLabel ?? 'Product name *';
  static String get descriptionOptional =>
      _localizations?.descriptionOptional ?? 'Description (optional)';
  static String get skuLabel => _localizations?.skuLabel ?? 'SKU / Code';
  static String get categoryLabel =>
      _localizations?.categoryLabel ?? 'Category';
  static String get baseUnitLabel =>
      _localizations?.baseUnitLabel ?? 'Base unit (optional)';
  static String get baseUnitHelper =>
      _localizations?.baseUnitHelper ??
      'e.g. piece, kg, box — what sizes below are variants of';
  static String get sellingPriceSection =>
      _localizations?.sellingPriceSection ?? 'Selling Price';
  static String get sellingPriceDescription =>
      _localizations?.sellingPriceDescription ??
      'What the customer sees and pays.';
  static String get retailPriceLabel =>
      _localizations?.retailPriceLabel ?? 'Retail price *';
  static String get discountLabel =>
      _localizations?.discountLabel ?? 'Discount';
  static String get customerPays =>
      _localizations?.customerPays ?? 'Customer Pays';
  static String get costAndProfitMarginSection =>
      _localizations?.costAndProfitMarginSection ?? 'Cost & Profit Margin';
  static String get costAndProfitMarginDescription =>
      _localizations?.costAndProfitMarginDescription ??
      'What this product costs you to buy or produce. Used only to show your profit below — customers never see this.';
  static String get costPriceLabel =>
      _localizations?.costPriceLabel ?? 'Cost price';
  static String get costPriceOptional =>
      _localizations?.costPriceOptional ?? 'Cost price (optional)';
  static String get costPriceHelper =>
      _localizations?.costPriceHelper ??
      'Used to calculate profit margin for this size';
  static String get enterCostPriceHint =>
      _localizations?.enterCostPriceHint ??
      'Enter a cost price to see your profit margin here.';
  static String get stockQuantityLabel =>
      _localizations?.stockQuantityLabel ?? 'Stock qty (optional)';
  static String get sellingBelowCost =>
      _localizations?.sellingBelowCost ?? 'Selling Below Cost';
  static String get profitMargin =>
      _localizations?.profitMargin ?? 'Profit Margin';
  static String get perUnit => _localizations?.perUnit ?? 'per unit';
  static String get statusSection =>
      _localizations?.statusSection ?? 'Status';
  static String get sizeVariantsSection =>
      _localizations?.sizeVariantsSection ?? 'Size / Price Variants';
  static String get noSizeVariantsNote =>
      _localizations?.noSizeVariantsNote ??
      'No size variants — product will use the retail price above';
  static String get sizeLabel => _localizations?.sizeLabel ?? 'Size label';
  static String get sizeLabelHint =>
      _localizations?.sizeLabelHint ?? 'e.g. 1 Liter, 5Kg, Dozen';
  static String get priceLabel => _localizations?.priceLabel ?? 'Price';
  static String get sellingPricePrefix =>
      _localizations?.sellingPricePrefix ?? 'Selling Price: Rs ';
  static String get marginPrefix =>
      _localizations?.marginPrefix ?? 'Margin: Rs ';
  static String get addSizeButton =>
      _localizations?.addSizeButton ?? 'Add Size';
  static String get updateProductButton =>
      _localizations?.updateProductButton ?? 'Update Product';
  static String get saveProductButton =>
      _localizations?.saveProductButton ?? 'Save Product';
  static String get productAddedSuccess =>
      _localizations?.productAddedSuccess ?? 'Product added';
  static String get productUpdatedSuccess =>
      _localizations?.productUpdatedSuccess ?? 'Product updated';
  static String get selectPackageSizeLabel =>
      _localizations?.selectPackageSizeLabel ?? 'Select Package Size';

  // ─── New Sale & Order Form ─────────────────────────────────────
  static String get newSaleTitle =>
      _localizations?.newSaleTitle ?? 'New Sale';
  static String get selectProductsSection =>
      _localizations?.selectProductsSection ?? 'Select Products';
  static String get selectProductsInstruction =>
      _localizations?.selectProductsInstruction ??
      'Check products to add. Select size variants from dropdown and customize prices if needed.';
  static String get searchCatalogHint =>
      _localizations?.searchCatalogHint ??
      'Search products by name, sku, or category...';
  static String get noProductsFoundInCatalog =>
      _localizations?.noProductsFoundInCatalog ??
      'No products found in catalog. You can add one below.';
  static String get customItemSection =>
      _localizations?.customItemSection ?? 'Custom / Non-Catalog Item';
  static String get customItemSubtitle =>
      _localizations?.customItemSubtitle ??
      'For one-off items or products not yet in your inventory';
  static String get addCustomItemButton =>
      _localizations?.addCustomItemButton ?? 'Add Custom Item';
  static String get itemNameLabel =>
      _localizations?.itemNameLabel ?? 'Item name *';
  static String get rateOrPriceLabel =>
      _localizations?.rateOrPriceLabel ?? 'Rate / Price (Rs) *';
  static String get quantityLabel =>
      _localizations?.quantityLabel ?? 'Quantity *';
  static String get discountPercentageLabel =>
      _localizations?.discountPercentageLabel ?? 'Discount (%)';
  static String get paymentAndSettlementSection =>
      _localizations?.paymentAndSettlementSection ?? 'Payment & Settlement';
  static String get paidAmountUpfrontLabel =>
      _localizations?.paidAmountUpfrontLabel ??
      'Paid amount upfront (optional)';
  static String get paidAmountHelper =>
      _localizations?.paidAmountHelper ??
      'Will automatically be credited & recorded to ledger';
  static String get saveSaleButton =>
      _localizations?.saveSaleButton ?? 'Save Sale';
  static String get saleSavedSuccess =>
      _localizations?.saleSavedSuccess ?? 'Sale saved successfully';
  static String get subtotalLabel =>
      _localizations?.subtotalLabel ?? 'Subtotal';
  static String get discountAmountLabel =>
      _localizations?.discountAmountLabel ?? 'Discount';
  static String get taxLabel => _localizations?.taxLabel ?? 'Tax';
  static String get totalAmountLabel =>
      _localizations?.totalAmountLabel ?? 'Total Amount';
  static String get paidUpfrontLabel =>
      _localizations?.paidUpfrontLabel ?? 'Paid Upfront';
  static String get balanceDueLabel =>
      _localizations?.balanceDueLabel ?? 'Balance Due';

  // ─── Payments ──────────────────────────────────────────────────
  static String get paymentsTitle =>
      _localizations?.paymentsTitle ?? 'Payments';
  static String get recordPaymentButton =>
      _localizations?.recordPaymentButton ?? 'Record Payment';
  static String get noPaymentsYet =>
      _localizations?.noPaymentsYet ?? 'No payments recorded yet.';
  static String get deletePaymentTitle =>
      _localizations?.deletePaymentTitle ?? 'Delete payment?';
  static String get deletePaymentConfirm =>
      _localizations?.deletePaymentConfirm ??
      'This will remove the payment and its allocations.';
  static String get paymentRecordedSuccess =>
      _localizations?.paymentRecordedSuccess ??
      'Payment recorded successfully';
  static String get paymentModeLabel =>
      _localizations?.paymentModeLabel ?? 'Payment Mode';
  static String get amountRequiredLabel =>
      _localizations?.amountRequiredLabel ?? 'Amount (Rs) *';
  static String get savePaymentButton =>
      _localizations?.savePaymentButton ?? 'Save Payment';
  static String get enterValidPaymentAmount =>
      _localizations?.enterValidPaymentAmount ??
      'Enter a valid payment amount';

  // ─── Party History & PDF ───────────────────────────────────────
  static String get partyHistoryTitle =>
      _localizations?.partyHistoryTitle ?? 'Party History';
  static String get exportPrintPdfTooltip =>
      _localizations?.exportPrintPdfTooltip ??
      'Export & Print PDF Statement';
  static String get sharePdfTooltip =>
      _localizations?.sharePdfTooltip ?? 'Share PDF Statement';
  static String get netBalanceLabel =>
      _localizations?.netBalanceLabel ?? 'Net Balance';
  static String get totalSalesStat =>
      _localizations?.totalSalesStat ?? 'Total Sales';
  static String get paymentsStat =>
      _localizations?.paymentsStat ?? 'Payments';
  static String get balanceDueStat =>
      _localizations?.balanceDueStat ?? 'Balance Due';
  static String get ordersStat => _localizations?.ordersStat ?? 'Orders';
  static String get daysSinceOldestUnpaidSale =>
      _localizations?.daysSinceOldestUnpaidSale ??
      'days since oldest unpaid sale invoice';
  static String get filterAll => _localizations?.filterAll ?? 'All';
  static String get filterOrders =>
      _localizations?.filterOrders ?? 'Orders';
  static String get filterSales => _localizations?.filterSales ?? 'Sales';
  static String get filterPayments =>
      _localizations?.filterPayments ?? 'Payments';
  static String get noTransactionsRecorded =>
      _localizations?.noTransactionsRecorded ??
      'No transactions or orders recorded yet';
  static String get orderItemsLabel =>
      _localizations?.orderItemsLabel ?? 'Order Items:';
  static String get saleItemsLabel =>
      _localizations?.saleItemsLabel ?? 'Sale Items:';
  static String get paidPrefix => _localizations?.paidPrefix ?? 'Paid: Rs ';
  static String get duePrefix => _localizations?.duePrefix ?? 'Due: Rs ';
  static String get datePrefix => _localizations?.datePrefix ?? 'Date: ';
  static String get paymentModePrefix =>
      _localizations?.paymentModePrefix ?? 'Payment Mode: ';
  static String get actionSale => _localizations?.actionSale ?? 'Sale';
  static String get actionOrder => _localizations?.actionOrder ?? 'Order';
  static String get actionPay => _localizations?.actionPay ?? 'Pay';

  // ─── Payment Collection & Order Advance ───────────────────────
  static String get advancePaymentSection =>
      _localizations?.advancePaymentSection ?? 'Advance Payment (Optional)';
  static String get advancePaidLabel =>
      _localizations?.advancePaidLabel ?? 'Advance Paid';
  static String get advancePaidHelper =>
      _localizations?.advancePaidHelper ??
      'Advance / token amount collected with this order';
  static String get collectPayment =>
      _localizations?.collectPayment ?? 'Collect Payment';
  static String get receivePayment =>
      _localizations?.receivePayment ?? 'Receive Payment';
  static String get collectAdvancePayment =>
      _localizations?.collectAdvancePayment ?? 'Collect Advance';
  static String get paymentCollectedSuccess =>
      _localizations?.paymentCollectedSuccess ??
      'Payment collected successfully';
  static String get paymentStatusUnpaid =>
      _localizations?.paymentStatusUnpaid ?? 'Unpaid';
  static String get paymentStatusPartial =>
      _localizations?.paymentStatusPartial ?? 'Partial';
  static String get paymentStatusPaid =>
      _localizations?.paymentStatusPaid ?? 'Paid';
  static String get paymentStatusAdvancePaid =>
      _localizations?.paymentStatusAdvancePaid ?? 'Advance Paid';
  static String get quickFullPaid =>
      _localizations?.quickFullPaid ?? 'Full Paid';
  static String get quickHalfPaid =>
      _localizations?.quickHalfPaid ?? 'Half Paid';
  static String get quickUnpaid =>
      _localizations?.quickUnpaid ?? 'Unpaid (Credit)';
  static String get quickToken500 =>
      _localizations?.quickToken500 ?? 'Rs 500 Advance';
  static String get quickToken1000 =>
      _localizations?.quickToken1000 ?? 'Rs 1,000 Advance';
  static String get amountToCollect =>
      _localizations?.amountToCollect ?? 'Amount to Collect *';
  static String get advancePrefix =>
      _localizations?.advancePrefix ?? 'Adv: Rs ';
  static String get collectPaymentDescription =>
      _localizations?.collectPaymentDescription ??
      'Record payment received and update customer ledger balance.';

  // ─── Settings & Hotel Profile ──────────────────────────────────
  static String get settingsTitle =>
      _localizations?.settingsTitle ?? 'Settings & Hotel Profile';
  static String get hotelBusinessProfileSection =>
      _localizations?.hotelBusinessProfileSection ?? 'Hotel / Business Profile';
  static String get businessLogoLabel =>
      _localizations?.businessLogoLabel ?? 'Business Logo';
  static String get businessLogoHelper =>
      _localizations?.businessLogoHelper ??
      'Used on printed receipts & invoices';
  static String get uploadButton =>
      _localizations?.uploadButton ?? 'Upload';
  static String get changeButton =>
      _localizations?.changeButton ?? 'Change';
  static String get hotelBusinessNameLabel =>
      _localizations?.hotelBusinessNameLabel ?? 'Hotel / Business Name *';
  static String get taglineLabel =>
      _localizations?.taglineLabel ?? 'Tagline / Slogan';
  static String get contactPhoneLabel =>
      _localizations?.contactPhoneLabel ?? 'Contact Phone';
  static String get emailAddressLabel =>
      _localizations?.emailAddressLabel ?? 'Email Address';
  static String get locationAddressLabel =>
      _localizations?.locationAddressLabel ?? 'Location / Address';
  static String get ntnTaxNumberLabel =>
      _localizations?.ntnTaxNumberLabel ?? 'NTN / Tax Registration No.';
  static String get invoiceAndAccountingSection =>
      _localizations?.invoiceAndAccountingSection ?? 'Invoice & Accounting';
  static String get currencyLabel =>
      _localizations?.currencyLabel ?? 'Currency';
  static String get currencyHint =>
      _localizations?.currencyHint ?? 'Rs, \$, AED';
  static String get taxRateLabel =>
      _localizations?.taxRateLabel ?? 'Tax Rate (%)';
  static String get enableTaxTitle =>
      _localizations?.enableTaxTitle ?? 'Enable Tax Calculation on Sales';
  static String get enableTaxSubtitle =>
      _localizations?.enableTaxSubtitle ??
      'Automatically compute tax on invoices & receipts';
  static String get invoiceFooterNoteLabel =>
      _localizations?.invoiceFooterNoteLabel ?? 'Invoice Footer Note';
  static String get invoiceFooterNoteHint =>
      _localizations?.invoiceFooterNoteHint ??
      'e.g. Thank you for your business! Visit again.';
  static String get saveSettingsButton =>
      _localizations?.saveSettingsButton ?? 'Save Settings';
  static String get settingsSavedSuccess =>
      _localizations?.settingsSavedSuccess ?? 'Settings saved successfully';

  // ─── Language Selector ─────────────────────────────────────────
  static String get languageSectionTitle =>
      _localizations?.languageSectionTitle ?? 'Language / زبان';
  static String get selectLanguageTitle =>
      _localizations?.selectLanguageTitle ?? 'Select Language / زبان منتخب کریں';
  static String get englishLanguage =>
      _localizations?.englishLanguage ?? 'English';
  static String get urduLanguage =>
      _localizations?.urduLanguage ?? 'اردو (Urdu)';
  static String get languageChangedSuccess =>
      _localizations?.languageChangedSuccess ??
      'Language changed successfully';

  // ─── Theme Switcher ───────────────────────────────────────────
  static String get themeSectionTitle =>
      _localizations?.themeSectionTitle ?? 'Theme / تھیم';
  static String get themeDarkMode =>
      _localizations?.themeDarkMode ?? 'Dark Mode';
  static String get themeLightMode =>
      _localizations?.themeLightMode ?? 'Light Mode';
  static String get themeSubtitle =>
      _localizations?.themeSubtitle ??
      'Switch between light and dark frosted glass theme';
}
