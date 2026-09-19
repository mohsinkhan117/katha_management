// lib/core/models/party_balance_summary.dart

import 'party_model.dart';

/// A party's outstanding balance, computed fresh from Sale/Payment
/// records — never stored, so it can't drift out of sync with the
/// transactions that produced it.
///
/// balanceDue = party.openingBalance
///            + sum(sale.totalAmount - sale.paidAmount) across sales
///            - sum(payment.amount) across payments
///
/// This treats a Payment as a simple collection against the party's
/// overall running balance rather than something tied to a specific
/// invoice — which matches how a paper khata book actually works.
class PartyBalanceSummary {
  final PartyModel party;
  final double balanceDue;
  final DateTime? oldestPendingSaleDate;

  const PartyBalanceSummary({
    required this.party,
    required this.balanceDue,
    this.oldestPendingSaleDate,
  });

  String get partyId => party.id;
  String get partyName => party.name;
  String? get partyPhone => party.phone;

  int? get daysSinceOldestDue {
    if (oldestPendingSaleDate == null) return null;
    return DateTime.now().difference(oldestPendingSaleDate!).inDays;
  }
}
