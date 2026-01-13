import 'package:sqflite_common/sqlite_api.dart' show DatabaseFactory;

// Conditional import: use sqflite when available (Flutter mobile apps only)
// This file is ONLY used when Flutter is available (dart.library.ui)
// Pure Dart packages will never reach this code path
// If sqflite is not available in Flutter app, use the stub which will throw
import 'database_factory_mobile_sqflite_stub.dart'
    if (dart.library.ui) 'database_factory_mobile_sqflite.dart' as sqflite_factory;

/// Get database factory for mobile platforms (Android/iOS)
///
/// **Important Notes:**
/// - This function is ONLY called in Flutter apps (dart.library.ui available)
/// - Pure Dart packages will NEVER call this - they use sqflite_common_ffi for all platforms
/// - This requires `sqflite` to be added to your Flutter app's `pubspec.yaml` dependencies
/// - The package does not include `sqflite` as a dependency to allow `dart pub` analysis
///   and to work with pure Dart packages
///
/// Add to your Flutter app's `pubspec.yaml`:
/// ```yaml
/// dependencies:
///   sqflite: ^2.4.2
/// ```
///
/// If sqflite is not available, this will throw and the caller will fall back to `sqflite_common_ffi`
/// (which works on all platforms including Android/iOS via FFI).
DatabaseFactory getDatabaseFactory() {
  // Use conditional import to get sqflite factory when available
  // This works because:
  // - In Flutter apps with sqflite: uses sqflite's databaseFactory
  // - In Flutter apps without sqflite: uses stub which throws (caller falls back to sqflite_common_ffi)
  // - Pure Dart packages: never reach this code path (use sqflite_common_ffi directly)
  return sqflite_factory.getDatabaseFactory();
}
