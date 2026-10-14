// lib/ui/settings_view/settings_view_model.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:katha_management/core/models/settings/hotel_profile_model.dart';
import 'package:katha_management/features/settings/data/repositories/settings_repository.dart';
import 'package:katha_management/features/settings/data/repositories/sqflite_settings_repository.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({SettingsRepository? repository})
    : _repository = repository ?? SqfliteSettingsRepository() {
    loadProfile();
  }

  final SettingsRepository _repository;
  final ImagePicker _picker = ImagePicker();

  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;
  String? successMessage;

  String hotelName = '';
  String tagline = '';
  String phone = '';
  String email = '';
  String address = '';
  String ntnOrTaxNumber = '';
  String currencySymbol = 'Rs';
  String invoiceFooterNote = '';
  String? logoPath;
  bool enableTax = false;
  double taxPercentage = 0.0;

  Future<void> loadProfile() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final profile = await _repository.getProfile();
      hotelName = profile.hotelName;
      tagline = profile.tagline ?? '';
      phone = profile.phone ?? '';
      email = profile.email ?? '';
      address = profile.address ?? '';
      ntnOrTaxNumber = profile.ntnOrTaxNumber ?? '';
      currencySymbol = profile.currencySymbol;
      invoiceFooterNote = profile.invoiceFooterNote ?? '';
      logoPath = profile.logoPath;
      enableTax = profile.enableTax;
      taxPercentage = profile.taxPercentage;
    } catch (e) {
      errorMessage = 'Failed to load settings: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setHotelName(String value) {
    hotelName = value;
    notifyListeners();
  }

  void setTagline(String value) {
    tagline = value;
    notifyListeners();
  }

  void setPhone(String value) {
    phone = value;
    notifyListeners();
  }

  void setEmail(String value) {
    email = value;
    notifyListeners();
  }

  void setAddress(String value) {
    address = value;
    notifyListeners();
  }

  void setNtnOrTaxNumber(String value) {
    ntnOrTaxNumber = value;
    notifyListeners();
  }

  void setCurrencySymbol(String value) {
    currencySymbol = value;
    notifyListeners();
  }

  void setInvoiceFooterNote(String value) {
    invoiceFooterNote = value;
    notifyListeners();
  }

  void setEnableTax(bool value) {
    enableTax = value;
    notifyListeners();
  }

  void setTaxPercentage(double value) {
    taxPercentage = value.clamp(0, 100);
    notifyListeners();
  }

  Future<void> pickLogo() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        logoPath = pickedFile.path;
        notifyListeners();
      }
    } catch (e) {
      errorMessage = 'Could not pick image: $e';
      notifyListeners();
    }
  }

  void removeLogo() {
    logoPath = null;
    notifyListeners();
  }

  Future<bool> saveSettings() async {
    if (hotelName.trim().isEmpty) {
      errorMessage = 'Business / Hotel name cannot be empty';
      notifyListeners();
      return false;
    }

    isSaving = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();

    try {
      final profile = HotelProfileModel(
        id: 'default_profile',
        hotelName: hotelName.trim(),
        tagline: tagline.trim().isEmpty ? null : tagline.trim(),
        phone: phone.trim().isEmpty ? null : phone.trim(),
        email: email.trim().isEmpty ? null : email.trim(),
        address: address.trim().isEmpty ? null : address.trim(),
        ntnOrTaxNumber: ntnOrTaxNumber.trim().isEmpty
            ? null
            : ntnOrTaxNumber.trim(),
        currencySymbol: currencySymbol.trim().isEmpty
            ? 'Rs'
            : currencySymbol.trim(),
        invoiceFooterNote: invoiceFooterNote.trim().isEmpty
            ? null
            : invoiceFooterNote.trim(),
        logoPath: logoPath,
        enableTax: enableTax,
        taxPercentage: enableTax ? taxPercentage : 0.0,
        updatedAt: DateTime.now(),
      );

      await _repository.saveProfile(profile);
      successMessage = 'Settings saved successfully!';
      return true;
    } catch (e) {
      errorMessage = 'Failed to save settings: $e';
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
