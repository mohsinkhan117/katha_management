// lib/core/models/hotel_profile.dart

/// The hotel's own profile — name, address, phone, tax rate, currency.
/// A singleton per hotel (one document in Firestore), not a list of records.
class HotelProfile {
  final String name;
  final String address;
  final String phone;

  /// Percent, e.g. 5.0 for 5%.
  final double taxRate;

  final String currency;

  const HotelProfile({
    required this.name,
    required this.address,
    required this.phone,
    required this.taxRate,
    required this.currency,
  });

  static const defaults = HotelProfile(
    name: 'Pearl Hotel',
    address: 'Main Road, Peshawar',
    phone: '0928-xxxxxxx',
    taxRate: 5.0,
    currency: 'PKR',
  );

  HotelProfile copyWith({
    String? name,
    String? address,
    String? phone,
    double? taxRate,
    String? currency,
  }) {
    return HotelProfile(
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      taxRate: taxRate ?? this.taxRate,
      currency: currency ?? this.currency,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
      'taxRate': taxRate,
      'currency': currency,
    };
  }

  factory HotelProfile.fromMap(Map<String, dynamic> map) {
    return HotelProfile(
      name: map['name'] as String? ?? defaults.name,
      address: map['address'] as String? ?? defaults.address,
      phone: map['phone'] as String? ?? defaults.phone,
      taxRate: (map['taxRate'] as num?)?.toDouble() ?? defaults.taxRate,
      currency: map['currency'] as String? ?? defaults.currency,
    );
  }
}
