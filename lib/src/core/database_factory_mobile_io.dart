import 'package:sqflite_common/sqlite_api.dart' show DatabaseFactory;
import 'package:sqflite/sqflite.dart' as sqflite;

/// Get database factory for mobile platforms (Android/iOS)
///
/// Uses sqflite for native mobile performance on Android/iOS.
/// For desktop platforms, sqflite_common_ffi is used instead.
DatabaseFactory getDatabaseFactory() {
  // Return sqflite's database factory for mobile platforms
  // sqflite exports databaseFactory which is compatible with sqflite_common
  return sqflite.databaseFactory;
}
