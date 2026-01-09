import 'package:sqflite_orm/src/models/base_model.dart';

/// Registry to store all registered models
class ModelRegistry {
  static final ModelRegistry _instance = ModelRegistry._internal();
  factory ModelRegistry() => _instance;
  ModelRegistry._internal();

  final Map<Type, ModelInfo> _models = {};

  /// Register a model type
  void register<T extends BaseModel>(Type modelType, ModelInfo info) {
    _models[modelType] = info;
  }

  /// Get model info for a type
  ModelInfo? getInfo(Type modelType) {
    return _models[modelType];
  }

  /// Get all registered models
  Map<Type, ModelInfo> get allModels => Map.unmodifiable(_models);

  /// Clear all registered models
  void clear() {
    _models.clear();
  }
}

/// Information about a model
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

/// Information about a column
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

/// Information about a foreign key
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

/// Information about a relationship
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
