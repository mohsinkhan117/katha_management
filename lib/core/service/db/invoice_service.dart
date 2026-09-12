// lib/core/service/db/invoice_service.dart

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:katha_management/core/models/invoice.dart';
import 'package:katha_management/core/service/db/firestore_paths.dart';

/// CRUD + real-time stream for the `invoices` collection.
///
/// ASSUMES `FirestorePaths.invoices` exists (e.g. `static const invoices =
/// 'invoices';`) alongside `menu`/`tables`/`orders` — add it if missing.
class InvoiceService {
  InvoiceService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _invoices =>
      _db.collection(FirestorePaths.invoices);

  Stream<List<Invoice>> invoicesStream() {
    return _invoices
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => Invoice.fromMap(d.id, d.data())).toList(),
        );
  }

  /// Creates the invoice document and derives its human-readable
  /// [Invoice.invoiceNumber] from the generated doc id (e.g. "INV-A1B2C3").
  /// Two writes: Firestore doesn't know its own auto-id before `add()`
  /// returns, so the number can't be included in the first write.
  ///
  /// NOTE: this gives unique-but-not-sequential invoice numbers. If you
  /// need sequential numbering (INV-0001, INV-0002…) instead, swap this
  /// for a counter document updated inside a Firestore transaction — ask
  /// and I'll wire that up.
  Future<Invoice> createInvoice(Invoice invoice) async {
    final ref = await _invoices.add({
      ...invoice.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    final invoiceNumber = 'INV-${ref.id.substring(0, 6).toUpperCase()}';
    await ref.update({'invoiceNumber': invoiceNumber});

    return Invoice(
      id: ref.id,
      invoiceNumber: invoiceNumber,
      orderId: invoice.orderId,
      tableId: invoice.tableId,
      tableNumber: invoice.tableNumber,
      items: invoice.items,
      taxRate: invoice.taxRate,
      createdAt: DateTime.now(),
      printStatus: invoice.printStatus,
    );
  }

  Future<void> updatePrintStatus(String invoiceId, PrintStatus status) {
    return _invoices.doc(invoiceId).update({'printStatus': status.name});
  }
}
