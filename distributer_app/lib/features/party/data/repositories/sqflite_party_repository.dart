// lib/features/party/data/repositories/sqflite_party_repository.dart

import 'package:katha_management/core/models/party_model.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import 'party_repository.dart';

/// sqflite-backed implementation of [PartyRepository].
///
/// Unlike Sale/Order/Payment, a party has no child rows to manage —
/// no transaction wrapping is needed for a plain single-table CRUD.
class SqflitePartyRepository implements PartyRepository {
  SqflitePartyRepository({AppDatabase? database})
    : _appDatabase = database ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

  static const String _table = 'parties';

  @override
  Future<void> createParty(PartyModel party) async {
    final db = await _appDatabase.database;
    await db.insert(
      _table,
      party.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<PartyModel>> getAllParties() async {
    final db = await _appDatabase.database;
    final rows = await db.query(_table, orderBy: 'name COLLATE NOCASE ASC');
    return rows.map(PartyModel.fromMap).toList();
  }

  @override
  Future<PartyModel?> getPartyById(String id) async {
    final db = await _appDatabase.database;
    final rows = await db.query(_table, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return PartyModel.fromMap(rows.first);
  }

  @override
  Future<List<PartyModel>> searchParties(String query) async {
    final db = await _appDatabase.database;
    final likeQuery = '%$query%';

    final rows = await db.query(
      _table,
      where: 'name LIKE ? COLLATE NOCASE OR phone LIKE ?',
      whereArgs: [likeQuery, likeQuery],
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(PartyModel.fromMap).toList();
  }

  @override
  Future<void> updateParty(PartyModel party) async {
    final db = await _appDatabase.database;
    await db.update(
      _table,
      party.toMap(),
      where: 'id = ?',
      whereArgs: [party.id],
    );
  }

  @override
  Future<void> deleteParty(String id) async {
    final db = await _appDatabase.database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}
