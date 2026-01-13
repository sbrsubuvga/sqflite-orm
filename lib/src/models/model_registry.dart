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
///
/// This class is used internally by the ORM to manage model metadata.
/// It's typically created automatically during model registration.
class ModelInfo {
  /// The database table name for this model.
  final String tableName;

  /// The Dart type of the model class.
  final Type modelType;

  /// Map of column names to column metadata.
  final Map<String, ColumnInfo> columns;

  /// The name of the primary key column, if any.
  final String? primaryKey;

  /// Map of foreign key names to foreign key metadata.
  final Map<String, ForeignKeyInfo> foreignKeys;

  /// Map of relationship names to relationship metadata.
  final Map<String, RelationshipInfo> relationships;

  /// Factory function to create model instances from database rows.
  ///
  /// This function is used to convert database rows (Map<String, dynamic>)
  /// into model instances. If not provided, models must implement [BaseModel.fromMap].
  final BaseModel Function(Map<String, dynamic>)? factory;

  /// Create model information.
  ///
  /// [tableName] is the database table name.
  /// [modelType] is the Dart type of the model.
  /// [columns] is the map of column metadata.
  /// [primaryKey] is the primary key column name (optional).
  /// [foreignKeys] is the map of foreign key metadata (optional).
  /// [relationships] is the map of relationship metadata (optional).
  /// [factory] is the factory function to create instances (optional).
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
///
/// This class is used internally to store column metadata for registered models.
class ColumnInfo {
  /// The column name in the database.
  final String name;

  /// The Dart type name (e.g., 'int', 'String', 'DateTime').
  final String dartType;

  /// The SQL type name (e.g., 'INTEGER', 'TEXT', 'REAL').
  final String sqlType;

  /// Whether the column allows NULL values.
  final bool nullable;

  /// Default value for the column (SQL expression or literal).
  final String? defaultValue;

  /// Whether this column is a primary key.
  final bool isPrimaryKey;

  /// Whether this column auto-increments (only valid for primary keys).
  final bool autoIncrement;

  /// Create column information.
  ///
  /// [name] is the column name.
  /// [dartType] is the Dart type name.
  /// [sqlType] is the SQL type name.
  /// [nullable] is whether the column allows NULL (defaults to true).
  /// [defaultValue] is the default value (optional).
  /// [isPrimaryKey] is whether this is a primary key (defaults to false).
  /// [autoIncrement] is whether this auto-increments (defaults to false).
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
///
/// This class is used internally to store foreign key metadata.
class ForeignKeyInfo {
  /// The referenced table name.
  final String table;

  /// The referenced column name (typically the primary key).
  final String column;

  /// Whether to cascade deletes (delete related records when parent is deleted).
  final bool onDeleteCascade;

  /// Whether to cascade updates (update related records when parent key changes).
  final bool onUpdateCascade;

  /// Create foreign key information.
  ///
  /// [table] is the referenced table name.
  /// [column] is the referenced column name.
  /// [onDeleteCascade] is whether to cascade deletes (defaults to false).
  /// [onUpdateCascade] is whether to cascade updates (defaults to false).
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
///
/// This class is used internally to store relationship metadata for eager loading.
class RelationshipInfo {
  /// The relationship type: 'OneToMany', 'ManyToOne', or 'ManyToMany'.
  final String type;

  /// The target model type for this relationship.
  final Type targetType;

  /// The foreign key column name (for OneToMany and ManyToOne).
  final String? foreignKey;

  /// The join table name (for ManyToMany relationships).
  final String? joinTable;

  /// The foreign key in the join table pointing to this model (for ManyToMany).
  final String? thisForeignKey;

  /// The foreign key in the join table pointing to the target model (for ManyToMany).
  final String? targetForeignKey;

  /// Create relationship information.
  ///
  /// [type] is the relationship type ('OneToMany', 'ManyToOne', or 'ManyToMany').
  /// [targetType] is the target model type.
  /// [foreignKey] is the foreign key column name (for OneToMany/ManyToOne).
  /// [joinTable] is the join table name (for ManyToMany).
  /// [thisForeignKey] is the foreign key in join table for this model (for ManyToMany).
  /// [targetForeignKey] is the foreign key in join table for target model (for ManyToMany).
  RelationshipInfo({
    required this.type,
    required this.targetType,
    this.foreignKey,
    this.joinTable,
    this.thisForeignKey,
    this.targetForeignKey,
  });
}
