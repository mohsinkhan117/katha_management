// lib/features/sale/data/repositories/sale_repository.dart

import 'package:katha_management/core/models/sale_model.dart';

/// Contract for anything that can persist/read sales.
///
/// The ViewModel and View depend only on this interface — never on
/// `SqfliteSaleRepository` directly. That means Phase 5 (cloud) can
/// introduce a `FirestoreSaleRepository` or a `SyncSaleRepository`
/// (writes local + pushes to Firestore) without any change above
/// this layer.
abstract class SaleRepository {
  Future<void> createSale(SaleModel sale);

  Future<List<SaleModel>> getAllSales();

  Future<SaleModel?> getSaleById(String id);

  Future<List<SaleModel>> getSalesByParty(String partyId);

  Future<void> updateSale(SaleModel sale);

  Future<void> deleteSale(String id);
}
