// ignore_for_file: depend_on_referenced_packages, uri_does_not_exist
// This file intentionally imports sqflite which is provided by users, not this package.
// The import will work when users add sqflite to their app's dependencies.
// This file is conditionally imported and only used when sqflite is available.

import 'package:sqflite_common/sqlite_api.dart' show DatabaseFactory;

// Import sqflite when available (only in Flutter apps with sqflite in user's dependencies)
// This import will work when users add sqflite to their app's pubspec.yaml
// even though sqflite is not in sqflite_orm's dependencies
import 'package:sqflite/sqflite.dart' as sqflite;

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
  // Return sqflite's database factory for mobile platforms
  // sqflite exports databaseFactory which is compatible with sqflite_common
  return sqflite.databaseFactory;
}
