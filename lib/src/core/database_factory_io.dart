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
/// - **Mobile (Android/iOS) in Flutter apps**:
///   - Prefers `sqflite` if available (native plugin, better performance)
///   - Falls back to `sqflite_common_ffi` if `sqflite` not available (FFI works on mobile too)
/// - **Mobile (Android/iOS) in pure Dart**: Always uses `sqflite_common_ffi` (sqflite is Flutter-only)
///
/// **Important Notes:**
/// - `sqflite_common_ffi` works on ALL platforms including Android/iOS (uses FFI)
/// - Pure Dart packages can NEVER use `sqflite` (it requires Flutter SDK)
/// - Flutter apps can use either `sqflite` (recommended for mobile) or `sqflite_common_ffi` (fallback)
DatabaseFactory getDatabaseFactory() {
  // For desktop platforms, always use FFI (works in both Flutter and pure Dart)
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    return desktop_factory.getDatabaseFactory();
  }

  // For mobile platforms:
  // - In Flutter apps: try to use sqflite (if user added it), fallback to sqflite_common_ffi
  // - In pure Dart: always use sqflite_common_ffi (sqflite is not available)
  if (Platform.isAndroid || Platform.isIOS) {
    // Check if we're in Flutter (dart.library.ui available)
    // If not, we're in pure Dart and must use sqflite_common_ffi
    try {
      return mobile_factory.getDatabaseFactory();
    } catch (e) {
      // Fallback to desktop factory (sqflite_common_ffi) when:
      // - Pure Dart environment (sqflite not available)
      // - Flutter app but sqflite not in user's dependencies
      return desktop_factory.getDatabaseFactory();
    }
  }

  // Fallback to desktop factory for unknown platforms
  return desktop_factory.getDatabaseFactory();
}
