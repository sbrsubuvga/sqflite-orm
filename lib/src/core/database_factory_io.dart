import 'dart:io' show Platform;
import 'package:sqflite_common/sqlite_api.dart' show DatabaseFactory;

// Conditional imports - only import mobile factory when Flutter (dart:ui) is available
// The mobile factory will only be used on Android/iOS platforms in Flutter apps
// In pure Dart scripts, it will use the stub and fallback to desktop factory
import 'database_factory_mobile_stub.dart'
    if (dart.library.ui) 'database_factory_mobile_io.dart' as mobile_factory;
// Conditional import for desktop factory - only when FFI is available
import 'database_factory_desktop_stub.dart'
    if (dart.library.ffi) 'database_factory_desktop_ffi.dart'
    as desktop_factory;

/// Get the appropriate database factory based on platform
/// - Mobile (Android/iOS): uses sqflite (Flutter plugin) - only in Flutter apps
/// - Desktop (Windows/Linux/macOS): uses sqflite_common_ffi (FFI)
DatabaseFactory getDatabaseFactory() {
  // For desktop platforms, always use FFI
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    return desktop_factory.getDatabaseFactory();
  }

  // For mobile platforms, try to use sqflite (Flutter plugin)
  // This will only work in Flutter apps, not in pure Dart
  if (Platform.isAndroid || Platform.isIOS) {
    try {
      return mobile_factory.getDatabaseFactory();
    } catch (e) {
      // Fallback to desktop if mobile not available (e.g., in pure Dart context)
      return desktop_factory.getDatabaseFactory();
    }
  }

  // Fallback to desktop factory for unknown platforms
  return desktop_factory.getDatabaseFactory();
}
