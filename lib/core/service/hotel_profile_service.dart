// lib/core/service/hotel_profile_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:katha_management/core/models/hotel_profile.dart';
import 'package:katha_management/core/utils/loggers_utils/logger_utils.dart';

/// Talks to Firestore for the hotel profile — a singleton document at
/// `profile/hotel` (one hotel, not a collection of records).
class HotelProfileService {
  HotelProfileService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const _tag = 'HotelProfileService';

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _firestore.collection('profile').doc('hotel');

  /// Real-time stream of the hotel profile document — updates live if it's
  /// edited from another device.
  Stream<HotelProfile> watchProfile() {
    return _doc.snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return HotelProfile.defaults;
      return HotelProfile.fromMap(data);
    });
  }

  /// One-off read, e.g. for an initial synchronous-feeling load.
  Future<HotelProfile> loadProfile() async {
    LoggerUtils.logInfo(_tag, 'Loading hotel profile from Firestore');
    try {
      final snapshot = await _doc.get();
      final data = snapshot.data();
      if (data == null) {
        LoggerUtils.logInfo(_tag, 'No profile document yet — using defaults');
        return HotelProfile.defaults;
      }
      LoggerUtils.logSuccess(_tag, 'Loaded hotel profile');
      return HotelProfile.fromMap(data);
    } catch (e, st) {
      LoggerUtils.logError(_tag, 'loadProfile() failed: $e');
      LoggerUtils.logDebug(_tag, 'loadProfile() stack trace', data: st);
      rethrow;
    }
  }

  /// Creates the document if it doesn't exist yet, otherwise updates it.
  Future<void> saveProfile(HotelProfile profile) async {
    LoggerUtils.logInfo(_tag, 'Saving hotel profile to Firestore');
    try {
      // merge: true so this also works the very first time, before the
      // document exists yet (acts as create-or-update).
      await _doc.set(profile.toMap(), SetOptions(merge: true));
      LoggerUtils.logSuccess(_tag, 'Hotel profile saved');
    } catch (e, st) {
      LoggerUtils.logError(_tag, 'saveProfile() failed: $e');
      LoggerUtils.logDebug(_tag, 'saveProfile() stack trace', data: st);
      rethrow;
    }
  }
}
