import 'package:sqflite_common/sqlite_api.dart' show Database;

/// Manages database connection pooling.
///
/// Singleton that maintains a single database connection per path.
/// Reuses existing connections when possible to improve performance.
///
/// Example:
/// ```dart
/// final pool = ConnectionPool();
/// final db = await pool.getDatabase('app.db', () => openDatabase(...));
/// ```
class ConnectionPool {
  static final ConnectionPool _instance = ConnectionPool._internal();
  factory ConnectionPool() => _instance;
  ConnectionPool._internal();

  Database? _database;
  String? _path;

  /// Get or create database connection.
  ///
  /// Returns an existing connection if one exists for the given path
  /// and is still open. Otherwise, creates a new connection using [createFn].
  ///
  /// [path] is the database file path.
  /// [createFn] is a function that creates a new database connection.
  ///
  /// Returns the database connection (existing or newly created).
  Future<Database> getDatabase(
      String path, Future<Database> Function() createFn) async {
    if (_database != null && _path == path && _database!.isOpen) {
      return _database!;
    }

    _path = path;
    _database = await createFn();
    return _database!;
  }

  /// Close the database connection.
  ///
  /// Closes the current database connection if it exists and is open.
  /// Clears the internal connection and path references.
  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
      _path = null;
    }
  }

  /// Check if database connection is open.
  ///
  /// Returns `true` if a database connection exists and is open,
  /// `false` otherwise.
  Future<bool> isOpen() async {
    return _database != null && _database!.isOpen;
  }
}
