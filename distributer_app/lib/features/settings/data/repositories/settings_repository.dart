// lib/features/settings/data/repositories/settings_repository.dart

import 'package:katha_management/core/models/settings/hotel_profile_model.dart';

abstract class SettingsRepository {
  /// Fetches current hotel/business profile, or returns default if not set.
  Future<HotelProfileModel> getProfile();

  /// Saves or updates the hotel/business profile.
  Future<void> saveProfile(HotelProfileModel profile);
}
