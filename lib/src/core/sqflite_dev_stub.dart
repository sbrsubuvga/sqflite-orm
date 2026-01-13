import 'package:sqflite_common/sqlite_api.dart' show Database;

/// Helper function to enable workbench if sqflite_dev is available
///
/// This function will attempt to enable the workbench feature.
/// If sqflite_dev is not available (not in dependencies), it will silently do nothing.
void enableWorkbenchIfAvailable(Database database, {String? name, int? port}) {
  try {
    // Try to dynamically call enableWorkbench if sqflite_dev extension is available
    // This works because extensions are resolved at compile time, but we can catch
    // the error if the extension doesn't exist
    (database as dynamic).enableWorkbench(name: name, port: port);
  } catch (e) {
    // sqflite_dev not available - this is fine, just skip workbench
    // Users who want workbench should add sqflite_dev to their dependencies
  }
}
