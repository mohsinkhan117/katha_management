// lib/features/settings/data/repositories/sqflite_settings_repository.dart

import 'package:sqflite/sqflite.dart';
import 'package:katha_management/core/database/app_database.dart';
import 'package:katha_management/core/models/settings/hotel_profile_model.dart';
import 'settings_repository.dart';

class SqfliteSettingsRepository implements SettingsRepository {
  SqfliteSettingsRepository({AppDatabase? database})
    : _appDatabase = database ?? AppDatabase.instance;

  final AppDatabase _appDatabase;
  static const String _tableName = 'hotel_profile';

  @override
  Future<HotelProfileModel> getProfile() async {
    final db = await _appDatabase.database;
    final rows = await db.query(_tableName, limit: 1);

    if (rows.isEmpty) {
      return HotelProfileModel.defaultProfile();
    }

    return HotelProfileModel.fromMap(rows.first);
  }

  @override
  Future<void> saveProfile(HotelProfileModel profile) async {
    final db = await _appDatabase.database;
    await db.insert(
      _tableName,
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
