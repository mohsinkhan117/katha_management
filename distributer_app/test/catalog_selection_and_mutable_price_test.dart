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
      'Defaults to first size available in dropdown, allows price mutation for special customers',
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

        // 1. Toggle select product -> automatically selects first size (1 Liter, Rs 495)
        vm.toggleProduct(oilProduct, true);
        expect(vm.isProductSelected(oilProduct.id), isTrue);

        final state = vm.getProductState(oilProduct.id)!;
        expect(state.sizeId, 'size_1l');
        expect(state.sizeLabel, '1 Liter');
        expect(state.defaultPrice, 495);
        expect(state.unitPrice, 495); // Starts at first size's default price
        expect(state.quantity, 1.0);
        expect(vm.totalAmount, 495);

        // 2. Mutate price (e.g. special discount price of 450)
        vm.updateProductPrice(oilProduct.id, 450);
        expect(state.unitPrice, 450);
        expect(vm.totalAmount, 450);

        // 3. Switch dropdown size to 5 Liter (Rs 2375)
        final size5L = oilProduct.sizes[1];
        vm.changeProductSize(oilProduct, size5L);

        final updatedState = vm.getProductState(oilProduct.id)!;
        expect(updatedState.sizeId, 'size_5l');
        expect(updatedState.sizeLabel, '5 Liter');
        expect(updatedState.unitPrice, 2375);
        expect(vm.totalAmount, 2375);

        // 4. Increase quantity to 2
        vm.updateProductQuantity(oilProduct.id, 2);
        expect(vm.totalAmount, 4750); // 2 * 2375
      },
    );
  });

  group('NewOrderViewModel Catalog Selection & Mutable Price', () {
    test(
      'Defaults to first size, changes size via dropdown, and supports mutable pricing',
      () async {
        final productRepo = MockProductRepository([oilProduct]);
        final partyRepo = MockPartyRepository([sampleParty]);

        final vm = NewOrderViewModel(
          initialPartyId: 'party_1',
          partyRepository: partyRepo,
          productRepository: productRepo,
        );

        await Future.delayed(const Duration(milliseconds: 10));

        // 1. Select product
        vm.toggleProduct(oilProduct, true);
        expect(vm.isProductSelected(oilProduct.id), isTrue);
        expect(vm.getProductState(oilProduct.id)!.sizeLabel, '1 Liter');

        // 2. Change size dropdown to 5L
        vm.changeProductSize(oilProduct, oilProduct.sizes[1]);
        expect(vm.getProductState(oilProduct.id)!.sizeLabel, '5 Liter');
        expect(vm.getProductState(oilProduct.id)!.unitPrice, 2375);

        // 3. Give custom price
        vm.updateProductPrice(oilProduct.id, 2200);
        expect(vm.totalAmount, 2200);
        expect(vm.items.first.productName, 'Cooking Oil (5 Liter)');
        expect(vm.items.first.unitPrice, 2200);
      },
    );
  });
}
