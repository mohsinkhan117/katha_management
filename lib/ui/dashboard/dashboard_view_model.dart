// lib/features/home/logic/home_view_model.dart

import 'package:flutter/material.dart';

/// ────────────────────────────────────────────────────────────────
/// TEMPORARY DUMMY MODELS
/// These will be replaced by the real `Party` / `Transaction` models
/// once the Party & Ledger modules (Phase 1 & 4) are implemented.
/// Kept here for now so the Home screen can be built and visualized
/// before the sqflite repositories exist.
/// ────────────────────────────────────────────────────────────────

enum DummyTransactionType { sale, payment, returnItem }

class DummyPendingParty {
  final String name;
  final String phone;
  final double balanceDue;
  final int daysOverdue;

  const DummyPendingParty({
    required this.name,
    required this.phone,
    required this.balanceDue,
    required this.daysOverdue,
  });
}

class DummyTransaction {
  final String partyName;
  final DummyTransactionType type;
  final double amount;
  final DateTime date;

  const DummyTransaction({
    required this.partyName,
    required this.type,
    required this.amount,
    required this.date,
  });
}

/// ────────────────────────────────────────────────────────────────
/// HomeViewModel
/// Feeds the Dashboard (Home) screen. Currently backed by dummy data
/// so the UI can be designed before the sqflite repositories
/// (Phase 0–4) are wired in. Swap `loadDashboardData` to call the
/// real repositories once they exist — the UI won't need to change.
/// ────────────────────────────────────────────────────────────────
class DashboardViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String businessName = 'Ali Traders';

  double todaySales = 0;
  double todayCollection = 0;
  double totalReceivables = 0;
  int totalPartiesCount = 0;

  List<DummyPendingParty> topPendingParties = [];
  List<DummyTransaction> recentTransactions = [];

  DashboardViewModel() {
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    _isLoading = true;
    notifyListeners();

    // Simulate a DB call — replace with repository calls in Phase 4.
    await Future.delayed(const Duration(milliseconds: 600));

    todaySales = 48500;
    todayCollection = 32200;
    totalReceivables = 214750;
    totalPartiesCount = 37;

    topPendingParties = const [
      DummyPendingParty(
        name: 'Rehman General Store',
        phone: '0301-2345678',
        balanceDue: 32500,
        daysOverdue: 12,
      ),
      DummyPendingParty(
        name: 'Sitara Cosmetics',
        phone: '0345-9988776',
        balanceDue: 21800,
        daysOverdue: 5,
      ),
      DummyPendingParty(
        name: 'Al-Madina Super Mart',
        phone: '0333-1122334',
        balanceDue: 18000,
        daysOverdue: 21,
      ),
      DummyPendingParty(
        name: 'Noor Traders',
        phone: '0312-5566778',
        balanceDue: 9600,
        daysOverdue: 3,
      ),
    ];

    recentTransactions = [
      DummyTransaction(
        partyName: 'Rehman General Store',
        type: DummyTransactionType.sale,
        amount: 8500,
        date: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      DummyTransaction(
        partyName: 'Sitara Cosmetics',
        type: DummyTransactionType.payment,
        amount: 5000,
        date: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      DummyTransaction(
        partyName: 'Noor Traders',
        type: DummyTransactionType.sale,
        amount: 6200,
        date: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      DummyTransaction(
        partyName: 'Al-Madina Super Mart',
        type: DummyTransactionType.returnItem,
        amount: 1200,
        date: DateTime.now().subtract(const Duration(hours: 8)),
      ),
      DummyTransaction(
        partyName: 'Rehman General Store',
        type: DummyTransactionType.payment,
        amount: 15000,
        date: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() => loadDashboardData();
}
