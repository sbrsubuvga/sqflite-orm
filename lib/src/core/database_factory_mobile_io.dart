// Import sqflite only when needed - this file is only imported on mobile platforms
// Note: sqflite requires Flutter SDK. For pure Dart usage, this file won't be imported.
// ignore: avoid_relative_lib_imports
import 'package:sqflite/sqflite.dart' show databaseFactory;
import 'package:sqflite_common/sqlite_api.dart' show DatabaseFactory;

/// Get database factory for mobile platforms (Android/iOS)
/// This function is only called when Platform.isAndroid || Platform.isIOS is true
/// and dart.library.ui is available (Flutter environment)
DatabaseFactory getDatabaseFactory() {
  // Return the sqflite databaseFactory for mobile platforms
  return databaseFactory;
}
