import 'package:sqflite_orm/src/models/base_model.dart';

/// Registry to store all registered models.
///
/// This is a singleton that maintains information about all registered
/// model types, including their table names, columns, and relationships.
///
/// Models are typically registered automatically during [DatabaseManager.initialize],
/// but can also be registered manually.
class ModelRegistry {
  static final ModelRegistry _instance = ModelRegistry._internal();
  factory ModelRegistry() => _instance;
  ModelRegistry._internal();

  final Map<Type, ModelInfo> _models = {};

  /// Register a model type with its metadata.
  ///
  /// Typically called automatically during database initialization,
  /// but can be called manually for custom registration.
  void register<T extends BaseModel>(Type modelType, ModelInfo info) {
    _models[modelType] = info;
  }

  /// Get model info for a type.
  ///
  /// Returns `null` if the model type is not registered.
  ModelInfo? getInfo(Type modelType) {
    return _models[modelType];
  }

  /// Get all registered models.
  ///
  /// Returns an unmodifiable map of all registered model types and their info.
  Map<Type, ModelInfo> get allModels => Map.unmodifiable(_models);

  /// Clear all registered models.
  ///
  /// Useful for testing or resetting the registry.
  void clear() {
    _models.clear();
  }
}

/// Information about a registered model.
///
/// Contains metadata about a model including its table name, columns,
/// primary key, foreign keys, and relationships.
class ModelInfo {
  final String tableName;
  final Type modelType;
  final Map<String, ColumnInfo> columns;
  final String? primaryKey;
  final Map<String, ForeignKeyInfo> foreignKeys;
  final Map<String, RelationshipInfo> relationships;
  final BaseModel Function(Map<String, dynamic>)? factory;

  ModelInfo({
    required this.tableName,
    required this.modelType,
    required this.columns,
    this.primaryKey,
    this.foreignKeys = const {},
    this.relationships = const {},
    this.factory,
  });
}

/// Information about a database column.
///
/// Contains metadata about a column including its name, type, nullability,
/// and whether it's a primary key.
class ColumnInfo {
  final String name;
  final String dartType;
  final String sqlType;
  final bool nullable;
  final String? defaultValue;
  final bool isPrimaryKey;
  final bool autoIncrement;

  ColumnInfo({
    required this.name,
    required this.dartType,
    required this.sqlType,
    this.nullable = true,
    this.defaultValue,
    this.isPrimaryKey = false,
    this.autoIncrement = false,
  });
}

/// Information about a foreign key relationship.
///
/// Contains metadata about a foreign key including the referenced table
/// and column, and cascade options.
class ForeignKeyInfo {
  final String table;
  final String column;
  final bool onDeleteCascade;
  final bool onUpdateCascade;

  ForeignKeyInfo({
    required this.table,
    required this.column,
    this.onDeleteCascade = false,
    this.onUpdateCascade = false,
  });
}

/// Information about a model relationship.
///
/// Contains metadata about relationships between models including the type
/// (OneToMany, ManyToOne, ManyToMany), target model, and foreign keys.
class RelationshipInfo {
  final String type; // 'OneToMany', 'ManyToOne', 'ManyToMany'
  final Type targetType;
  final String? foreignKey;
  final String? joinTable;
  final String? thisForeignKey;
  final String? targetForeignKey;

  RelationshipInfo({
    required this.type,
    required this.targetType,
    this.foreignKey,
    this.joinTable,
    this.thisForeignKey,
    this.targetForeignKey,
  });
}
