import 'package:sqflite_common/sqlite_api.dart' show DatabaseFactory;

/// Stub for desktop database factory
DatabaseFactory getDatabaseFactory() {
  throw UnsupportedError(
      'sqflite_common_ffi not available - desktop platform not supported');
}
