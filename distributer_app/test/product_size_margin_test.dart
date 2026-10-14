// test/product_size_margin_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:katha_management/core/models/product/product_size_model.dart';

void main() {
  group('ProductSizeModel Cost & Margin Calculations', () {
    test(
      'Calculates profit margin and percentage correctly when costPrice is provided',
      () {
        // Selling price 1000, 10% discount -> finalPrice = 900
        // Cost price 600 -> profitMargin = 300
        // Margin percentage = (300 / 900) * 100 = 33.333%
        final size = ProductSizeModel.calculate(
          productId: 'prod_1',
          label: '1 Liter',
          price: 1000,
          discountPercentage: 10,
          costPrice: 600,
        );

        expect(size.finalPrice, 900);
        expect(size.costPrice, 600);
        expect(size.profitMargin, 300);
        expect(size.profitMarginPercentage, closeTo(33.333, 0.01));
      },
    );

    test(
      'Profit margin is null when costPrice is omitted or null (optional)',
      () {
        final size = ProductSizeModel.calculate(
          productId: 'prod_1',
          label: '500 ml',
          price: 500,
          discountPercentage: 0,
        );

        expect(size.finalPrice, 500);
        expect(size.costPrice, isNull);
        expect(size.profitMargin, isNull);
        expect(size.profitMarginPercentage, isNull);
      },
    );

    test(
      'Correctly identifies negative margin (loss) when selling below cost',
      () {
        // Selling price 400, cost price 500 -> profitMargin = -100
        final size = ProductSizeModel.calculate(
          productId: 'prod_1',
          label: 'Sample Pack',
          price: 400,
          discountPercentage: 0,
          costPrice: 500,
        );

        expect(size.finalPrice, 400);
        expect(size.costPrice, 500);
        expect(size.profitMargin, -100);
        expect(size.profitMarginPercentage, closeTo(-25.0, 0.01));
      },
    );

    test(
      'Serializes toMap and deserializes fromMap with costPrice preserved',
      () {
        final size = ProductSizeModel.calculate(
          id: 'size_123',
          productId: 'prod_1',
          label: 'Family Pack',
          price: 2500,
          discountPercentage: 20,
          costPrice: 1500,
        );

        final map = size.toMap();
        expect(map['costPrice'], 1500);
        expect(map['finalPrice'], 2000);

        final fromMap = ProductSizeModel.fromMap(map);
        expect(fromMap.id, 'size_123');
        expect(fromMap.productId, 'prod_1');
        expect(fromMap.label, 'Family Pack');
        expect(fromMap.price, 2500);
        expect(fromMap.discountPercentage, 20);
        expect(fromMap.finalPrice, 2000);
        expect(fromMap.costPrice, 1500);
        expect(fromMap.profitMargin, 500);
      },
    );

    test('attachToProduct and copyWith preserve costPrice', () {
      final original = ProductSizeModel.calculate(
        productId: '',
        label: 'Large',
        price: 800,
        costPrice: 500,
      );

      final attached = original.attachToProduct('prod_99');
      expect(attached.productId, 'prod_99');
      expect(attached.costPrice, 500);

      final updated = attached.copyWith(price: 1000, costPrice: 600);
      expect(updated.price, 1000);
      expect(updated.costPrice, 600);
      expect(updated.profitMargin, 400);
    });
  });
}
