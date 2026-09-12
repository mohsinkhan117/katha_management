class Hotel {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String? logoPath;
  final double taxRate;
  final String currency;

  const Hotel({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    this.logoPath,
    required this.taxRate,
    required this.currency,
  });

  factory Hotel.fromMap(String id, Map<String, dynamic> map) {
    return Hotel(
      id: id,
      name: map['name'] as String? ?? '',
      address: map['address'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      logoPath: map['logoPath'] as String?,
      taxRate: (map['taxRate'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'PKR',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
      'taxRate': taxRate,
      'currency': currency,

      // We intentionally do NOT save the local logo path to Firestore.
      //
      // The logo belongs to the device's local storage.
    };
  }

  Hotel copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    String? logoPath,
    double? taxRate,
    String? currency,
  }) {
    return Hotel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      logoPath: logoPath ?? this.logoPath,
      taxRate: taxRate ?? this.taxRate,
      currency: currency ?? this.currency,
    );
  }
}
