import 'package:sqflite_common/sqlite_api.dart'
    show Database, Transaction, Batch;

/// Manages database transactions
class TransactionManager {
  /// Execute a function within a transaction
  static Future<T> transaction<T>(
    Database db,
    Future<T> Function(Transaction txn) action,
  ) async {
    return await db.transaction(action);
  }

  /// Execute multiple operations in a batch
  static Future<void> batch(
    Database db,
    Future<void> Function(Batch batch) action,
  ) async {
    final batch = db.batch();
    await action(batch);
    await batch.commit(noResult: false);
  }
}
