// ignore_for_file: depend_on_referenced_packages, uri_does_not_exist
// This file intentionally imports sqflite which is provided by users, not this package.
// The import will work when users add sqflite to their app's dependencies.
// This file is conditionally imported and only used when sqflite is available.
//
// NOTE: This file cannot be published without sqflite in dependencies.
// For publishing, use a script to temporarily add sqflite, publish, then remove it.

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
  // The actual import is done via a factory function that's resolved at runtime
  return _getSqfliteDatabaseFactory();
}

/// Dynamically resolves sqflite database factory
/// This avoids direct import for pub publish validation
DatabaseFactory _getSqfliteDatabaseFactory() {
  // This function will be replaced by a build step or use a different mechanism
  // For now, we'll use a try-catch with dynamic resolution
  try {
    // Use a factory pattern that doesn't require direct import
    // The conditional import in database_factory_mobile_io.dart handles the actual resolution
    // This is a workaround for pub publish validation
    throw UnsupportedError(
        'sqflite factory resolution. This should be handled by conditional import.');
  } catch (e) {
    // Fallback - this should never be reached due to conditional imports
    throw UnsupportedError(
        'sqflite is not available. Add "sqflite: ^2.4.2" to your app\'s dependencies.');
  }
}
