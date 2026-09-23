// lib/core/services/party_report_pdf_service.dart

import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:katha_management/core/models/new_order/new_order_model.dart';
import 'package:katha_management/core/models/party_balance_summary.dart';
import 'package:katha_management/core/models/party_model.dart';
import 'package:katha_management/core/models/payment/payment_model.dart';
import 'package:katha_management/core/models/sale_model.dart';
import 'package:katha_management/core/models/settings/hotel_profile_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Generates and exports comprehensive PDF reports for a Party's complete
/// order history, sales, payment ledger, and financial balance statistics.
class PartyReportPdfService {
  static final DateFormat _dateFormat = DateFormat('dd-MM-yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd-MM-yyyy hh:mm a');

  /// Builds the PDF document byte array
  static Future<Uint8List> generatePdf({
    required PartyModel party,
    required PartyBalanceSummary? balance,
    required List<OrderModel> orders,
    required List<SaleModel> sales,
    required List<PaymentModel> payments,
    HotelProfileModel? hotelProfile,
  }) async {
    final pdf = pw.Document(
      title: '${party.name} - Statement & Order History',
      author: hotelProfile?.hotelName ?? 'Katha Management',
    );

    final profile = hotelProfile ?? HotelProfileModel.defaultProfile();
    final currency = profile.currencySymbol;

    final totalSales = sales.fold(0.0, (sum, s) => sum + s.totalAmount);
    final totalPayments = payments.fold(0.0, (sum, p) => sum + p.amount);
    final balanceDue = balance?.balanceDue ?? 0.0;
    final totalOrders = orders.length;
    final pendingOrders = orders.where((o) => o.status != OrderStatus.delivered).length;
    final deliveredOrders = orders.where((o) => o.status == OrderStatus.delivered).length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (context) => _buildHeader(profile, context),
        footer: (context) => _buildFooter(profile, context),
        build: (context) => [
          _buildPartyAndStatementBanner(party, balance, currency),
          pw.SizedBox(height: 12),
          _buildFinancialSummaryGrid(
            totalSales: totalSales,
            totalPayments: totalPayments,
            balanceDue: balanceDue,
            totalOrders: totalOrders,
            pendingOrders: pendingOrders,
            deliveredOrders: deliveredOrders,
            daysSinceOldestDue: balance?.daysSinceOldestDue,
            currency: currency,
          ),
          pw.SizedBox(height: 16),
          _buildOrdersSection(orders, currency),
          pw.SizedBox(height: 16),
          _buildSalesSection(sales, currency),
          pw.SizedBox(height: 16),
          _buildPaymentsSection(payments, currency),
        ],
      ),
    );

    return pdf.save();
  }

  /// Opens standard print / PDF preview dialog
  static Future<void> printOrPreview({
    required PartyModel party,
    required PartyBalanceSummary? balance,
    required List<OrderModel> orders,
    required List<SaleModel> sales,
    required List<PaymentModel> payments,
    HotelProfileModel? hotelProfile,
  }) async {
    final bytes = await generatePdf(
      party: party,
      balance: balance,
      orders: orders,
      sales: sales,
      payments: payments,
      hotelProfile: hotelProfile,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: 'Statement_${party.name.replaceAll(' ', '_')}_${_dateFormat.format(DateTime.now())}.pdf',
    );
  }

  /// Shares the PDF file across apps (WhatsApp, Email, Drive)
  static Future<void> sharePdf({
    required PartyModel party,
    required PartyBalanceSummary? balance,
    required List<OrderModel> orders,
    required List<SaleModel> sales,
    required List<PaymentModel> payments,
    HotelProfileModel? hotelProfile,
  }) async {
    final bytes = await generatePdf(
      party: party,
      balance: balance,
      orders: orders,
      sales: sales,
      payments: payments,
      hotelProfile: hotelProfile,
    );

    await Printing.sharePdf(
      bytes: bytes,
      filename: 'Statement_${party.name.replaceAll(' ', '_')}_${_dateFormat.format(DateTime.now())}.pdf',
    );
  }

  // ─── Document Header ───────────────────────────────────────────────
  static pw.Widget _buildHeader(HotelProfileModel profile, pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.blueGrey700, width: 1.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                profile.hotelName.isNotEmpty ? profile.hotelName : 'KATHA MANAGEMENT',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey900,
                ),
              ),
              if (profile.tagline != null && profile.tagline!.isNotEmpty)
                pw.Text(
                  profile.tagline!,
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
              if (profile.phone != null && profile.phone!.isNotEmpty)
                pw.Text(
                  'Phone: ${profile.phone!}',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
              if (profile.address != null && profile.address!.isNotEmpty)
                pw.Text(
                  profile.address!,
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blueGrey800,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'PARTY STATEMENT & HISTORY',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Date: ${_dateTimeFormat.format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Document Footer ───────────────────────────────────────────────
  static pw.Widget _buildFooter(HotelProfileModel profile, pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 0.8),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            profile.invoiceFooterNote ?? 'Thank you for your business.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  // ─── Party Info Banner ──────────────────────────────────────────────
  static pw.Widget _buildPartyAndStatementBanner(
    PartyModel party,
    PartyBalanceSummary? balance,
    String currency,
  ) {
    final due = balance?.balanceDue ?? 0.0;
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'PARTY DETAILS',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                party.name,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
              if (party.phone != null && party.phone!.isNotEmpty)
                pw.Text(
                  'Phone: ${party.phone!}',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                ),
              if (party.address != null && party.address!.isNotEmpty)
                pw.Text(
                  'Address: ${party.address!}',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: due > 0 ? PdfColors.red50 : PdfColors.green50,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(
                color: due > 0 ? PdfColors.red300 : PdfColors.green300,
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'CURRENT BALANCE DUE',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: due > 0 ? PdfColors.red800 : PdfColors.green800,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  '$currency ${due.toStringAsFixed(0)}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: due > 0 ? PdfColors.red900 : PdfColors.green900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Financial & Payment Statistics Grid ────────────────────────────
  static pw.Widget _buildFinancialSummaryGrid({
    required double totalSales,
    required double totalPayments,
    required double balanceDue,
    required int totalOrders,
    required int pendingOrders,
    required int deliveredOrders,
    int? daysSinceOldestDue,
    required String currency,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Expanded(
              child: _buildSummaryBox('TOTAL SALES', '$currency ${totalSales.toStringAsFixed(0)}', PdfColors.blue50, PdfColors.blue900),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: _buildSummaryBox('TOTAL PAYMENTS', '$currency ${totalPayments.toStringAsFixed(0)}', PdfColors.green50, PdfColors.green900),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: _buildSummaryBox(
                'BALANCE DUE',
                '$currency ${balanceDue.toStringAsFixed(0)}',
                balanceDue > 0 ? PdfColors.red50 : PdfColors.green50,
                balanceDue > 0 ? PdfColors.red900 : PdfColors.green900,
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: _buildSummaryBox('ORDERS ($totalOrders)', '$pendingOrders Pending / $deliveredOrders Done', PdfColors.purple50, PdfColors.purple900),
            ),
          ],
        ),
        if (daysSinceOldestDue != null) ...[
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: pw.BoxDecoration(
              color: PdfColors.amber50,
              borderRadius: pw.BorderRadius.circular(4),
              border: pw.Border.all(color: PdfColors.amber300),
            ),
            child: pw.Text(
              'Aging: $daysSinceOldestDue days since oldest unpaid sale invoice.',
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.amber900,
              ),
            ),
          ),
        ],
      ],
    );
  }

  static pw.Widget _buildSummaryBox(String title, String value, PdfColor bg, PdfColor textColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: textColor, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: textColor),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: textColor),
          ),
        ],
      ),
    );
  }

  // ─── Orders History Table & Item Breakdown ─────────────────────────
  static pw.Widget _buildOrdersSection(List<OrderModel> orders, String currency) {
    if (orders.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Text(
          'ORDERS HISTORY: No orders recorded for this party.',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          color: PdfColors.blueGrey800,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'COMPLETE ORDERS HISTORY',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.Text(
                'Total Orders: ${orders.length}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.white),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 4),
        ...orders.map((order) => _buildSingleOrderBlock(order, currency)),
      ],
    );
  }

  static pw.Widget _buildSingleOrderBlock(OrderModel order, String currency) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Order Header
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: PdfColors.grey200,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    pw.Text(
                      'Order #${order.id.length > 8 ? order.id.substring(0, 8) : order.id}',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      'Date: ${_dateFormat.format(order.orderDate)}',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
                    ),
                    if (order.expectedDeliveryDate != null) ...[
                      pw.SizedBox(width: 8),
                      pw.Text(
                        'Delivery: ${_dateFormat.format(order.expectedDeliveryDate!)}',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
                      ),
                    ],
                  ],
                ),
                pw.Row(
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: pw.BoxDecoration(
                        color: order.status == OrderStatus.delivered
                            ? PdfColors.green100
                            : PdfColors.orange100,
                        borderRadius: pw.BorderRadius.circular(3),
                        border: pw.Border.all(
                          color: order.status == OrderStatus.delivered
                              ? PdfColors.green400
                              : PdfColors.orange400,
                          width: 0.5,
                        ),
                      ),
                      child: pw.Text(
                        order.status.label.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 7,
                          fontWeight: pw.FontWeight.bold,
                          color: order.status == OrderStatus.delivered
                              ? PdfColors.green900
                              : PdfColors.orange900,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      '$currency ${order.totalAmount.toStringAsFixed(0)}',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Items Table
          pw.Table(
            border: const pw.TableBorder(
              horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(3),
              1: pw.FlexColumnWidth(1),
              2: pw.FlexColumnWidth(1.2),
              3: pw.FlexColumnWidth(1),
              4: pw.FlexColumnWidth(1.2),
            },
            children: [
              // Table Header
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _tableCell('Product & Size', isHeader: true),
                  _tableCell('Qty', isHeader: true, align: pw.TextAlign.center),
                  _tableCell('Unit Price', isHeader: true, align: pw.TextAlign.right),
                  _tableCell('Discount', isHeader: true, align: pw.TextAlign.right),
                  _tableCell('Subtotal', isHeader: true, align: pw.TextAlign.right),
                ],
              ),
              ...order.items.map((item) {
                return pw.TableRow(
                  children: [
                    _tableCell(item.productName),
                    _tableCell(
                      item.quantity.toStringAsFixed(
                        item.quantity.truncateToDouble() == item.quantity ? 0 : 2,
                      ),
                      align: pw.TextAlign.center,
                    ),
                    _tableCell('$currency ${item.unitPrice.toStringAsFixed(0)}', align: pw.TextAlign.right),
                    _tableCell(
                      item.discount > 0 ? '-$currency ${item.discount.toStringAsFixed(0)}' : '-',
                      align: pw.TextAlign.right,
                    ),
                    _tableCell(
                      '$currency ${item.subtotal.toStringAsFixed(0)}',
                      align: pw.TextAlign.right,
                      isBold: true,
                    ),
                  ],
                );
              }),
            ],
          ),

          if (order.note != null && order.note!.trim().isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(
                'Note: ${order.note!}',
                style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Sales & Invoices History Table ────────────────────────────────
  static pw.Widget _buildSalesSection(List<SaleModel> sales, String currency) {
    if (sales.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          color: PdfColors.blueGrey800,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'SALES & INVOICES HISTORY',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.Text(
                'Total Sales: ${sales.length}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.white),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: const {
            0: pw.FlexColumnWidth(1.2),
            1: pw.FlexColumnWidth(2.5),
            2: pw.FlexColumnWidth(1.2),
            3: pw.FlexColumnWidth(1.2),
            4: pw.FlexColumnWidth(1.2),
            5: pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _tableCell('Date', isHeader: true),
                _tableCell('Items', isHeader: true),
                _tableCell('Total', isHeader: true, align: pw.TextAlign.right),
                _tableCell('Paid', isHeader: true, align: pw.TextAlign.right),
                _tableCell('Due', isHeader: true, align: pw.TextAlign.right),
                _tableCell('Status', isHeader: true, align: pw.TextAlign.center),
              ],
            ),
            ...sales.map((sale) {
              final itemsSummary = sale.items
                  .map((i) => '${i.productName} (${i.quantity.toStringAsFixed(0)})')
                  .join(', ');
              return pw.TableRow(
                children: [
                  _tableCell(_dateFormat.format(sale.saleDate)),
                  _tableCell(itemsSummary.isNotEmpty ? itemsSummary : 'Direct Sale'),
                  _tableCell('$currency ${sale.totalAmount.toStringAsFixed(0)}', align: pw.TextAlign.right),
                  _tableCell('$currency ${sale.paidAmount.toStringAsFixed(0)}', align: pw.TextAlign.right),
                  _tableCell(
                    '$currency ${sale.balanceDue.toStringAsFixed(0)}',
                    align: pw.TextAlign.right,
                    isBold: sale.balanceDue > 0,
                  ),
                  _tableCell(sale.status.value.toUpperCase(), align: pw.TextAlign.center),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  // ─── Payments History Table ────────────────────────────────────────
  static pw.Widget _buildPaymentsSection(List<PaymentModel> payments, String currency) {
    if (payments.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          color: PdfColors.blueGrey800,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'PAYMENT TRANSACTIONS & RECEIPTS',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.Text(
                'Total Received: $currency ${payments.fold(0.0, (s, p) => s + p.amount).toStringAsFixed(0)}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.white),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: const {
            0: pw.FlexColumnWidth(1.2),
            1: pw.FlexColumnWidth(1.5),
            2: pw.FlexColumnWidth(1.5),
            3: pw.FlexColumnWidth(3),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _tableCell('Date', isHeader: true),
                _tableCell('Payment Mode', isHeader: true),
                _tableCell('Amount', isHeader: true, align: pw.TextAlign.right),
                _tableCell('Note / Reference', isHeader: true),
              ],
            ),
            ...payments.map((p) {
              return pw.TableRow(
                children: [
                  _tableCell(_dateFormat.format(p.paymentDate)),
                  _tableCell(p.mode.label),
                  _tableCell('$currency ${p.amount.toStringAsFixed(0)}', align: pw.TextAlign.right, isBold: true),
                  _tableCell(p.note != null && p.note!.isNotEmpty ? p.note! : '-'),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  static pw.Widget _tableCell(
    String text, {
    bool isHeader = false,
    bool isBold = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 7.5 : 7,
          fontWeight: isHeader || isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.black : PdfColors.grey900,
        ),
      ),
    );
  }
}

