// lib/core/models/order_item.dart

/// A line item on an [Order]. `name` and `price` are a snapshot taken from
/// the [MenuItem] at the moment it was added — later edits to the menu must
/// never retroactively change an already-built order or invoice.
class OrderItem {
  final String menuItemId;
  final String name;
  final double price;

  /// In units of the menu item's `quantityStep` at order time (e.g. 0.5,
  /// 1, 1.5, 2 for a Karahi with quantityStep 0.5). Kept as `double` rather
  /// than `int` for this reason — not all items are wholeunit-orderable.
  final double quantity;

  const OrderItem({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
  });

  double get subtotal => price * quantity;

  OrderItem copyWith({
    String? menuItemId,
    String? name,
    double? price,
    double? quantity,
  }) {
    return OrderItem(
      menuItemId: menuItemId ?? this.menuItemId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
    );
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      menuItemId: map['menuItemId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'menuItemId': menuItemId,
      'name': name,
      'price': price,
      'quantity': quantity,
    };
  }
}
