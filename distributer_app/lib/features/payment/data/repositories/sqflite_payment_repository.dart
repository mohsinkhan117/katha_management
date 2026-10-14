// lib/features/payment/data/repositories/sqflite_payment_repository.dart

import 'package:katha_management/core/models/payment/payment_allocation_model.dart';
import 'package:katha_management/core/models/payment/payment_model.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import 'payment_repository.dart';

class SqflitePaymentRepository implements PaymentRepository {
  SqflitePaymentRepository({AppDatabase? appDatabase})
    : _appDatabase = appDatabase ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

  static const _paymentsTable = 'payments';
  static const _allocationsTable = 'payment_allocations';
  static const _salesTable = 'sales';

  Future<Database> get _db async => _appDatabase.database;

  @override
  Future<void> insertPayment(
    PaymentModel payment, {
    List<PaymentAllocationModel> allocations = const [],
  }) async {
    final db = await _db;

    await db.transaction((txn) async {
      await txn.insert(
        _paymentsTable,
        payment.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (allocations.isNotEmpty) {
        for (final allocation in allocations) {
          await _applyAllocation(txn, allocation);
        }
      } else {
        await _autoAllocateFifo(txn, payment);
      }
    });
  }

  @override
  Future<void> updatePayment(PaymentModel payment) async {
    final db = await _db;
    await db.update(
      _paymentsTable,
      payment.toMap(),
      where: 'id = ?',
      whereArgs: [payment.id],
    );
  }

  @override
  Future<void> deletePayment(String paymentId) async {
    final db = await _db;
    // payment_allocations cascades via FK; sales paidAmount is left as
    // the caller's concern if a reversal is needed — deleting a
    // payment outright is expected to be rare and audited elsewhere.
    await db.delete(_paymentsTable, where: 'id = ?', whereArgs: [paymentId]);
  }

  @override
  Future<PaymentModel?> getPaymentById(String paymentId) async {
    final db = await _db;
    final rows = await db.query(
      _paymentsTable,
      where: 'id = ?',
      whereArgs: [paymentId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return PaymentModel.fromMap(rows.first);
  }

  @override
  Future<List<PaymentModel>> getAllPayments() async {
    final db = await _db;
    final rows = await db.query(_paymentsTable, orderBy: 'paymentDate DESC');
    return rows.map(PaymentModel.fromMap).toList();
  }

  @override
  Future<List<PaymentModel>> getPaymentsByParty(String partyId) async {
    final db = await _db;
    final rows = await db.query(
      _paymentsTable,
      where: 'partyId = ?',
      whereArgs: [partyId],
      orderBy: 'paymentDate DESC',
    );
    return rows.map(PaymentModel.fromMap).toList();
  }

  @override
  Future<List<PaymentAllocationModel>> getAllocationsForPayment(
    String paymentId,
  ) async {
    final db = await _db;
    final rows = await db.query(
      _allocationsTable,
      where: 'paymentId = ?',
      whereArgs: [paymentId],
    );
    return rows.map(PaymentAllocationModel.fromMap).toList();
  }

  @override
  Future<List<PaymentAllocationModel>> getAllocationsForSale(
    String saleId,
  ) async {
    final db = await _db;
    final rows = await db.query(
      _allocationsTable,
      where: 'saleId = ?',
      whereArgs: [saleId],
    );
    return rows.map(PaymentAllocationModel.fromMap).toList();
  }

  @override
  Future<void> allocatePayment(
    String paymentId,
    List<PaymentAllocationModel> allocations,
  ) async {
    final db = await _db;
    await db.transaction((txn) async {
      for (final allocation in allocations) {
        await _applyAllocation(txn, allocation);
      }
    });
  }

  @override
  Future<double> getUnallocatedAmount(String paymentId) async {
    final db = await _db;

    final paymentRows = await db.query(
      _paymentsTable,
      columns: ['amount'],
      where: 'id = ?',
      whereArgs: [paymentId],
      limit: 1,
    );
    if (paymentRows.isEmpty) return 0;
    final amount = (paymentRows.first['amount'] as num).toDouble();

    final allocatedResult = await db.rawQuery(
      'SELECT COALESCE(SUM(amountApplied), 0) as allocated '
      'FROM $_allocationsTable WHERE paymentId = ?',
      [paymentId],
    );
    final allocated = (allocatedResult.first['allocated'] as num).toDouble();

    return amount - allocated;
  }

  /// Automatically applies a payment against the party's oldest unpaid sales
  /// in FIFO (First-In, First-Out) order. Any remaining balance stays unallocated
  /// as an advance on account.
  Future<void> _autoAllocateFifo(
    DatabaseExecutor txn,
    PaymentModel payment,
  ) async {
    String whereClause;
    List<dynamic> whereArgs;

    if (payment.partyId != null && payment.partyId!.isNotEmpty) {
      whereClause = 'partyId = ? AND paidAmount < totalAmount';
      whereArgs = [payment.partyId];
    } else {
      whereClause = 'LOWER(partyName) = ? AND paidAmount < totalAmount';
      whereArgs = [payment.partyName.trim().toLowerCase()];
    }

    final unpaidSales = await txn.query(
      _salesTable,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'saleDate ASC, createdAt ASC',
    );

    double remainingToAllocate = payment.amount;

    for (final saleRow in unpaidSales) {
      if (remainingToAllocate <= 0) break;

      final saleId = saleRow['id'] as String;
      final totalAmount = (saleRow['totalAmount'] as num).toDouble();
      final paidAmount = (saleRow['paidAmount'] as num).toDouble();
      final balanceDue = totalAmount - paidAmount;

      if (balanceDue <= 0) continue;

      final applyAmount = remainingToAllocate < balanceDue
          ? remainingToAllocate
          : balanceDue;

      final allocation = PaymentAllocationModel(
        paymentId: payment.id,
        saleId: saleId,
        amountApplied: applyAmount,
      );

      await _applyAllocation(txn, allocation);
      remainingToAllocate -= applyAmount;
    }
  }

  /// Inserts the allocation row and rolls the amount into the target
  /// sale's `paidAmount`, bumping `status` to `paid` or `partial`.
  Future<void> _applyAllocation(
    DatabaseExecutor txn,
    PaymentAllocationModel allocation,
  ) async {
    await txn.insert(
      _allocationsTable,
      allocation.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    final saleRows = await txn.query(
      _salesTable,
      columns: ['paidAmount', 'totalAmount'],
      where: 'id = ?',
      whereArgs: [allocation.saleId],
      limit: 1,
    );
    if (saleRows.isEmpty) return;

    final currentPaid = (saleRows.first['paidAmount'] as num).toDouble();
    final totalAmount = (saleRows.first['totalAmount'] as num).toDouble();
    final newPaid = currentPaid + allocation.amountApplied;
    final newStatus = newPaid >= totalAmount
        ? 'paid'
        : (newPaid > 0 ? 'partial' : 'pending');

    await txn.update(
      _salesTable,
      {
        'paidAmount': newPaid,
        'status': newStatus,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [allocation.saleId],
    );
  }
}
