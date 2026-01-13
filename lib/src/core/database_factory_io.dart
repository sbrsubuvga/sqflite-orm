import 'package:sqflite_common/sqlite_api.dart' show DatabaseFactory;

// Conditional import for desktop factory - only when FFI is available
import 'database_factory_desktop_stub.dart'
    if (dart.library.ffi) 'database_factory_desktop_ffi.dart'
    as desktop_factory;

/// Get the appropriate database factory based on platform
///
/// **Platform Selection:**
/// - **All platforms**: Uses `sqflite_common_ffi` (FFI-based, works everywhere)
/// - **Desktop (Windows/Linux/macOS)**: Uses `sqflite_common_ffi` (FFI-based)
/// - **Mobile (Android/iOS)**: Uses `sqflite_common_ffi` (FFI works on mobile too)
///
/// **Important Notes:**
/// - This is a pure Dart package - no Flutter SDK required
/// - `sqflite_common_ffi` works on ALL platforms including Android/iOS (uses FFI)
/// - Consistent behavior across all platforms
DatabaseFactory getDatabaseFactory() {
  // Always use sqflite_common_ffi for all platforms
  // This works everywhere via FFI (Foreign Function Interface)
  return desktop_factory.getDatabaseFactory();
}
