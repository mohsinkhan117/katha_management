// test/catalog_selection_and_mutable_price_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:katha_management/core/models/party_model.dart';
import 'package:katha_management/core/models/product/product_model.dart';
import 'package:katha_management/core/models/product/product_size_model.dart';
import 'package:katha_management/features/party/data/repositories/party_repository.dart';
import 'package:katha_management/features/product/data/repositories/product_repository.dart';
import 'package:katha_management/ui/features/new_sale/new_sale_view_model.dart';
import 'package:katha_management/ui/features/new_order/new_order_view_model.dart';

// In-memory mock repositories for fast unit testing
class MockProductRepository implements ProductRepository {
  final List<ProductModel> products;
  MockProductRepository(this.products);

  @override
  Future<void> createProduct(ProductModel product) async =>
      products.add(product);
  @override
  Future<List<ProductModel>> getAllProducts({
    bool includeInactive = false,
  }) async => products;
  @override
  Future<ProductModel?> getProductById(String id) async =>
      products.where((p) => p.id == id).firstOrNull;
  @override
  Future<List<ProductModel>> searchProducts(
    String query, {
    bool includeInactive = false,
  }) async => products;
  @override
  Future<void> setActive(String id, bool isActive) async {}
  @override
  Future<void> updateProduct(ProductModel product) async {}
}

class MockPartyRepository implements PartyRepository {
  final List<PartyModel> parties;
  MockPartyRepository(this.parties);

  @override
  Future<void> createParty(PartyModel party) async => parties.add(party);
  @override
  Future<List<PartyModel>> getAllParties() async => parties;
  @override
  Future<PartyModel?> getPartyById(String id) async =>
      parties.where((p) => p.id == id).firstOrNull;
  @override
  Future<List<PartyModel>> searchParties(String query) async => parties;
  @override
  Future<void> updateParty(PartyModel party) async {}
  @override
  Future<void> deleteParty(String id) async =>
      parties.removeWhere((p) => p.id == id);
}

void main() {
  late ProductModel oilProduct;
  late PartyModel sampleParty;

  setUp(() {
    oilProduct = ProductModel(
      id: 'prod_oil',
      name: 'Cooking Oil',
      retailPrice: 550,
      finalPrice: 550,
      sizes: [
        ProductSizeModel.calculate(
          id: 'size_1l',
          productId: 'prod_oil',
          label: '1 Liter',
          price: 550,
          discountPercentage: 10, // finalPrice = 495
        ),
        ProductSizeModel.calculate(
          id: 'size_5l',
          productId: 'prod_oil',
          label: '5 Liter',
          price: 2500,
          discountPercentage: 5, // finalPrice = 2375
        ),
      ],
    );

    sampleParty = PartyModel(
      id: 'party_1',
      name: 'Ali Khan',
      phone: '03001234567',
    );
  });

  group('NewSaleViewModel Catalog Selection & Mutable Price', () {
    test(
      'Defaults to catalog finalPrice, allows price mutation for special customers',
      () async {
        final productRepo = MockProductRepository([oilProduct]);
        final partyRepo = MockPartyRepository([sampleParty]);

        final vm = NewSaleViewModel(
          initialPartyId: 'party_1',
          partyRepository: partyRepo,
          productRepository: productRepo,
        );

        // Wait for async init
        await Future.delayed(const Duration(milliseconds: 10));

        expect(vm.selectedPartyId, 'party_1');
        expect(vm.partyName, 'Ali Khan');

        final size1L = oilProduct.sizes.firstWhere((s) => s.id == 'size_1l');
        final sizeKey = NewSaleViewModel.getItemKey(oilProduct.id, size1L.id);

        // 1. Toggle select 1 Liter variant
        vm.toggleProductVariant(oilProduct, size1L, true);
        expect(vm.isVariantSelected(oilProduct.id, size1L.id), isTrue);

        final state = vm.getVariantState(oilProduct.id, size1L.id)!;
        expect(state.defaultPrice, 495);
        expect(state.unitPrice, 495); // Starts at default
        expect(state.quantity, 1.0);
        expect(vm.totalAmount, 495);

        // 2. Mutate price (e.g. special discount price of 450)
        vm.updateVariantPrice(sizeKey, 450);
        expect(state.unitPrice, 450);
        expect(vm.totalAmount, 450);

        // 3. Increase quantity to 3
        vm.updateVariantQuantity(sizeKey, 3);
        expect(vm.totalAmount, 1350); // 3 * 450
      },
    );
  });

  group('NewOrderViewModel Catalog Selection & Mutable Price', () {
    test(
      'Allows selecting multiple sizes of a product with varying custom prices',
      () async {
        final productRepo = MockProductRepository([oilProduct]);
        final partyRepo = MockPartyRepository([sampleParty]);

        final vm = NewOrderViewModel(
          initialPartyId: 'party_1',
          partyRepository: partyRepo,
          productRepository: productRepo,
        );

        await Future.delayed(const Duration(milliseconds: 10));

        final size1L = oilProduct.sizes[0];
        final size5L = oilProduct.sizes[1];

        // Select both 1L and 5L variants
        vm.toggleProductVariant(oilProduct, size1L, true);
        vm.toggleProductVariant(oilProduct, size5L, true);

        final key1L = NewOrderViewModel.getItemKey(oilProduct.id, size1L.id);
        final key5L = NewOrderViewModel.getItemKey(oilProduct.id, size5L.id);

        // Custom price on 5L
        vm.updateVariantPrice(key5L, 2200); // reduced from 2375
        vm.updateVariantQuantity(key1L, 2); // 2 x 495 = 990

        // Total = (2 * 495) + (1 * 2200) = 990 + 2200 = 3190
        expect(vm.totalAmount, 3190);
        expect(vm.items.length, 2);
        expect(vm.items[0].productName, 'Cooking Oil (1 Liter)');
        expect(vm.items[1].productName, 'Cooking Oil (5 Liter)');
      },
    );
  });
}
