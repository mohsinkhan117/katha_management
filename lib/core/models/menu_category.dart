// lib/core/models/menu_category.dart

class MenuCategory {
  final String id;
  final String name;

  const MenuCategory({required this.id, required this.name});

  factory MenuCategory.fromMap(String id, Map<String, dynamic> map) {
    return MenuCategory(id: id, name: map['name'] as String? ?? '');
  }

  Map<String, dynamic> toMap() => {'name': name};
}
