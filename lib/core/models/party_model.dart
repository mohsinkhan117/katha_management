// lib\core\models\party_model.dart

import 'package:uuid/uuid.dart';

/// Loose categorization used for filtering the party list and for
/// quick visual grouping — free-form enough that it doesn't need a
/// separate lookup table.
enum PartyTag { wholesale, retail, distributor, vip, other }

extension PartyTagX on PartyTag {
  String get value => name;

  String get label {
    switch (this) {
      case PartyTag.wholesale:
        return 'Wholesale';
      case PartyTag.retail:
        return 'Retail';
      case PartyTag.distributor:
        return 'Distributor';
      case PartyTag.vip:
        return 'VIP';
      case PartyTag.other:
        return 'Other';
    }
  }

  static PartyTag? fromString(String? value) {
    if (value == null) return null;
    return PartyTag.values.firstWhere(
      (tag) => tag.name == value,
      orElse: () => PartyTag.other,
    );
  }
}

/// A customer / shop / retailer the business sells to.
///
/// This is the entity every other module (Sale, Order, Payment)
/// should eventually reference by `partyId` instead of the free-text
/// name matching those modules currently fall back on. Nothing about
/// this model requires that migration to happen all at once — those
/// modules can adopt real `partyId`s feature by feature.
///
/// `openingBalance` is the only balance ever *stored* here. A party's
/// live balance (opening + sales - payments) is a computed value that
/// belongs to the Ledger module, not this one — storing a running
/// balance here would risk it drifting out of sync with the actual
/// transactions.
class PartyModel {
  final String id;
  final String name;
  final String? phone;
  final String? address;
  final double openingBalance;
  final PartyTag? tag;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  // add the following extra more details 
  /*
  List<String> PhoneNumbers; // incase of more than a single phone number
  List<Order> orders; // I want to get all the orders, there complete stats(deliveryTime,status, paymentStatus, times, I mean All details of orders)

  also in view I want to show complete stats of company paymentsRecieved/ advance(Opening balance)/ remainingDues, promised dates of orders to be paid within
   */

  PartyModel({
    String? id,
    required this.name,
    this.phone,
    this.address,
    this.openingBalance = 0,
    this.tag,
    this.note,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'openingBalance': openingBalance,
      'tag': tag?.value,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory PartyModel.fromMap(Map<String, dynamic> map) {
    return PartyModel(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      openingBalance: (map['openingBalance'] as num?)?.toDouble() ?? 0,
      tag: PartyTagX.fromString(map['tag'] as String?),
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      isSynced: (map['isSynced'] as int?) == 1,
    );
  }

  PartyModel copyWith({
    String? name,
    String? phone,
    String? address,
    double? openingBalance,
    PartyTag? tag,
    String? note,
    bool? isSynced,
  }) {
    return PartyModel(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      openingBalance: openingBalance ?? this.openingBalance,
      tag: tag ?? this.tag,
      note: note ?? this.note,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
