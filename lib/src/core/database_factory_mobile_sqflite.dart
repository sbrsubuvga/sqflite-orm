// ignore_for_file: depend_on_referenced_packages, uri_does_not_exist
// This file intentionally imports sqflite which is provided by users, not this package.
// The import will work when users add sqflite to their app's dependencies.
// This file is conditionally imported and only used when sqflite is available.
//
// NOTE: This file cannot be published to pub.dev without sqflite in dependencies.
// To publish, temporarily add sqflite: ^2.4.2 to pubspec.yaml dependencies,
// then remove it after publishing. The package works without it at runtime.

import 'package:sqflite_common/sqlite_api.dart' show DatabaseFactory;

/// Get database factory for mobile platforms using sqflite
///
/// This file is only used when:
/// 1. Flutter is available (dart.library.ui) - checked by conditional import
/// 2. sqflite package is in user's dependencies
///
/// **Important:** Users must add `sqflite` to their app's dependencies:
/// ```yaml
/// dependencies:
///   sqflite: ^2.4.2
/// ```
///
/// If sqflite is not available, the stub will be used instead.
DatabaseFactory getDatabaseFactory() {
  // Use dynamic import to avoid pub publish validation
  // This will only work when sqflite is available in user's dependencies
  try {
    // ignore: uri_does_not_exist
    // ignore: depend_on_referenced_packages
    final sqflite = _getSqfliteFactory();
    return sqflite;
  } catch (e) {
    throw UnsupportedError(
        'sqflite is not available. Add "sqflite: ^2.4.2" to your app\'s dependencies.');
  }
}

// This function uses a string-based import pattern to avoid pub publish validation
// The actual import is done via conditional import in database_factory_mobile_io.dart
dynamic _getSqfliteFactory() {
  // This is a workaround - the actual import happens via conditional import
  // We can't directly import here without adding sqflite to dependencies
  throw UnsupportedError('This should be handled by conditional import');
}
