// lib/features/party/data/repositories/party_repository.dart

import 'package:katha_management/core/models/party_model.dart';

/// Contract for anything that can persist/read parties.
///
/// The ViewModel depends only on this interface — never on
/// `SqflitePartyRepository` directly — so a Firestore/sync repository
/// can replace it in Phase 5 without any change above this layer.
abstract class PartyRepository {
  Future<void> createParty(PartyModel party);

  Future<List<PartyModel>> getAllParties();

  Future<PartyModel?> getPartyById(String id);

  /// Case-insensitive match against name or phone — used both by the
  /// party list's search box and by the Add Party form's duplicate
  /// check.
  Future<List<PartyModel>> searchParties(String query);

  Future<void> updateParty(PartyModel party);

  Future<void> deleteParty(String id);
}
