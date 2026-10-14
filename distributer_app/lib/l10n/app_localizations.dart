import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ur'),
  ];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'Katha Management'**
  String get appTitle;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Rs'**
  String get currency;

  /// No description provided for @currencyPrefix.
  ///
  /// In en, this message translates to:
  /// **'Rs '**
  String get currencyPrefix;

  /// No description provided for @percentSuffix.
  ///
  /// In en, this message translates to:
  /// **'%'**
  String get percentSuffix;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @noteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteOptional;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @noPhoneOnFile.
  ///
  /// In en, this message translates to:
  /// **'No phone on file'**
  String get noPhoneOnFile;

  /// No description provided for @noPhone.
  ///
  /// In en, this message translates to:
  /// **'No phone'**
  String get noPhone;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get navOrders;

  /// No description provided for @navCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get navCustomers;

  /// No description provided for @navParties.
  ///
  /// In en, this message translates to:
  /// **'Parties'**
  String get navParties;

  /// No description provided for @navProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get navProducts;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @todaysSales.
  ///
  /// In en, this message translates to:
  /// **'Today\'\'s Sales'**
  String get todaysSales;

  /// No description provided for @todaysCollection.
  ///
  /// In en, this message translates to:
  /// **'Today\'\'s Collection'**
  String get todaysCollection;

  /// No description provided for @receivables.
  ///
  /// In en, this message translates to:
  /// **'Receivables'**
  String get receivables;

  /// No description provided for @topPendingParties.
  ///
  /// In en, this message translates to:
  /// **'Top Pending Parties'**
  String get topPendingParties;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @noPendingBalances.
  ///
  /// In en, this message translates to:
  /// **'No pending balances'**
  String get noPendingBalances;

  /// No description provided for @noRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'No recent activity'**
  String get noRecentActivity;

  /// No description provided for @daysOverdueSuffix.
  ///
  /// In en, this message translates to:
  /// **'d overdue'**
  String get daysOverdueSuffix;

  /// No description provided for @openingBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Previous Due (Opening Balance)'**
  String get openingBalanceLabel;

  /// No description provided for @quickActionNewSale.
  ///
  /// In en, this message translates to:
  /// **'New Sale'**
  String get quickActionNewSale;

  /// No description provided for @quickActionNewOrder.
  ///
  /// In en, this message translates to:
  /// **'New Order'**
  String get quickActionNewOrder;

  /// No description provided for @quickActionAddPayment.
  ///
  /// In en, this message translates to:
  /// **'Add Payment'**
  String get quickActionAddPayment;

  /// No description provided for @quickActionAddParty.
  ///
  /// In en, this message translates to:
  /// **'Add Party'**
  String get quickActionAddParty;

  /// No description provided for @activityTypeSale.
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get activityTypeSale;

  /// No description provided for @activityTypePayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get activityTypePayment;

  /// No description provided for @activityTypeOrder.
  ///
  /// In en, this message translates to:
  /// **'Order Placed'**
  String get activityTypeOrder;

  /// No description provided for @customersTitle.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customersTitle;

  /// No description provided for @addPartyTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Party'**
  String get addPartyTitle;

  /// No description provided for @searchCustomersHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or phone'**
  String get searchCustomersHint;

  /// No description provided for @noCustomersYet.
  ///
  /// In en, this message translates to:
  /// **'No customers yet'**
  String get noCustomersYet;

  /// No description provided for @settled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get settled;

  /// No description provided for @basicInfoSection.
  ///
  /// In en, this message translates to:
  /// **'Basic Info'**
  String get basicInfoSection;

  /// No description provided for @partyNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Party name *'**
  String get partyNameLabel;

  /// No description provided for @partyPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get partyPhoneLabel;

  /// No description provided for @partyAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address (optional)'**
  String get partyAddressLabel;

  /// No description provided for @categorySection.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categorySection;

  /// No description provided for @openingBalanceSection.
  ///
  /// In en, this message translates to:
  /// **'Previous Due (Opening Balance)'**
  String get openingBalanceSection;

  /// No description provided for @openingBalanceAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Unpaid Due Amount (optional)'**
  String get openingBalanceAmountLabel;

  /// No description provided for @openingBalanceHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter previous unpaid balance / due carried over from before this app'**
  String get openingBalanceHelper;

  /// No description provided for @openingBalanceInfoNote.
  ///
  /// In en, this message translates to:
  /// **'Previous unpaid balance carried over from before this app'**
  String get openingBalanceInfoNote;

  /// No description provided for @savePartyButton.
  ///
  /// In en, this message translates to:
  /// **'Save Party'**
  String get savePartyButton;

  /// No description provided for @updatePartyButton.
  ///
  /// In en, this message translates to:
  /// **'Update Party'**
  String get updatePartyButton;

  /// No description provided for @editPartyTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Party'**
  String get editPartyTitle;

  /// No description provided for @partyAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Party added'**
  String get partyAddedSuccess;

  /// No description provided for @partyUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Party updated successfully'**
  String get partyUpdatedSuccess;

  /// No description provided for @deletePartyTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Party?'**
  String get deletePartyTitle;

  /// No description provided for @deletePartyMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this party? All related transaction history may be affected.'**
  String get deletePartyMessage;

  /// No description provided for @deletePartyButton.
  ///
  /// In en, this message translates to:
  /// **'Delete Party'**
  String get deletePartyButton;

  /// No description provided for @partyDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Party deleted successfully'**
  String get partyDeletedSuccess;

  /// No description provided for @partyDetailsSection.
  ///
  /// In en, this message translates to:
  /// **'Party Details'**
  String get partyDetailsSection;

  /// No description provided for @selectExistingCustomer.
  ///
  /// In en, this message translates to:
  /// **'Select Existing Customer'**
  String get selectExistingCustomer;

  /// No description provided for @selectCustomer.
  ///
  /// In en, this message translates to:
  /// **'Select Customer'**
  String get selectCustomer;

  /// No description provided for @partyNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Party name is required'**
  String get partyNameRequired;

  /// No description provided for @ordersTitle.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get ordersTitle;

  /// No description provided for @tabPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get tabPending;

  /// No description provided for @tabDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get tabDone;

  /// No description provided for @searchOrdersHint.
  ///
  /// In en, this message translates to:
  /// **'Search orders by party, item, or note...'**
  String get searchOrdersHint;

  /// No description provided for @noPendingOrders.
  ///
  /// In en, this message translates to:
  /// **'No pending orders'**
  String get noPendingOrders;

  /// No description provided for @noDoneOrders.
  ///
  /// In en, this message translates to:
  /// **'No completed/cancelled orders'**
  String get noDoneOrders;

  /// No description provided for @newOrderButton.
  ///
  /// In en, this message translates to:
  /// **'New Order'**
  String get newOrderButton;

  /// No description provided for @editOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Order'**
  String get editOrderTitle;

  /// No description provided for @updateOrderButton.
  ///
  /// In en, this message translates to:
  /// **'Update Order'**
  String get updateOrderButton;

  /// No description provided for @orderConvertedToSale.
  ///
  /// In en, this message translates to:
  /// **'Order converted to Sale invoice'**
  String get orderConvertedToSale;

  /// No description provided for @orderedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Ordered: '**
  String get orderedPrefix;

  /// No description provided for @updatedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Updated: '**
  String get updatedPrefix;

  /// No description provided for @deliveryByPrefix.
  ///
  /// In en, this message translates to:
  /// **'Delivery by: '**
  String get deliveryByPrefix;

  /// No description provided for @viewItems.
  ///
  /// In en, this message translates to:
  /// **'View items'**
  String get viewItems;

  /// No description provided for @hideItems.
  ///
  /// In en, this message translates to:
  /// **'Hide items'**
  String get hideItems;

  /// No description provided for @cancelOrderTooltip.
  ///
  /// In en, this message translates to:
  /// **'Cancel order'**
  String get cancelOrderTooltip;

  /// No description provided for @cancelOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel Order?'**
  String get cancelOrderTitle;

  /// No description provided for @cancelOrderMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this order?'**
  String get cancelOrderMessage;

  /// No description provided for @yesCancel.
  ///
  /// In en, this message translates to:
  /// **'Yes, Cancel'**
  String get yesCancel;

  /// No description provided for @deleteOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Order?'**
  String get deleteOrderTitle;

  /// No description provided for @deleteOrderMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete this order?'**
  String get deleteOrderMessage;

  /// No description provided for @deleteOrderButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteOrderButton;

  /// No description provided for @orderDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Order deleted successfully'**
  String get orderDeletedSuccess;

  /// No description provided for @cannotEditDeliveredOrPaidOrder.
  ///
  /// In en, this message translates to:
  /// **'Orders that are Delivered or Paid cannot be modified.'**
  String get cannotEditDeliveredOrPaidOrder;

  /// No description provided for @convertedToSaleBadge.
  ///
  /// In en, this message translates to:
  /// **'Converted to Sale'**
  String get convertedToSaleBadge;

  /// No description provided for @convertToSaleButton.
  ///
  /// In en, this message translates to:
  /// **'Convert to Sale'**
  String get convertToSaleButton;

  /// No description provided for @changeStatusTooltip.
  ///
  /// In en, this message translates to:
  /// **'Change Status'**
  String get changeStatusTooltip;

  /// No description provided for @expectedDeliveryDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Expected Delivery Date'**
  String get expectedDeliveryDateLabel;

  /// No description provided for @expectedDeliveryPrefix.
  ///
  /// In en, this message translates to:
  /// **'Expected Delivery: '**
  String get expectedDeliveryPrefix;

  /// No description provided for @expectedDeliveryDateOptional.
  ///
  /// In en, this message translates to:
  /// **'Expected delivery date (optional)'**
  String get expectedDeliveryDateOptional;

  /// No description provided for @deliveryDateOptional.
  ///
  /// In en, this message translates to:
  /// **'Delivery date (optional)'**
  String get deliveryDateOptional;

  /// No description provided for @changePartyTooltip.
  ///
  /// In en, this message translates to:
  /// **'Change Party'**
  String get changePartyTooltip;

  /// No description provided for @newOrderPlacedStatusInfo.
  ///
  /// In en, this message translates to:
  /// **'New orders will be created with status: Placed'**
  String get newOrderPlacedStatusInfo;

  /// No description provided for @selectExpectedDeliveryDateHint.
  ///
  /// In en, this message translates to:
  /// **'Select expected delivery date'**
  String get selectExpectedDeliveryDateHint;

  /// No description provided for @estimatedTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Estimated Total'**
  String get estimatedTotalLabel;

  /// No description provided for @orderPlacedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Order placed successfully'**
  String get orderPlacedSuccess;

  /// No description provided for @placeOrderButton.
  ///
  /// In en, this message translates to:
  /// **'Place Order'**
  String get placeOrderButton;

  /// No description provided for @orderSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Order saved successfully'**
  String get orderSavedSuccess;

  /// No description provided for @orderUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Order updated successfully'**
  String get orderUpdatedSuccess;

  /// No description provided for @markDelivered.
  ///
  /// In en, this message translates to:
  /// **'Mark Delivered'**
  String get markDelivered;

  /// No description provided for @markPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark Paid'**
  String get markPaid;

  /// No description provided for @orderPaidSuccess.
  ///
  /// In en, this message translates to:
  /// **'Order marked as Paid and balance settled'**
  String get orderPaidSuccess;

  /// No description provided for @itemSingular.
  ///
  /// In en, this message translates to:
  /// **'item'**
  String get itemSingular;

  /// No description provided for @itemsPlural.
  ///
  /// In en, this message translates to:
  /// **'items'**
  String get itemsPlural;

  /// No description provided for @productsTitle.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get productsTitle;

  /// No description provided for @addProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProductTitle;

  /// No description provided for @editProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get editProductTitle;

  /// No description provided for @searchProductsHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or SKU'**
  String get searchProductsHint;

  /// No description provided for @noProductsYet.
  ///
  /// In en, this message translates to:
  /// **'No products yet'**
  String get noProductsYet;

  /// No description provided for @lowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get lowStock;

  /// No description provided for @productNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Product name *'**
  String get productNameLabel;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptional;

  /// No description provided for @skuLabel.
  ///
  /// In en, this message translates to:
  /// **'SKU / Code'**
  String get skuLabel;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @baseUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Base unit (optional)'**
  String get baseUnitLabel;

  /// No description provided for @baseUnitHelper.
  ///
  /// In en, this message translates to:
  /// **'e.g. piece, kg, box — what sizes below are variants of'**
  String get baseUnitHelper;

  /// No description provided for @sellingPriceSection.
  ///
  /// In en, this message translates to:
  /// **'Selling Price'**
  String get sellingPriceSection;

  /// No description provided for @sellingPriceDescription.
  ///
  /// In en, this message translates to:
  /// **'What the customer sees and pays.'**
  String get sellingPriceDescription;

  /// No description provided for @retailPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Retail price *'**
  String get retailPriceLabel;

  /// No description provided for @discountLabel.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discountLabel;

  /// No description provided for @customerPays.
  ///
  /// In en, this message translates to:
  /// **'Customer Pays'**
  String get customerPays;

  /// No description provided for @costAndProfitMarginSection.
  ///
  /// In en, this message translates to:
  /// **'Cost & Profit Margin'**
  String get costAndProfitMarginSection;

  /// No description provided for @costAndProfitMarginDescription.
  ///
  /// In en, this message translates to:
  /// **'What this product costs you to buy or produce. Used only to show your profit below — customers never see this.'**
  String get costAndProfitMarginDescription;

  /// No description provided for @costPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Cost price'**
  String get costPriceLabel;

  /// No description provided for @costPriceOptional.
  ///
  /// In en, this message translates to:
  /// **'Cost price (optional)'**
  String get costPriceOptional;

  /// No description provided for @costPriceHelper.
  ///
  /// In en, this message translates to:
  /// **'Used to calculate profit margin for this size'**
  String get costPriceHelper;

  /// No description provided for @enterCostPriceHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a cost price to see your profit margin here.'**
  String get enterCostPriceHint;

  /// No description provided for @stockQuantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Stock qty (optional)'**
  String get stockQuantityLabel;

  /// No description provided for @sellingBelowCost.
  ///
  /// In en, this message translates to:
  /// **'Selling Below Cost'**
  String get sellingBelowCost;

  /// No description provided for @profitMargin.
  ///
  /// In en, this message translates to:
  /// **'Profit Margin'**
  String get profitMargin;

  /// No description provided for @perUnit.
  ///
  /// In en, this message translates to:
  /// **'per unit'**
  String get perUnit;

  /// No description provided for @statusSection.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusSection;

  /// No description provided for @sizeVariantsSection.
  ///
  /// In en, this message translates to:
  /// **'Size / Price Variants'**
  String get sizeVariantsSection;

  /// No description provided for @noSizeVariantsNote.
  ///
  /// In en, this message translates to:
  /// **'No size variants — product will use the retail price above'**
  String get noSizeVariantsNote;

  /// No description provided for @sizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Size label'**
  String get sizeLabel;

  /// No description provided for @sizeLabelHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 1 Liter, 5Kg, Dozen'**
  String get sizeLabelHint;

  /// No description provided for @priceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get priceLabel;

  /// No description provided for @sellingPricePrefix.
  ///
  /// In en, this message translates to:
  /// **'Selling Price: Rs '**
  String get sellingPricePrefix;

  /// No description provided for @marginPrefix.
  ///
  /// In en, this message translates to:
  /// **'Margin: Rs '**
  String get marginPrefix;

  /// No description provided for @addSizeButton.
  ///
  /// In en, this message translates to:
  /// **'Add Size'**
  String get addSizeButton;

  /// No description provided for @updateProductButton.
  ///
  /// In en, this message translates to:
  /// **'Update Product'**
  String get updateProductButton;

  /// No description provided for @saveProductButton.
  ///
  /// In en, this message translates to:
  /// **'Save Product'**
  String get saveProductButton;

  /// No description provided for @productAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Product added'**
  String get productAddedSuccess;

  /// No description provided for @productUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Product updated'**
  String get productUpdatedSuccess;

  /// No description provided for @selectPackageSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Select Package Size'**
  String get selectPackageSizeLabel;

  /// No description provided for @newSaleTitle.
  ///
  /// In en, this message translates to:
  /// **'New Sale'**
  String get newSaleTitle;

  /// No description provided for @selectProductsSection.
  ///
  /// In en, this message translates to:
  /// **'Select Products'**
  String get selectProductsSection;

  /// No description provided for @selectProductsInstruction.
  ///
  /// In en, this message translates to:
  /// **'Check products to add. Select size variants from dropdown and customize prices if needed.'**
  String get selectProductsInstruction;

  /// No description provided for @searchCatalogHint.
  ///
  /// In en, this message translates to:
  /// **'Search products by name, sku, or category...'**
  String get searchCatalogHint;

  /// No description provided for @noProductsFoundInCatalog.
  ///
  /// In en, this message translates to:
  /// **'No products found in catalog. You can add one below.'**
  String get noProductsFoundInCatalog;

  /// No description provided for @customItemSection.
  ///
  /// In en, this message translates to:
  /// **'Custom / Non-Catalog Item'**
  String get customItemSection;

  /// No description provided for @customItemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'For one-off items or products not yet in your inventory'**
  String get customItemSubtitle;

  /// No description provided for @addCustomItemButton.
  ///
  /// In en, this message translates to:
  /// **'Add Custom Item'**
  String get addCustomItemButton;

  /// No description provided for @itemNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Item name *'**
  String get itemNameLabel;

  /// No description provided for @rateOrPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Rate / Price (Rs) *'**
  String get rateOrPriceLabel;

  /// No description provided for @quantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity *'**
  String get quantityLabel;

  /// No description provided for @discountPercentageLabel.
  ///
  /// In en, this message translates to:
  /// **'Discount (%)'**
  String get discountPercentageLabel;

  /// No description provided for @paymentAndSettlementSection.
  ///
  /// In en, this message translates to:
  /// **'Payment & Settlement'**
  String get paymentAndSettlementSection;

  /// No description provided for @paidAmountUpfrontLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid amount upfront (optional)'**
  String get paidAmountUpfrontLabel;

  /// No description provided for @paidAmountHelper.
  ///
  /// In en, this message translates to:
  /// **'Will automatically be credited & recorded to ledger'**
  String get paidAmountHelper;

  /// No description provided for @saveSaleButton.
  ///
  /// In en, this message translates to:
  /// **'Save Sale'**
  String get saveSaleButton;

  /// No description provided for @saleSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Sale saved successfully'**
  String get saleSavedSuccess;

  /// No description provided for @subtotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotalLabel;

  /// No description provided for @discountAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discountAmountLabel;

  /// No description provided for @taxLabel.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get taxLabel;

  /// No description provided for @totalAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmountLabel;

  /// No description provided for @paidUpfrontLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid Upfront'**
  String get paidUpfrontLabel;

  /// No description provided for @balanceDueLabel.
  ///
  /// In en, this message translates to:
  /// **'Balance Due'**
  String get balanceDueLabel;

  /// No description provided for @paymentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get paymentsTitle;

  /// No description provided for @recordPaymentButton.
  ///
  /// In en, this message translates to:
  /// **'Record Payment'**
  String get recordPaymentButton;

  /// No description provided for @noPaymentsYet.
  ///
  /// In en, this message translates to:
  /// **'No payments recorded yet.'**
  String get noPaymentsYet;

  /// No description provided for @deletePaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete payment?'**
  String get deletePaymentTitle;

  /// No description provided for @deletePaymentConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will remove the payment and its allocations.'**
  String get deletePaymentConfirm;

  /// No description provided for @paymentRecordedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded successfully'**
  String get paymentRecordedSuccess;

  /// No description provided for @paymentModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Mode'**
  String get paymentModeLabel;

  /// No description provided for @amountRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount (Rs) *'**
  String get amountRequiredLabel;

  /// No description provided for @savePaymentButton.
  ///
  /// In en, this message translates to:
  /// **'Save Payment'**
  String get savePaymentButton;

  /// No description provided for @enterValidPaymentAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid payment amount'**
  String get enterValidPaymentAmount;

  /// No description provided for @partyHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Party History'**
  String get partyHistoryTitle;

  /// No description provided for @exportPrintPdfTooltip.
  ///
  /// In en, this message translates to:
  /// **'Export & Print PDF Statement'**
  String get exportPrintPdfTooltip;

  /// No description provided for @sharePdfTooltip.
  ///
  /// In en, this message translates to:
  /// **'Share PDF Statement'**
  String get sharePdfTooltip;

  /// No description provided for @netBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Net Balance'**
  String get netBalanceLabel;

  /// No description provided for @totalSalesStat.
  ///
  /// In en, this message translates to:
  /// **'Total Sales'**
  String get totalSalesStat;

  /// No description provided for @paymentsStat.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get paymentsStat;

  /// No description provided for @balanceDueStat.
  ///
  /// In en, this message translates to:
  /// **'Balance Due'**
  String get balanceDueStat;

  /// No description provided for @ordersStat.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get ordersStat;

  /// No description provided for @daysSinceOldestUnpaidSale.
  ///
  /// In en, this message translates to:
  /// **'days since oldest unpaid sale invoice'**
  String get daysSinceOldestUnpaidSale;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get filterOrders;

  /// No description provided for @filterSales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get filterSales;

  /// No description provided for @filterPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get filterPayments;

  /// No description provided for @noTransactionsRecorded.
  ///
  /// In en, this message translates to:
  /// **'No transactions or orders recorded yet'**
  String get noTransactionsRecorded;

  /// No description provided for @orderItemsLabel.
  ///
  /// In en, this message translates to:
  /// **'Order Items:'**
  String get orderItemsLabel;

  /// No description provided for @saleItemsLabel.
  ///
  /// In en, this message translates to:
  /// **'Sale Items:'**
  String get saleItemsLabel;

  /// No description provided for @paidPrefix.
  ///
  /// In en, this message translates to:
  /// **'Paid: Rs '**
  String get paidPrefix;

  /// No description provided for @duePrefix.
  ///
  /// In en, this message translates to:
  /// **'Due: Rs '**
  String get duePrefix;

  /// No description provided for @datePrefix.
  ///
  /// In en, this message translates to:
  /// **'Date: '**
  String get datePrefix;

  /// No description provided for @paymentModePrefix.
  ///
  /// In en, this message translates to:
  /// **'Payment Mode: '**
  String get paymentModePrefix;

  /// No description provided for @actionSale.
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get actionSale;

  /// No description provided for @actionOrder.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get actionOrder;

  /// No description provided for @actionPay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get actionPay;

  /// No description provided for @advancePaymentSection.
  ///
  /// In en, this message translates to:
  /// **'Advance Payment (Optional)'**
  String get advancePaymentSection;

  /// No description provided for @advancePaidLabel.
  ///
  /// In en, this message translates to:
  /// **'Advance Paid'**
  String get advancePaidLabel;

  /// No description provided for @advancePaidHelper.
  ///
  /// In en, this message translates to:
  /// **'Advance / token amount collected with this order'**
  String get advancePaidHelper;

  /// No description provided for @collectPayment.
  ///
  /// In en, this message translates to:
  /// **'Collect Payment'**
  String get collectPayment;

  /// No description provided for @receivePayment.
  ///
  /// In en, this message translates to:
  /// **'Receive Payment'**
  String get receivePayment;

  /// No description provided for @collectAdvancePayment.
  ///
  /// In en, this message translates to:
  /// **'Collect Advance'**
  String get collectAdvancePayment;

  /// No description provided for @paymentCollectedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Payment collected successfully'**
  String get paymentCollectedSuccess;

  /// No description provided for @paymentStatusUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get paymentStatusUnpaid;

  /// No description provided for @paymentStatusPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get paymentStatusPartial;

  /// No description provided for @paymentStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paymentStatusPaid;

  /// No description provided for @paymentStatusAdvancePaid.
  ///
  /// In en, this message translates to:
  /// **'Advance Paid'**
  String get paymentStatusAdvancePaid;

  /// No description provided for @quickFullPaid.
  ///
  /// In en, this message translates to:
  /// **'Full Paid'**
  String get quickFullPaid;

  /// No description provided for @quickHalfPaid.
  ///
  /// In en, this message translates to:
  /// **'Half Paid'**
  String get quickHalfPaid;

  /// No description provided for @quickUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid (Credit)'**
  String get quickUnpaid;

  /// No description provided for @quickToken500.
  ///
  /// In en, this message translates to:
  /// **'Rs 500 Advance'**
  String get quickToken500;

  /// No description provided for @quickToken1000.
  ///
  /// In en, this message translates to:
  /// **'Rs 1,000 Advance'**
  String get quickToken1000;

  /// No description provided for @amountToCollect.
  ///
  /// In en, this message translates to:
  /// **'Amount to Collect *'**
  String get amountToCollect;

  /// No description provided for @advancePrefix.
  ///
  /// In en, this message translates to:
  /// **'Adv: Rs '**
  String get advancePrefix;

  /// No description provided for @collectPaymentDescription.
  ///
  /// In en, this message translates to:
  /// **'Record payment received and update customer ledger balance.'**
  String get collectPaymentDescription;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings & Hotel Profile'**
  String get settingsTitle;

  /// No description provided for @hotelBusinessProfileSection.
  ///
  /// In en, this message translates to:
  /// **'Hotel / Business Profile'**
  String get hotelBusinessProfileSection;

  /// No description provided for @businessLogoLabel.
  ///
  /// In en, this message translates to:
  /// **'Business Logo'**
  String get businessLogoLabel;

  /// No description provided for @businessLogoHelper.
  ///
  /// In en, this message translates to:
  /// **'Used on printed receipts & invoices'**
  String get businessLogoHelper;

  /// No description provided for @uploadButton.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get uploadButton;

  /// No description provided for @changeButton.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeButton;

  /// No description provided for @hotelBusinessNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Hotel / Business Name *'**
  String get hotelBusinessNameLabel;

  /// No description provided for @taglineLabel.
  ///
  /// In en, this message translates to:
  /// **'Tagline / Slogan'**
  String get taglineLabel;

  /// No description provided for @contactPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact Phone'**
  String get contactPhoneLabel;

  /// No description provided for @emailAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddressLabel;

  /// No description provided for @locationAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Location / Address'**
  String get locationAddressLabel;

  /// No description provided for @ntnTaxNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'NTN / Tax Registration No.'**
  String get ntnTaxNumberLabel;

  /// No description provided for @invoiceAndAccountingSection.
  ///
  /// In en, this message translates to:
  /// **'Invoice & Accounting'**
  String get invoiceAndAccountingSection;

  /// No description provided for @currencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currencyLabel;

  /// No description provided for @currencyHint.
  ///
  /// In en, this message translates to:
  /// **'Rs, \$, AED'**
  String get currencyHint;

  /// No description provided for @taxRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Tax Rate (%)'**
  String get taxRateLabel;

  /// No description provided for @enableTaxTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable Tax Calculation on Sales'**
  String get enableTaxTitle;

  /// No description provided for @enableTaxSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically compute tax on invoices & receipts'**
  String get enableTaxSubtitle;

  /// No description provided for @invoiceFooterNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Invoice Footer Note'**
  String get invoiceFooterNoteLabel;

  /// No description provided for @invoiceFooterNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Thank you for your business! Visit again.'**
  String get invoiceFooterNoteHint;

  /// No description provided for @saveSettingsButton.
  ///
  /// In en, this message translates to:
  /// **'Save Settings'**
  String get saveSettingsButton;

  /// No description provided for @settingsSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Settings saved successfully'**
  String get settingsSavedSuccess;

  /// No description provided for @languageSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Language / زبان'**
  String get languageSectionTitle;

  /// No description provided for @selectLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Language / زبان منتخب کریں'**
  String get selectLanguageTitle;

  /// No description provided for @englishLanguage.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get englishLanguage;

  /// No description provided for @urduLanguage.
  ///
  /// In en, this message translates to:
  /// **'اردو (Urdu)'**
  String get urduLanguage;

  /// No description provided for @languageChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Language changed successfully'**
  String get languageChangedSuccess;

  /// No description provided for @themeSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme / تھیم'**
  String get themeSectionTitle;

  /// No description provided for @themeDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get themeDarkMode;

  /// No description provided for @themeLightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get themeLightMode;

  /// No description provided for @themeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Switch between light and dark frosted glass theme'**
  String get themeSubtitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ur'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
