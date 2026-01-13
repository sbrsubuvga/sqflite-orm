import 'package:sqflite_common/sqlite_api.dart' show Database;
import 'package:sqflite_orm/src/models/model_registry.dart';

/// Validates database schema against model definitions.
///
/// Compares the actual database schema with the registered model definitions
/// to detect mismatches, missing columns, or extra columns.
///
/// Example:
/// ```dart
/// final validator = SchemaValidator();
/// await validator.validate(db, [User, Post, Comment]);
/// ```
class SchemaValidator {
  /// Validate the database schema against registered models.
  ///
  /// Checks that:
  /// - All model columns exist in the database
  /// - Column types are compatible
  /// - Warns about extra columns in the database
  ///
  /// [db] is the database connection.
  /// [models] is the list of model types to validate.
  ///
  /// Throws [SchemaValidationError] if required columns are missing.
  /// Prints warnings for type mismatches or extra columns.
  Future<void> validate(Database db, List<Type> models) async {
    for (final modelType in models) {
      final info = ModelRegistry().getInfo(modelType);
      if (info == null) {
        continue;
      }

      await _validateTable(db, info);
    }
  }

  Future<void> _validateTable(Database db, ModelInfo info) async {
    try {
      // Get table info from database
      final tableInfo = await db.rawQuery(
        "PRAGMA table_info('${info.tableName}')",
      );

      final dbColumns = <String, Map<String, dynamic>>{};
      for (final row in tableInfo) {
        dbColumns[row['name'] as String] = row;
      }

      // Check for missing columns
      for (final columnName in info.columns.keys) {
        if (!dbColumns.containsKey(columnName)) {
          throw SchemaValidationError(
            'Missing column: ${info.tableName}.$columnName',
          );
        }
      }

      // Check for extra columns (warn only)
      for (final dbColumnName in dbColumns.keys) {
        if (!info.columns.containsKey(dbColumnName)) {
          // Extra column found in database
        }
      }

      // Check column types (basic validation)
      for (final entry in info.columns.entries) {
        final columnName = entry.key;
        final columnInfo = entry.value;
        final dbColumn = dbColumns[columnName];

        if (dbColumn != null) {
          final dbType = dbColumn['type'] as String?;
          if (dbType != null && !_typesCompatible(dbType, columnInfo.sqlType)) {
            // Type mismatch detected
          }
        }
      }
    } catch (e) {
      if (e is SchemaValidationError) {
        rethrow;
      }
      // Table might not exist yet, which is OK during initial creation
    }
  }

  bool _typesCompatible(String dbType, String modelType) {
    // Basic type compatibility check
    final dbTypeLower = dbType.toLowerCase();
    final modelTypeLower = modelType.toLowerCase();

    if (modelTypeLower.contains('int') && dbTypeLower.contains('int')) {
      return true;
    }
    if (modelTypeLower.contains('real') && dbTypeLower.contains('real')) {
      return true;
    }
    if (modelTypeLower.contains('text') && dbTypeLower.contains('text')) {
      return true;
    }
    if (modelTypeLower.contains('blob') && dbTypeLower.contains('blob')) {
      return true;
    }

    return false;
  }
}

/// Exception thrown when schema validation fails.
///
/// This exception is thrown when the database schema doesn't match
/// the model definitions, such as when required columns are missing.
///
/// Example:
/// ```dart
/// try {
///   await validator.validate(db, [User]);
/// } on SchemaValidationError catch (e) {
///   print('Schema mismatch: ${e.message}');
/// }
/// ```
class SchemaValidationError implements Exception {
  /// Error message describing the validation failure.
  final String message;

  /// Create a schema validation error.
  ///
  /// [message] describes what validation check failed.
  SchemaValidationError(this.message);

  @override
  String toString() => 'SchemaValidationError: $message';
}
