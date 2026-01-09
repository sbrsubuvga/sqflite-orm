import 'package:sqflite_common_ffi/sqflite_ffi.dart' show Database;
import 'package:sqflite_orm/src/models/model_registry.dart';

/// Validates database schema against model definitions
class SchemaValidator {
  /// Validate the database schema against registered models
  Future<void> validate(Database db, List<Type> models) async {
    for (final modelType in models) {
      final info = ModelRegistry().getInfo(modelType);
      if (info == null) {
        print('Warning: Model $modelType not registered in ModelRegistry');
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
          print(
            'Warning: Extra column found in database: '
            '${info.tableName}.$dbColumnName (not in model definition)',
          );
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
            print(
              'Warning: Type mismatch for ${info.tableName}.$columnName: '
              'DB has $dbType, model expects ${columnInfo.sqlType}',
            );
          }
        }
      }
    } catch (e) {
      if (e is SchemaValidationError) {
        rethrow;
      }
      // Table might not exist yet, which is OK during initial creation
      print('Schema validation note: ${info.tableName} - $e');
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

/// Exception thrown when schema validation fails
class SchemaValidationError implements Exception {
  final String message;
  SchemaValidationError(this.message);

  @override
  String toString() => 'SchemaValidationError: $message';
}
