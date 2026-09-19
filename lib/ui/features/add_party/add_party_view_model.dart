// lib\ui\add_party\add_party_view_model.dart
// lib/features/party/logic/add_party_view_model.dart

import 'package:flutter/material.dart';
import 'package:katha_management/core/models/party_model.dart';
import 'package:katha_management/features/party/data/repositories/party_repository.dart';
import 'package:katha_management/features/party/data/repositories/sqflite_party_repository.dart';

/// Drives the Add Party form.
///
/// Depends on [PartyRepository] (the interface), not on
/// [SqflitePartyRepository] directly — a mock repository can be
/// passed in for tests, and a Firestore/sync repository can replace
/// it later without touching this class.
class AddPartyViewModel extends ChangeNotifier {
  AddPartyViewModel({PartyRepository? repository})
    : _repository = repository ?? SqflitePartyRepository();

  final PartyRepository _repository;

  String name = '';
  String phone = '';
  String address = '';
  double openingBalance = 0;
  PartyTag? tag;
  String? note;

  bool isSaving = false;
  bool isCheckingDuplicate = false;
  String? errorMessage;

  /// Non-blocking — set when a party with the same name already
  /// exists, so the form can warn without preventing the save (two
  /// different shops can legitimately share a name).
  String? duplicateWarning;

  bool get canSave => name.trim().isNotEmpty;

  void setName(String value) {
    name = value;
    duplicateWarning = null;
    notifyListeners();
    _checkDuplicate(value);
  }

  void setPhone(String value) {
    phone = value;
    notifyListeners();
  }

  void setAddress(String value) {
    address = value;
    notifyListeners();
  }

  void setOpeningBalance(double value) {
    openingBalance = value;
    notifyListeners();
  }

  void setTag(PartyTag? value) {
    tag = value;
    notifyListeners();
  }

  void setNote(String value) {
    note = value;
    notifyListeners();
  }

  Future<void> _checkDuplicate(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;

    isCheckingDuplicate = true;
    notifyListeners();

    try {
      final matches = await _repository.searchParties(trimmed);
      final exactMatch = matches.any(
        (party) => party.name.trim().toLowerCase() == trimmed.toLowerCase(),
      );

      // The name may have changed again while this lookup was in
      // flight — only apply the result if it's still relevant.
      if (name.trim() == trimmed) {
        duplicateWarning = exactMatch
            ? 'A party named "$trimmed" already exists.'
            : null;
      }
    } catch (_) {
      // A failed duplicate check shouldn't block data entry.
    } finally {
      isCheckingDuplicate = false;
      notifyListeners();
    }
  }

  Future<bool> saveParty() async {
    if (!canSave) {
      errorMessage = 'Party name is required.';
      notifyListeners();
      return false;
    }

    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      final party = PartyModel(
        name: name.trim(),
        phone: phone.trim().isEmpty ? null : phone.trim(),
        address: address.trim().isEmpty ? null : address.trim(),
        openingBalance: openingBalance,
        tag: tag,
        note: note,
      );

      await _repository.createParty(party);
      _resetForm();
      return true;
    } catch (e) {
      errorMessage = 'Failed to save party: $e';
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  void _resetForm() {
    name = '';
    phone = '';
    address = '';
    openingBalance = 0;
    tag = null;
    note = null;
    duplicateWarning = null;
  }
}
