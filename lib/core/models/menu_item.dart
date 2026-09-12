// lib/core/models/menu_item.dart

class MenuItem {
  final String id;
  final String name;
  final String category;
  final double price;
  final bool isAvailable;
  final String? description;

  /// The minimum unit by which this item's order quantity can move per
  /// tap of the increment/decrement control (e.g. Karahi: 0.5 for
  /// half/full portions, Ice Cream: 2 for pairs, Shawarma: 1 for whole
  /// pieces only). Must be > 0. Defaults to 1 (whole-unit ordering) for
  /// items that don't set it explicitly, including legacy records.
  final double quantityStep;

  const MenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.isAvailable,
    this.description,
    this.quantityStep = 1,
  });

  MenuItem copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    bool? isAvailable,
    String? description,
    double? quantityStep,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      isAvailable: isAvailable ?? this.isAvailable,
      description: description ?? this.description,
      quantityStep: quantityStep ?? this.quantityStep,
    );
  }

  factory MenuItem.fromMap(String id, Map<String, dynamic> map) {
    return MenuItem(
      id: id,
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      isAvailable: map['isAvailable'] as bool? ?? true,
      description: map['description'] as String?,
      // Older documents won't have this field yet — default to 1 so
      // existing items keep behaving as whole-unit orderable.
      quantityStep: (map['quantityStep'] as num?)?.toDouble() ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'price': price,
      'isAvailable': isAvailable,
      'description': description,
      'quantityStep': quantityStep,
    };
  }
}
