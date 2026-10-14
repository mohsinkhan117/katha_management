// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Katha Management';

  @override
  String get currency => 'Rs';

  @override
  String get currencyPrefix => 'Rs ';

  @override
  String get percentSuffix => '%';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get update => 'Update';

  @override
  String get retry => 'Retry';

  @override
  String get refresh => 'Refresh';

  @override
  String get clear => 'Clear';

  @override
  String get add => 'Add';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get all => 'All';

  @override
  String get note => 'Note';

  @override
  String get noteOptional => 'Note (optional)';

  @override
  String get optional => 'Optional';

  @override
  String get status => 'Status';

  @override
  String get search => 'Search';

  @override
  String get noPhoneOnFile => 'No phone on file';

  @override
  String get noPhone => 'No phone';

  @override
  String get navHome => 'Home';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navOrders => 'Orders';

  @override
  String get navCustomers => 'Customers';

  @override
  String get navParties => 'Parties';

  @override
  String get navProducts => 'Products';

  @override
  String get navSettings => 'Settings';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get todaysSales => 'Today\'s Sales';

  @override
  String get todaysCollection => 'Today\'s Collection';

  @override
  String get receivables => 'Receivables';

  @override
  String get topPendingParties => 'Top Pending Parties';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get noPendingBalances => 'No pending balances';

  @override
  String get noRecentActivity => 'No recent activity';

  @override
  String get daysOverdueSuffix => 'd overdue';

  @override
  String get openingBalanceLabel => 'Previous Due (Opening Balance)';

  @override
  String get quickActionNewSale => 'New Sale';

  @override
  String get quickActionNewOrder => 'New Order';

  @override
  String get quickActionAddPayment => 'Add Payment';

  @override
  String get quickActionAddParty => 'Add Party';

  @override
  String get activityTypeSale => 'Sale';

  @override
  String get activityTypePayment => 'Payment';

  @override
  String get activityTypeOrder => 'Order Placed';

  @override
  String get customersTitle => 'Customers';

  @override
  String get addPartyTitle => 'Add Party';

  @override
  String get searchCustomersHint => 'Search by name or phone';

  @override
  String get noCustomersYet => 'No customers yet';

  @override
  String get settled => 'Settled';

  @override
  String get basicInfoSection => 'Basic Info';

  @override
  String get partyNameLabel => 'Party name *';

  @override
  String get partyPhoneLabel => 'Phone (optional)';

  @override
  String get partyAddressLabel => 'Address (optional)';

  @override
  String get categorySection => 'Category';

  @override
  String get openingBalanceSection => 'Previous Due (Opening Balance)';

  @override
  String get openingBalanceAmountLabel => 'Unpaid Due Amount (optional)';

  @override
  String get openingBalanceHelper =>
      'Enter previous unpaid balance / due carried over from before this app';

  @override
  String get openingBalanceInfoNote =>
      'Previous unpaid balance carried over from before this app';

  @override
  String get savePartyButton => 'Save Party';

  @override
  String get updatePartyButton => 'Update Party';

  @override
  String get editPartyTitle => 'Edit Party';

  @override
  String get partyAddedSuccess => 'Party added';

  @override
  String get partyUpdatedSuccess => 'Party updated successfully';

  @override
  String get deletePartyTitle => 'Delete Party?';

  @override
  String get deletePartyMessage =>
      'Are you sure you want to delete this party? All related transaction history may be affected.';

  @override
  String get deletePartyButton => 'Delete Party';

  @override
  String get partyDeletedSuccess => 'Party deleted successfully';

  @override
  String get partyDetailsSection => 'Party Details';

  @override
  String get selectExistingCustomer => 'Select Existing Customer';

  @override
  String get selectCustomer => 'Select Customer';

  @override
  String get partyNameRequired => 'Party name is required';

  @override
  String get ordersTitle => 'Orders';

  @override
  String get tabPending => 'Pending';

  @override
  String get tabDone => 'Done';

  @override
  String get searchOrdersHint => 'Search orders by party, item, or note...';

  @override
  String get noPendingOrders => 'No pending orders';

  @override
  String get noDoneOrders => 'No completed/cancelled orders';

  @override
  String get newOrderButton => 'New Order';

  @override
  String get editOrderTitle => 'Edit Order';

  @override
  String get updateOrderButton => 'Update Order';

  @override
  String get orderConvertedToSale => 'Order converted to Sale invoice';

  @override
  String get orderedPrefix => 'Ordered: ';

  @override
  String get updatedPrefix => 'Updated: ';

  @override
  String get deliveryByPrefix => 'Delivery by: ';

  @override
  String get viewItems => 'View items';

  @override
  String get hideItems => 'Hide items';

  @override
  String get cancelOrderTooltip => 'Cancel order';

  @override
  String get cancelOrderTitle => 'Cancel Order?';

  @override
  String get cancelOrderMessage =>
      'Are you sure you want to cancel this order?';

  @override
  String get yesCancel => 'Yes, Cancel';

  @override
  String get deleteOrderTitle => 'Delete Order?';

  @override
  String get deleteOrderMessage =>
      'Are you sure you want to permanently delete this order?';

  @override
  String get deleteOrderButton => 'Delete';

  @override
  String get orderDeletedSuccess => 'Order deleted successfully';

  @override
  String get cannotEditDeliveredOrPaidOrder =>
      'Orders that are Delivered or Paid cannot be modified.';

  @override
  String get convertedToSaleBadge => 'Converted to Sale';

  @override
  String get convertToSaleButton => 'Convert to Sale';

  @override
  String get changeStatusTooltip => 'Change Status';

  @override
  String get expectedDeliveryDateLabel => 'Expected Delivery Date';

  @override
  String get expectedDeliveryPrefix => 'Expected Delivery: ';

  @override
  String get expectedDeliveryDateOptional =>
      'Expected delivery date (optional)';

  @override
  String get deliveryDateOptional => 'Delivery date (optional)';

  @override
  String get changePartyTooltip => 'Change Party';

  @override
  String get newOrderPlacedStatusInfo =>
      'New orders will be created with status: Placed';

  @override
  String get selectExpectedDeliveryDateHint => 'Select expected delivery date';

  @override
  String get estimatedTotalLabel => 'Estimated Total';

  @override
  String get orderPlacedSuccess => 'Order placed successfully';

  @override
  String get placeOrderButton => 'Place Order';

  @override
  String get orderSavedSuccess => 'Order saved successfully';

  @override
  String get orderUpdatedSuccess => 'Order updated successfully';

  @override
  String get markDelivered => 'Mark Delivered';

  @override
  String get markPaid => 'Mark Paid';

  @override
  String get orderPaidSuccess => 'Order marked as Paid and balance settled';

  @override
  String get itemSingular => 'item';

  @override
  String get itemsPlural => 'items';

  @override
  String get productsTitle => 'Products';

  @override
  String get addProductTitle => 'Add Product';

  @override
  String get editProductTitle => 'Edit Product';

  @override
  String get searchProductsHint => 'Search by name or SKU';

  @override
  String get noProductsYet => 'No products yet';

  @override
  String get lowStock => 'Low stock';

  @override
  String get productNameLabel => 'Product name *';

  @override
  String get descriptionOptional => 'Description (optional)';

  @override
  String get skuLabel => 'SKU / Code';

  @override
  String get categoryLabel => 'Category';

  @override
  String get baseUnitLabel => 'Base unit (optional)';

  @override
  String get baseUnitHelper =>
      'e.g. piece, kg, box — what sizes below are variants of';

  @override
  String get sellingPriceSection => 'Selling Price';

  @override
  String get sellingPriceDescription => 'What the customer sees and pays.';

  @override
  String get retailPriceLabel => 'Retail price *';

  @override
  String get discountLabel => 'Discount';

  @override
  String get customerPays => 'Customer Pays';

  @override
  String get costAndProfitMarginSection => 'Cost & Profit Margin';

  @override
  String get costAndProfitMarginDescription =>
      'What this product costs you to buy or produce. Used only to show your profit below — customers never see this.';

  @override
  String get costPriceLabel => 'Cost price';

  @override
  String get costPriceOptional => 'Cost price (optional)';

  @override
  String get costPriceHelper => 'Used to calculate profit margin for this size';

  @override
  String get enterCostPriceHint =>
      'Enter a cost price to see your profit margin here.';

  @override
  String get stockQuantityLabel => 'Stock qty (optional)';

  @override
  String get sellingBelowCost => 'Selling Below Cost';

  @override
  String get profitMargin => 'Profit Margin';

  @override
  String get perUnit => 'per unit';

  @override
  String get statusSection => 'Status';

  @override
  String get sizeVariantsSection => 'Size / Price Variants';

  @override
  String get noSizeVariantsNote =>
      'No size variants — product will use the retail price above';

  @override
  String get sizeLabel => 'Size label';

  @override
  String get sizeLabelHint => 'e.g. 1 Liter, 5Kg, Dozen';

  @override
  String get priceLabel => 'Price';

  @override
  String get sellingPricePrefix => 'Selling Price: Rs ';

  @override
  String get marginPrefix => 'Margin: Rs ';

  @override
  String get addSizeButton => 'Add Size';

  @override
  String get updateProductButton => 'Update Product';

  @override
  String get saveProductButton => 'Save Product';

  @override
  String get productAddedSuccess => 'Product added';

  @override
  String get productUpdatedSuccess => 'Product updated';

  @override
  String get selectPackageSizeLabel => 'Select Package Size';

  @override
  String get newSaleTitle => 'New Sale';

  @override
  String get selectProductsSection => 'Select Products';

  @override
  String get selectProductsInstruction =>
      'Check products to add. Select size variants from dropdown and customize prices if needed.';

  @override
  String get searchCatalogHint =>
      'Search products by name, sku, or category...';

  @override
  String get noProductsFoundInCatalog =>
      'No products found in catalog. You can add one below.';

  @override
  String get customItemSection => 'Custom / Non-Catalog Item';

  @override
  String get customItemSubtitle =>
      'For one-off items or products not yet in your inventory';

  @override
  String get addCustomItemButton => 'Add Custom Item';

  @override
  String get itemNameLabel => 'Item name *';

  @override
  String get rateOrPriceLabel => 'Rate / Price (Rs) *';

  @override
  String get quantityLabel => 'Quantity *';

  @override
  String get discountPercentageLabel => 'Discount (%)';

  @override
  String get paymentAndSettlementSection => 'Payment & Settlement';

  @override
  String get paidAmountUpfrontLabel => 'Paid amount upfront (optional)';

  @override
  String get paidAmountHelper =>
      'Will automatically be credited & recorded to ledger';

  @override
  String get saveSaleButton => 'Save Sale';

  @override
  String get saleSavedSuccess => 'Sale saved successfully';

  @override
  String get subtotalLabel => 'Subtotal';

  @override
  String get discountAmountLabel => 'Discount';

  @override
  String get taxLabel => 'Tax';

  @override
  String get totalAmountLabel => 'Total Amount';

  @override
  String get paidUpfrontLabel => 'Paid Upfront';

  @override
  String get balanceDueLabel => 'Balance Due';

  @override
  String get paymentsTitle => 'Payments';

  @override
  String get recordPaymentButton => 'Record Payment';

  @override
  String get noPaymentsYet => 'No payments recorded yet.';

  @override
  String get deletePaymentTitle => 'Delete payment?';

  @override
  String get deletePaymentConfirm =>
      'This will remove the payment and its allocations.';

  @override
  String get paymentRecordedSuccess => 'Payment recorded successfully';

  @override
  String get paymentModeLabel => 'Payment Mode';

  @override
  String get amountRequiredLabel => 'Amount (Rs) *';

  @override
  String get savePaymentButton => 'Save Payment';

  @override
  String get enterValidPaymentAmount => 'Enter a valid payment amount';

  @override
  String get partyHistoryTitle => 'Party History';

  @override
  String get exportPrintPdfTooltip => 'Export & Print PDF Statement';

  @override
  String get sharePdfTooltip => 'Share PDF Statement';

  @override
  String get netBalanceLabel => 'Net Balance';

  @override
  String get totalSalesStat => 'Total Sales';

  @override
  String get paymentsStat => 'Payments';

  @override
  String get balanceDueStat => 'Balance Due';

  @override
  String get ordersStat => 'Orders';

  @override
  String get daysSinceOldestUnpaidSale =>
      'days since oldest unpaid sale invoice';

  @override
  String get filterAll => 'All';

  @override
  String get filterOrders => 'Orders';

  @override
  String get filterSales => 'Sales';

  @override
  String get filterPayments => 'Payments';

  @override
  String get noTransactionsRecorded => 'No transactions or orders recorded yet';

  @override
  String get orderItemsLabel => 'Order Items:';

  @override
  String get saleItemsLabel => 'Sale Items:';

  @override
  String get paidPrefix => 'Paid: Rs ';

  @override
  String get duePrefix => 'Due: Rs ';

  @override
  String get datePrefix => 'Date: ';

  @override
  String get paymentModePrefix => 'Payment Mode: ';

  @override
  String get actionSale => 'Sale';

  @override
  String get actionOrder => 'Order';

  @override
  String get actionPay => 'Pay';

  @override
  String get advancePaymentSection => 'Advance Payment (Optional)';

  @override
  String get advancePaidLabel => 'Advance Paid';

  @override
  String get advancePaidHelper =>
      'Advance / token amount collected with this order';

  @override
  String get collectPayment => 'Collect Payment';

  @override
  String get receivePayment => 'Receive Payment';

  @override
  String get collectAdvancePayment => 'Collect Advance';

  @override
  String get paymentCollectedSuccess => 'Payment collected successfully';

  @override
  String get paymentStatusUnpaid => 'Unpaid';

  @override
  String get paymentStatusPartial => 'Partial';

  @override
  String get paymentStatusPaid => 'Paid';

  @override
  String get paymentStatusAdvancePaid => 'Advance Paid';

  @override
  String get quickFullPaid => 'Full Paid';

  @override
  String get quickHalfPaid => 'Half Paid';

  @override
  String get quickUnpaid => 'Unpaid (Credit)';

  @override
  String get quickToken500 => 'Rs 500 Advance';

  @override
  String get quickToken1000 => 'Rs 1,000 Advance';

  @override
  String get amountToCollect => 'Amount to Collect *';

  @override
  String get advancePrefix => 'Adv: Rs ';

  @override
  String get collectPaymentDescription =>
      'Record payment received and update customer ledger balance.';

  @override
  String get settingsTitle => 'Settings & Hotel Profile';

  @override
  String get hotelBusinessProfileSection => 'Hotel / Business Profile';

  @override
  String get businessLogoLabel => 'Business Logo';

  @override
  String get businessLogoHelper => 'Used on printed receipts & invoices';

  @override
  String get uploadButton => 'Upload';

  @override
  String get changeButton => 'Change';

  @override
  String get hotelBusinessNameLabel => 'Hotel / Business Name *';

  @override
  String get taglineLabel => 'Tagline / Slogan';

  @override
  String get contactPhoneLabel => 'Contact Phone';

  @override
  String get emailAddressLabel => 'Email Address';

  @override
  String get locationAddressLabel => 'Location / Address';

  @override
  String get ntnTaxNumberLabel => 'NTN / Tax Registration No.';

  @override
  String get invoiceAndAccountingSection => 'Invoice & Accounting';

  @override
  String get currencyLabel => 'Currency';

  @override
  String get currencyHint => 'Rs, \$, AED';

  @override
  String get taxRateLabel => 'Tax Rate (%)';

  @override
  String get enableTaxTitle => 'Enable Tax Calculation on Sales';

  @override
  String get enableTaxSubtitle =>
      'Automatically compute tax on invoices & receipts';

  @override
  String get invoiceFooterNoteLabel => 'Invoice Footer Note';

  @override
  String get invoiceFooterNoteHint =>
      'e.g. Thank you for your business! Visit again.';

  @override
  String get saveSettingsButton => 'Save Settings';

  @override
  String get settingsSavedSuccess => 'Settings saved successfully';

  @override
  String get languageSectionTitle => 'Language / زبان';

  @override
  String get selectLanguageTitle => 'Select Language / زبان منتخب کریں';

  @override
  String get englishLanguage => 'English';

  @override
  String get urduLanguage => 'اردو (Urdu)';

  @override
  String get languageChangedSuccess => 'Language changed successfully';

  @override
  String get themeSectionTitle => 'Theme / تھیم';

  @override
  String get themeDarkMode => 'Dark Mode';

  @override
  String get themeLightMode => 'Light Mode';

  @override
  String get themeSubtitle =>
      'Switch between light and dark frosted glass theme';
}
