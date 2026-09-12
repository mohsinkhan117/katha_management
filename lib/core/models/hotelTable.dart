// lib/core/models/hotel_table.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum TableStatus { available, occupied, reserved }

TableStatus tableStatusFromString(String? value) {
  return TableStatus.values.firstWhere(
    (s) => s.name == value,
    orElse: () => TableStatus.available,
  );
}

class HotelTable {
  final String id;
  final int tableNumber;
  final int capacity;
  final TableStatus status;

  /// Id of the [Order] currently open on this table, if any — lets Home
  /// resume an in-progress order instead of starting a new one.
  final String? currentOrderId;

  const HotelTable({
    required this.id,
    required this.tableNumber,
    required this.capacity,
    required this.status,
    this.currentOrderId,
  });

  factory HotelTable.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    final statusString = data['status'] as String? ?? 'available';

    final status = TableStatus.values.firstWhere(
      (value) => value.name == statusString,
      orElse: () => TableStatus.available,
    );

    return HotelTable(
      id: doc.id,
      tableNumber: (data['tableNumber'] as num?)?.toInt() ?? 0,
      capacity: (data['capacity'] as num?)?.toInt() ?? 0,
      status: status,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tableNumber': tableNumber,
      'capacity': capacity,
      'status': status.name,
    };
  }

  HotelTable copyWith({
    String? id,
    int? tableNumber,
    int? capacity,
    TableStatus? status,
    String? currentOrderId,
  }) {
    return HotelTable(
      id: id ?? this.id,
      tableNumber: tableNumber ?? this.tableNumber,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      currentOrderId: currentOrderId ?? this.currentOrderId,
    );
  }

  factory HotelTable.fromMap(String id, Map<String, dynamic> map) {
    return HotelTable(
      id: id,
      tableNumber: (map['tableNumber'] as num?)?.toInt() ?? 0,
      capacity: (map['capacity'] as num?)?.toInt() ?? 0,
      status: tableStatusFromString(map['status'] as String?),
      currentOrderId: map['currentOrderId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tableNumber': tableNumber,
      'capacity': capacity,
      'status': status.name,
      'currentOrderId': currentOrderId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
