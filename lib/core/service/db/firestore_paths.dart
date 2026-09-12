// lib/core/service/db/firestore_paths.dart

/// Central place for Firestore collection names, so a rename only ever
/// happens in one file.
class FirestorePaths {
  FirestorePaths._();

  static const String tables = 'tables';
  static const String menu = 'menu';
  static const String categories = 'categories';
  static const String orders = 'orders';
  static const String invoices = 'invoices';
}
