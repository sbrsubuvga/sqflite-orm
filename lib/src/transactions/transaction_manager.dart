import 'package:sqflite_common/sqlite_api.dart'
    show Database, Transaction, Batch;

/// Manages database transactions and batch operations.
///
/// Provides static methods for executing operations within transactions
/// or as batch operations for better performance.
class TransactionManager {
  /// Execute a function within a transaction.
  ///
  /// If any operation in the transaction fails, all changes are rolled back.
  ///
  /// Example:
  /// ```dart
  /// await TransactionManager.transaction(db, (txn) async {
  ///   await txn.execute('INSERT INTO users ...');
  ///   await txn.execute('INSERT INTO posts ...');
  /// });
  /// ```
  static Future<T> transaction<T>(
    Database db,
    Future<T> Function(Transaction txn) action,
  ) async {
    return await db.transaction(action);
  }

  /// Execute multiple operations in a batch.
  ///
  /// Batch operations are more efficient than individual operations
  /// when performing multiple inserts, updates, or deletes.
  ///
  /// Example:
  /// ```dart
  /// await TransactionManager.batch(db, (batch) {
  ///   batch.insert('users', {'name': 'John'});
  ///   batch.insert('users', {'name': 'Jane'});
  /// });
  /// ```
  static Future<void> batch(
    Database db,
    Future<void> Function(Batch batch) action,
  ) async {
    final batch = db.batch();
    await action(batch);
    await batch.commit(noResult: false);
  }
}
