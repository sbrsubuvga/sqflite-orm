import 'package:sqflite_common/sqlite_api.dart' show DatabaseFactory;

/// Stub for sqflite database factory
///
/// This stub is used when sqflite is not available in Flutter apps.
/// The conditional import in database_factory_mobile_io.dart will use this stub when:
/// - sqflite package is not in the Flutter app's dependencies
///
/// **Note:** Pure Dart packages will never use this stub - they use sqflite_common_ffi
/// directly for all platforms since sqflite requires Flutter SDK.
DatabaseFactory getDatabaseFactory() {
  throw UnsupportedError('sqflite is not available in this Flutter app. '
      'Add "sqflite: ^2.4.2" to your Flutter app\'s dependencies for native mobile support. '
      'Alternatively, the package will automatically fall back to sqflite_common_ffi '
      '(which works on Android/iOS via FFI, though sqflite is recommended for mobile).');
}
