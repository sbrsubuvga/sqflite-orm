import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;
import 'package:sqflite_common/sqlite_api.dart' show DatabaseFactory;

bool _ffiInitialized = false;

/// Get database factory for desktop platforms (Windows/Linux/macOS)
DatabaseFactory getDatabaseFactory() {
  if (!_ffiInitialized) {
    ffi.sqfliteFfiInit();
    _ffiInitialized = true;
  }
  return ffi.databaseFactoryFfiNoIsolate;
}

