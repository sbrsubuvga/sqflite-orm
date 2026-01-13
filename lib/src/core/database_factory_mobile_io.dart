import 'package:sqflite_common/sqlite_api.dart' show DatabaseFactory;

// Always use the stub - sqflite is no longer supported
// This will throw and fall back to sqflite_common_ffi
import 'database_factory_mobile_sqflite_stub.dart' as sqflite_factory;

/// Get database factory for mobile platforms (Android/iOS)
///
/// **Important Notes:**
/// - This function is ONLY called in Flutter apps (dart.library.ui available)
/// - Pure Dart packages will NEVER call this - they use sqflite_common_ffi for all platforms
/// - This will always throw and fall back to `sqflite_common_ffi` (which works on all platforms including Android/iOS via FFI)
DatabaseFactory getDatabaseFactory() {
  // Always use stub which throws - caller will fall back to sqflite_common_ffi
  // sqflite is no longer supported in this package
  return sqflite_factory.getDatabaseFactory();
}
