import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;
import 'package:sqflite_common/sqlite_api.dart' show DatabaseFactory;

bool _ffiInitialized = false;

/// Get database factory using sqflite_common_ffi (FFI-based SQLite)
///
/// **Works on ALL platforms:**
/// - Desktop (Windows/Linux/macOS): Primary use case
/// - Mobile (Android/iOS): Works as fallback when sqflite is not available
/// - Pure Dart: Works everywhere (no Flutter SDK required)
///
/// This uses FFI (Foreign Function Interface) to call SQLite directly,
/// which works on all platforms that support FFI.
DatabaseFactory getDatabaseFactory() {
  if (!_ffiInitialized) {
    ffi.sqfliteFfiInit();
    _ffiInitialized = true;
  }
  return ffi.databaseFactoryFfiNoIsolate;
}
