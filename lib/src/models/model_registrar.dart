import 'package:sqflite_orm/src/models/base_model.dart';
import 'package:sqflite_orm/src/models/model_registry.dart';

/// Simplified model registration - manually register models
///
/// This is a manual registration system. For automatic registration
/// from annotations, use code generation (build_runner + source_gen).
class SimpleModelRegistrar {
  /// Register a model with manual specification
  static void register<T extends BaseModel>({
    required String tableName,
    required Map<String, ColumnInfo> columns,
    String? primaryKey,
    Map<String, ForeignKeyInfo> foreignKeys = const {},
    Map<String, RelationshipInfo> relationships = const {},
    BaseModel Function(Map<String, dynamic>)? factory,
    T Function()? instanceCreator,
  }) {
    final registry = ModelRegistry();

    // If factory is not provided but instanceCreator is, use fromMap
    BaseModel Function(Map<String, dynamic>)? finalFactory = factory;
    if (finalFactory == null && instanceCreator != null) {
      finalFactory = (Map<String, dynamic> map) {
        final instance = instanceCreator();
        return instance.fromMap(map);
      };
    }

    final modelInfo = ModelInfo(
      tableName: tableName,
      modelType: T,
      columns: columns,
      primaryKey: primaryKey,
      foreignKeys: foreignKeys,
      relationships: relationships,
      factory: finalFactory,
    );
    registry.register<T>(T, modelInfo);
  }

  /// Create a factory from a model's fromMap method
  ///
  /// This helper eliminates duplication by using the model's fromMap method
  /// instead of requiring a separate factory function.
  ///
  /// Example:
  /// ```dart
  /// SimpleModelRegistrar.register<User>(
  ///   tableName: 'users',
  ///   columns: {...},
  ///   instanceCreator: () => User(), // Used to call fromMap
  /// );
  /// ```
  static BaseModel Function(Map<String, dynamic>)
      factoryFromMap<T extends BaseModel>(
    T Function() instanceCreator,
  ) {
    return (Map<String, dynamic> map) {
      final instance = instanceCreator();
      return instance.fromMap(map);
    };
  }

  /// Simple registration - automatically infers columns from model
  ///
  /// This method extracts table name and infers column information from the model.
  /// Column types are inferred from toMap() values with sensible defaults.
  ///
  /// Example:
  /// ```dart
  /// SimpleModelRegistrar.registerModel<User>(
  ///   instanceCreator: () => User(),
  ///   primaryKey: 'id', // Still need to specify primary key
  /// );
  /// ```
  static void registerModel<T extends BaseModel>({
    required T Function() instanceCreator,
    Map<String, ColumnInfo>? columns,
    String? primaryKey,
    Map<String, ForeignKeyInfo> foreignKeys = const {},
    Map<String, RelationshipInfo> relationships = const {},
  }) {
    // Get table name from model instance
    final instance = instanceCreator();
    final tableName = instance.tableName;

    // If columns not provided, infer from toMap()
    final finalColumns = columns ?? inferColumnsFromModel(instance, primaryKey);

    register<T>(
      tableName: tableName,
      columns: finalColumns,
      primaryKey: primaryKey,
      foreignKeys: foreignKeys,
      relationships: relationships,
      instanceCreator: instanceCreator,
    );
  }

  /// Infer column information from model's toMap() method
  /// Made public for use in auto-registration
  static Map<String, ColumnInfo> inferColumnsFromModel(
    BaseModel instance,
    String? primaryKey,
  ) {
    final columns = <String, ColumnInfo>{};
    final map = instance.toMap();

    for (final entry in map.entries) {
      final columnName = entry.key;
      final value = entry.value;

      final isPrimaryKey = columnName == primaryKey;

      // Infer SQL type from Dart type
      String sqlType;
      bool nullable = value == null;

      if (value is int) {
        sqlType = 'INTEGER';
      } else if (value is double || value is num) {
        sqlType = 'REAL';
      } else if (value is String) {
        sqlType = 'TEXT';
      } else if (value is DateTime) {
        sqlType = 'TEXT'; // Store as ISO string
      } else if (value is bool) {
        sqlType = 'INTEGER'; // Store as 0/1
      } else if (value == null) {
        // For null values, try to infer from column name or use default
        if (isPrimaryKey) {
          sqlType = 'INTEGER'; // Primary keys are usually integers
        } else if (columnName.toLowerCase().contains('id')) {
          sqlType = 'INTEGER'; // IDs are usually integers
        } else if (columnName.toLowerCase().contains('date') ||
            columnName.toLowerCase().contains('time') ||
            columnName.toLowerCase().contains('at')) {
          sqlType = 'TEXT'; // Date/time fields are TEXT (ISO strings)
        } else {
          sqlType = 'TEXT'; // Default to TEXT for unknown types
        }
        nullable = true;
      } else {
        sqlType = 'TEXT'; // Default to TEXT for unknown types
        nullable = true;
      }

      // Primary keys are typically not nullable (unless explicitly null in toMap)
      // If primary key is null, assume auto-increment
      final finalNullable = isPrimaryKey ? false : nullable;
      final autoIncrement = isPrimaryKey && value == null;

      columns[columnName] = ColumnInfo(
        name: columnName,
        dartType: _sqlTypeToDartType(sqlType),
        sqlType: sqlType,
        nullable: finalNullable,
        isPrimaryKey: isPrimaryKey,
        autoIncrement: autoIncrement,
      );
    }

    return columns;
  }

  /// Helper to create a ColumnInfo for common types
  static ColumnInfo column({
    required String name,
    required String sqlType,
    bool nullable = true,
    String? defaultValue,
    bool isPrimaryKey = false,
    bool autoIncrement = false,
  }) {
    return ColumnInfo(
      name: name,
      dartType: _sqlTypeToDartType(sqlType),
      sqlType: sqlType,
      nullable: nullable,
      defaultValue: defaultValue,
      isPrimaryKey: isPrimaryKey,
      autoIncrement: autoIncrement,
    );
  }

  static String _sqlTypeToDartType(String sqlType) {
    switch (sqlType.toUpperCase()) {
      case 'INTEGER':
        return 'int';
      case 'REAL':
        return 'double';
      case 'TEXT':
        return 'String';
      case 'DATETIME':
        return 'DateTime';
      case 'BLOB':
        return 'Uint8List';
      default:
        return 'dynamic';
    }
  }
}
