import 'package:sqflite_common/sqlite_api.dart' show DatabaseFactory;

/// Get database factory for mobile platforms (Android/iOS)
/// 
/// **Important:** This requires `sqflite` to be added to your `pubspec.yaml` dependencies.
/// The package does not include `sqflite` as a dependency to allow `dart pub` analysis.
/// 
/// Add to your `pubspec.yaml`:
/// ```yaml
/// dependencies:
///   sqflite: ^2.4.2
/// ```
/// 
/// If sqflite is not available, this will throw and the caller will fall back to desktop factory.
DatabaseFactory getDatabaseFactory() {
  // Note: We cannot import sqflite directly here because it requires Flutter SDK
  // and would cause pub.dev analysis to fail. Users must add sqflite to their dependencies.
  // When sqflite is available, users can create a custom factory or the conditional
  // import mechanism will handle it through the stub.
  throw UnsupportedError(
      'sqflite is required for mobile (Android/iOS) support. '
      'Add "sqflite: ^2.4.2" to your dependencies. '
      'The package will automatically use sqflite when available.');
}
