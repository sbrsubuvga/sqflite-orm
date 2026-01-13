import 'package:sqflite_common/sqlite_api.dart' show DatabaseFactory;

/// Stub for mobile database factory
///
/// This stub is used when Flutter is not available (pure Dart environment).
/// In pure Dart packages, sqflite is not available (it requires Flutter SDK),
/// so this stub will throw and the caller will fall back to sqflite_common_ffi
/// which works on all platforms including mobile in pure Dart.
DatabaseFactory getDatabaseFactory() {
  throw UnsupportedError(
      'sqflite is not available in pure Dart packages (it requires Flutter SDK). '
      'Pure Dart packages should use sqflite_common_ffi for all platforms, '
      'which will be used automatically as a fallback.');
}
