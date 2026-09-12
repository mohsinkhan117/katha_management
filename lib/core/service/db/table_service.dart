// lib/core/service/db/table_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:katha_management/core/models/hotelTable.dart';
import 'package:katha_management/core/service/db/firestore_paths.dart';

/// CRUD + real-time stream for the `tables` collection.
class TableService {
  TableService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<List<HotelTable>> tablesStream() {
    return _db
        .collection(FirestorePaths.tables)
        .orderBy('tableNumber')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => HotelTable.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<void> addTable(HotelTable table) {
    return _db.collection(FirestorePaths.tables).add(table.toMap());
  }

  Future<void> updateTable(HotelTable table) {
    return _db
        .collection(FirestorePaths.tables)
        .doc(table.id)
        .update(table.toMap());
  }

  Future<void> deleteTable(String tableId) {
    return _db.collection(FirestorePaths.tables).doc(tableId).delete();
  }

  /// Marks [tableId] occupied and links it to the order that just opened
  /// on it. Uses a raw field update rather than `HotelTable.copyWith`
  /// on purpose — see [freeTable].
  Future<void> occupyTable({required String tableId, required String orderId}) {
    return _db.collection(FirestorePaths.tables).doc(tableId).update({
      'status': TableStatus.occupied.name,
      'currentOrderId': orderId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Frees [tableId] for new customers once its order is finalized.
  ///
  /// NOTE: this intentionally does NOT go through `table.copyWith(...)`.
  /// `copyWith`'s `currentOrderId: currentOrderId ?? this.currentOrderId`
  /// pattern means passing `null` always falls back to the *old* value —
  /// there's no way to clear the field through it. `FieldValue.delete()`
  /// here removes it at the Firestore level instead, which `fromMap`
  /// already treats as `null` on read.
  Future<void> freeTable(String tableId) {
    return _db.collection(FirestorePaths.tables).doc(tableId).update({
      'status': TableStatus.available.name,
      'currentOrderId': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
