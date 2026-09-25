// lib/ui/customers/customers_view_model.dart

import 'package:flutter/material.dart';
import 'package:katha_management/core/models/party_model.dart';
import 'package:katha_management/features/party/data/repositories/party_repository.dart';
import 'package:katha_management/features/party/data/repositories/sqflite_party_repository.dart';

import '../../core/models/party_balance_summary.dart';
import '../../core/services/party_balance_service.dart';

/// Feeds the Customers screen: every party plus their live balance,
/// with a simple name/phone filter.
class CustomersViewModel extends ChangeNotifier {
  CustomersViewModel({
    PartyRepository? partyRepository,
    PartyBalanceService? balanceService,
  }) : _partyRepository = partyRepository ?? SqflitePartyRepository(),
       _balanceService = balanceService ?? PartyBalanceService() {
    loadParties();
  }

  final PartyRepository _partyRepository;
  final PartyBalanceService _balanceService;

  bool isLoading = false;
  String? errorMessage;

  List<PartyBalanceSummary> _allBalances = [];
  String _query = '';

  List<PartyBalanceSummary> get parties {
    if (_query.trim().isEmpty) return _allBalances;
    final normalized = _query.trim().toLowerCase();
    return _allBalances.where((summary) {
      final name = summary.partyName.toLowerCase();
      final phone = summary.partyPhone?.toLowerCase() ?? '';
      return name.contains(normalized) || phone.contains(normalized);
    }).toList();
  }

  double get totalReceivables => _allBalances
      .where((p) => p.balanceDue > 0)
      .fold(0.0, (sum, p) => sum + p.balanceDue);

  Future<void> loadParties() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final parties = await _partyRepository.getAllParties();
      _allBalances = await _balanceService.computeAll(parties);

      // Highest balance due first; parties with nothing pending sort
      // alphabetically after them.
      _allBalances.sort((a, b) {
        if (a.balanceDue != b.balanceDue) {
          return b.balanceDue.compareTo(a.balanceDue);
        }
        return a.partyName.toLowerCase().compareTo(b.partyName.toLowerCase());
      });
    } catch (e) {
      errorMessage = 'Failed to load customers: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String value) {
    _query = value;
    notifyListeners();
  }

  Future<PartyModel?> getParty(String id) => _partyRepository.getPartyById(id);

  Future<bool> deleteParty(String id) async {
    try {
      await _partyRepository.deleteParty(id);
      await loadParties();
      return true;
    } catch (e) {
      errorMessage = 'Failed to delete customer: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> refresh() => loadParties();
}
