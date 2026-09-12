// lib/core/service/db/menu_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:katha_management/core/models/menu_item.dart';
import 'package:katha_management/core/service/db/firestore_paths.dart';

/// CRUD + real-time stream for the `menu` collection.
class MenuService {
  MenuService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<List<MenuItem>> menuStream() {
    return _db
        .collection(FirestorePaths.menu)
        .orderBy('category')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => MenuItem.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<void> addMenuItem(MenuItem item) {
    return _db.collection(FirestorePaths.menu).add(item.toMap());
  }

  Future<void> updateMenuItem(MenuItem item) {
    return _db
        .collection(FirestorePaths.menu)
        .doc(item.id)
        .update(item.toMap());
  }

  Future<void> deleteMenuItem(String menuItemId) {
    return _db.collection(FirestorePaths.menu).doc(menuItemId).delete();
  }
}
