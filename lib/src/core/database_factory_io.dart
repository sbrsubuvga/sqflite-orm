import 'dart:io' show Platform;
import 'package:sqflite_common/sqlite_api.dart' show DatabaseFactory;

// Conditional imports - only import mobile factory when Flutter (dart:ui) is available
// The mobile factory will only be used on Android/iOS platforms in Flutter apps
// In pure Dart scripts, it will use the stub and fallback to desktop factory (sqflite_common_ffi)
// Pure Dart packages can NEVER use sqflite (it requires Flutter), so they always use sqflite_common_ffi
import 'database_factory_mobile_stub.dart'
    if (dart.library.ui) 'database_factory_mobile_io.dart' as mobile_factory;
// Conditional import for desktop factory - only when FFI is available
import 'database_factory_desktop_stub.dart'
    if (dart.library.ffi) 'database_factory_desktop_ffi.dart'
    as desktop_factory;

/// Get the appropriate database factory based on platform
///
/// **Platform Selection:**
/// - **Desktop (Windows/Linux/macOS)**: Always uses `sqflite_common_ffi` (works in Flutter and pure Dart)
/// - **Mobile (Android/iOS)**: Always uses `sqflite_common_ffi` (FFI works on mobile too)
///
/// **Important Notes:**
/// - `sqflite_common_ffi` works on ALL platforms including Android/iOS (uses FFI)
/// - Pure Dart packages always use `sqflite_common_ffi` for all platforms
/// - Flutter apps always use `sqflite_common_ffi` (sqflite is no longer supported)
DatabaseFactory getDatabaseFactory() {
  // For desktop platforms, always use FFI (works in both Flutter and pure Dart)
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    return desktop_factory.getDatabaseFactory();
  }

  // For mobile platforms: always use sqflite_common_ffi (sqflite no longer supported)
  if (Platform.isAndroid || Platform.isIOS) {
    // Always fallback to desktop factory (sqflite_common_ffi)
    // sqflite is no longer supported in this package
    try {
      return mobile_factory.getDatabaseFactory();
    } catch (e) {
      // Fallback to desktop factory (sqflite_common_ffi)
      return desktop_factory.getDatabaseFactory();
    }
  }

  // Fallback to desktop factory for unknown platforms
  return desktop_factory.getDatabaseFactory();
}
