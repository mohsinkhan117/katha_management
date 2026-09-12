// lib/core/service/db/category_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:katha_management/core/models/menu_category.dart';
import 'package:katha_management/core/service/db/firestore_paths.dart';

/// CRUD + real-time stream for the `categories` collection.
class CategoryService {
  CategoryService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<List<MenuCategory>> categoriesStream() {
    return _db
        .collection(FirestorePaths.categories)
        .orderBy('name')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => MenuCategory.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Future<void> addCategory(String name) {
    return _db.collection(FirestorePaths.categories).add({'name': name});
  }

  Future<void> deleteCategory(String categoryId) {
    return _db.collection(FirestorePaths.categories).doc(categoryId).delete();
  }
}
