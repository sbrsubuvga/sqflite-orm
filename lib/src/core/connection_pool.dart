import 'package:sqflite_common_ffi/sqflite_ffi.dart' show Database;

/// Manages database connections
class ConnectionPool {
  static final ConnectionPool _instance = ConnectionPool._internal();
  factory ConnectionPool() => _instance;
  ConnectionPool._internal();

  Database? _database;
  String? _path;

  /// Get or create database connection
  Future<Database> getDatabase(String path, Future<Database> Function() createFn) async {
    if (_database != null && _path == path && await _database!.isOpen) {
      return _database!;
    }

    _path = path;
    _database = await createFn();
    return _database!;
  }

  /// Close the database connection
  Future<void> close() async {
    if (_database != null && await _database!.isOpen) {
      await _database!.close();
      _database = null;
      _path = null;
    }
  }

  /// Check if database is open
  Future<bool> isOpen() async {
    return _database != null && await _database!.isOpen;
  }
}

