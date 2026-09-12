import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:katha_management/core/models/hotel.dart';
import 'package:katha_management/core/models/hotelTable.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // TABLES

  Stream<List<HotelTable>> streamTables() {
    return _firestore
        .collection('tables')
        .orderBy('tableNumber')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => HotelTable.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> updateTableStatus(String tableId, TableStatus status) async {
    await _firestore.collection('tables').doc(tableId).update({
      'status': status.name,
    });
  }

  // HOTEL SETTINGS

  Future<Hotel?> getHotelSettings() async {
    final document = await _firestore.collection('hotel').doc('settings').get();

    if (!document.exists || document.data() == null) {
      return null;
    }

    return Hotel.fromMap(document.id, document.data()!);
  }

  Future<void> saveHotelSettings(Hotel hotel) async {
    await _firestore
        .collection('hotel')
        .doc('settings')
        .set(hotel.toMap(), SetOptions(merge: true));
  }
}
