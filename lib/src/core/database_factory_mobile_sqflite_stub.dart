import 'package:sqflite_common/sqlite_api.dart' show DatabaseFactory;

/// Stub for sqflite database factory
///
/// This stub is always used - sqflite is no longer supported in this package.
/// This will throw and the caller will fall back to sqflite_common_ffi
/// (which works on all platforms including Android/iOS via FFI).
///
/// **Note:** Pure Dart packages will never use this stub - they use sqflite_common_ffi
/// directly for all platforms since sqflite requires Flutter SDK.
DatabaseFactory getDatabaseFactory() {
  throw UnsupportedError('sqflite is no longer supported in this package. '
      'The package will automatically fall back to sqflite_common_ffi '
      '(which works on Android/iOS via FFI).');
}
