// lib/core/models/settings/hotel_profile_model.dart

class HotelProfileModel {
  final String id;
  final String hotelName;
  final String? tagline;
  final String? phone;
  final String? email;
  final String? address;
  final String? ntnOrTaxNumber;
  final String currencySymbol;
  final String? invoiceFooterNote;
  final String? logoPath;
  final bool enableTax;
  final double taxPercentage;
  final DateTime updatedAt;

  HotelProfileModel({
    this.id = 'default_profile',
    required this.hotelName,
    this.tagline,
    this.phone,
    this.email,
    this.address,
    this.ntnOrTaxNumber,
    this.currencySymbol = 'Rs',
    this.invoiceFooterNote,
    this.logoPath,
    this.enableTax = false,
    this.taxPercentage = 0.0,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  /// Default placeholder profile when no profile has been saved yet
  factory HotelProfileModel.defaultProfile() {
    return HotelProfileModel(
      id: 'default_profile',
      hotelName: 'My Business / Hotel',
      tagline: 'Quality Food & Service',
      currencySymbol: 'Rs',
      invoiceFooterNote: 'Thank you for your business!',
      enableTax: false,
      taxPercentage: 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hotelName': hotelName,
      'tagline': tagline,
      'phone': phone,
      'email': email,
      'address': address,
      'ntnOrTaxNumber': ntnOrTaxNumber,
      'currencySymbol': currencySymbol,
      'invoiceFooterNote': invoiceFooterNote,
      'logoPath': logoPath,
      'enableTax': enableTax ? 1 : 0,
      'taxPercentage': taxPercentage,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory HotelProfileModel.fromMap(Map<String, dynamic> map) {
    return HotelProfileModel(
      id: map['id'] as String? ?? 'default_profile',
      hotelName: map['hotelName'] as String? ?? '',
      tagline: map['tagline'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
      ntnOrTaxNumber: map['ntnOrTaxNumber'] as String?,
      currencySymbol: map['currencySymbol'] as String? ?? 'Rs',
      invoiceFooterNote: map['invoiceFooterNote'] as String?,
      logoPath: map['logoPath'] as String?,
      enableTax: (map['enableTax'] as int?) == 1,
      taxPercentage: (map['taxPercentage'] as num?)?.toDouble() ?? 0.0,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  HotelProfileModel copyWith({
    String? id,
    String? hotelName,
    String? tagline,
    String? phone,
    String? email,
    String? address,
    String? ntnOrTaxNumber,
    String? currencySymbol,
    String? invoiceFooterNote,
    String? logoPath,
    bool? enableTax,
    double? taxPercentage,
    DateTime? updatedAt,
  }) {
    return HotelProfileModel(
      id: id ?? this.id,
      hotelName: hotelName ?? this.hotelName,
      tagline: tagline ?? this.tagline,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      ntnOrTaxNumber: ntnOrTaxNumber ?? this.ntnOrTaxNumber,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      invoiceFooterNote: invoiceFooterNote ?? this.invoiceFooterNote,
      logoPath: logoPath ?? this.logoPath,
      enableTax: enableTax ?? this.enableTax,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
