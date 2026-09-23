// test/settings_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:katha_management/core/models/settings/hotel_profile_model.dart';

void main() {
  group('HotelProfileModel Tests', () {
    test('Default profile contains expected initial values', () {
      final defaultProfile = HotelProfileModel.defaultProfile();

      expect(defaultProfile.id, 'default_profile');
      expect(defaultProfile.hotelName, 'My Business / Hotel');
      expect(defaultProfile.currencySymbol, 'Rs');
      expect(defaultProfile.enableTax, isFalse);
      expect(defaultProfile.taxPercentage, 0.0);
    });

    test('Serialization toMap and deserialization fromMap works cleanly', () {
      final profile = HotelProfileModel(
        id: 'default_profile',
        hotelName: 'Serena Grand Hotel',
        tagline: 'Luxury & Comfort',
        phone: '0300-1234567',
        email: 'info@serenagrand.com',
        address: 'Club Road, Islamabad',
        ntnOrTaxNumber: 'NTN-987654',
        currencySymbol: 'PKR',
        invoiceFooterNote: 'Thanks for staying with us!',
        enableTax: true,
        taxPercentage: 16.0,
      );

      final map = profile.toMap();
      expect(map['hotelName'], 'Serena Grand Hotel');
      expect(map['enableTax'], 1);
      expect(map['taxPercentage'], 16.0);

      final fromMap = HotelProfileModel.fromMap(map);
      expect(fromMap.hotelName, 'Serena Grand Hotel');
      expect(fromMap.tagline, 'Luxury & Comfort');
      expect(fromMap.phone, '0300-1234567');
      expect(fromMap.email, 'info@serenagrand.com');
      expect(fromMap.address, 'Club Road, Islamabad');
      expect(fromMap.ntnOrTaxNumber, 'NTN-987654');
      expect(fromMap.currencySymbol, 'PKR');
      expect(fromMap.invoiceFooterNote, 'Thanks for staying with us!');
      expect(fromMap.enableTax, isTrue);
      expect(fromMap.taxPercentage, 16.0);
    });

    test('copyWith properly updates specific properties', () {
      final profile = HotelProfileModel.defaultProfile();
      final updated = profile.copyWith(
        hotelName: 'New Restaurant',
        enableTax: true,
        taxPercentage: 5.0,
      );

      expect(updated.hotelName, 'New Restaurant');
      expect(updated.currencySymbol, 'Rs');
      expect(updated.enableTax, isTrue);
      expect(updated.taxPercentage, 5.0);
    });
  });
}
