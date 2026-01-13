import 'package:sqflite_common/sqlite_api.dart' show Database;
import 'package:sqflite_orm/src/models/model_registry.dart';
import 'package:sqflite_orm/src/models/base_model.dart';

/// Handles eager loading of relationships (associations) for models.
///
/// This class is used internally by [QueryBuilder] to load relationships
/// when using the `include()` method. It supports OneToMany, ManyToOne,
/// and ManyToMany relationship types.
///
/// Example:
/// ```dart
/// final loader = AssociationLoader();
/// await loader.loadRelations(db, posts, ['author', 'comments'], postInfo);
/// final author = posts[0].getRelation<User>('author');
/// ```
class AssociationLoader {
  /// Create an association loader instance.
  ///
  /// Used internally by [QueryBuilder] to load relationships when using
  /// the `include()` or `withRelations()` methods.
  AssociationLoader();

  /// Load relationships for a list of models.
  ///
  /// Eagerly loads the specified relationships for all models in the list.
  /// The loaded relationships are stored in each model's internal relations map
  /// and can be accessed via [BaseModel.getRelation].
  ///
  /// [db] is the database connection.
  /// [models] is the list of models to load relationships for.
  /// [relationNames] is the list of relationship names to load.
  /// [modelInfo] is the model metadata containing relationship definitions.
  ///
  /// Supported relationship types:
  /// - `ManyToOne`: Loads a single related record via foreign key
  /// - `OneToMany`: Loads multiple related records via foreign key
  /// - `ManyToMany`: Loads multiple related records via join table
  Future<void> loadRelations<T extends BaseModel>(
    Database db,
    List<T> models,
    List<String> relationNames,
    ModelInfo modelInfo,
  ) async {
    if (models.isEmpty) return;

    for (final relationName in relationNames) {
      final relationship = modelInfo.relationships[relationName];
      if (relationship == null) {
        continue;
      }

      switch (relationship.type) {
        case 'ManyToOne':
          await _loadManyToOne(
              db, models, relationship, modelInfo, relationName);
          break;
        case 'OneToMany':
          await _loadOneToMany(
              db, models, relationship, modelInfo, relationName);
          break;
        case 'ManyToMany':
          await _loadManyToMany(
              db, models, relationship, modelInfo, relationName);
          break;
      }
    }
  }

  Future<void> _loadManyToOne(
    Database db,
    List<BaseModel> models,
    RelationshipInfo relationship,
    ModelInfo modelInfo,
    String relationName,
  ) async {
    if (relationship.foreignKey == null) return;

    // Get unique foreign key values
    final fkValues = models
        .map((m) => m.toMap()[relationship.foreignKey] as dynamic)
        .where((v) => v != null)
        .toSet()
        .toList();

    if (fkValues.isEmpty) return;

    final targetInfo = ModelRegistry().getInfo(relationship.targetType);
    if (targetInfo == null) return;

    // Load related records
    if (targetInfo.primaryKey == null) return;
    final placeholders = List.filled(fkValues.length, '?').join(', ');
    final query = 'SELECT * FROM ${targetInfo.tableName} '
        'WHERE ${targetInfo.primaryKey} IN ($placeholders)';

    final relatedRecords = await db.rawQuery(query, fkValues);
    final relatedMap = <dynamic, BaseModel>{};

    // Create map of related records using factory function
    if (targetInfo.factory != null) {
      for (final row in relatedRecords) {
        final key = row[targetInfo.primaryKey];
        if (key != null) {
          try {
            final instance = targetInfo.factory!(row);
            relatedMap[key] = instance;
          } catch (e) {
            // Failed to create instance
          }
        }
      }
    }

    // Assign related records to models
    // Store in model's __relations map (models can access via getRelation)
    for (final model in models) {
      final fkValue = model.toMap()[relationship.foreignKey];
      if (fkValue != null && relatedMap.containsKey(fkValue)) {
        // Store relationship in model's internal map
        model.relations ??= <String, dynamic>{};
        model.relations![relationName] = relatedMap[fkValue];
      }
    }
  }

  Future<void> _loadOneToMany(
    Database db,
    List<BaseModel> models,
    RelationshipInfo relationship,
    ModelInfo modelInfo,
    String relationName,
  ) async {
    if (relationship.foreignKey == null) return;

    final targetInfo = ModelRegistry().getInfo(relationship.targetType);
    if (targetInfo == null) return;

    // Get primary keys of parent models
    final modelPrimaryKey = modelInfo.primaryKey;
    if (modelPrimaryKey == null) return;
    final parentKeys = models
        .map((m) => m.toMap()[modelPrimaryKey] as dynamic)
        .where((v) => v != null)
        .toList();

    if (parentKeys.isEmpty) return;

    // Load all related records
    final placeholders = List.filled(parentKeys.length, '?').join(', ');
    final query = 'SELECT * FROM ${targetInfo.tableName} '
        'WHERE ${relationship.foreignKey} IN ($placeholders)';

    final relatedRecords = await db.rawQuery(query, parentKeys);
    final relatedMap = <dynamic, List<BaseModel>>{};

    // Group related records by foreign key using factory function
    if (targetInfo.factory != null) {
      for (final row in relatedRecords) {
        final fkValue = row[relationship.foreignKey];
        if (fkValue != null) {
          relatedMap.putIfAbsent(fkValue, () => []);
          try {
            final instance = targetInfo.factory!(row);
            relatedMap[fkValue]!.add(instance);
          } catch (e) {
            // Failed to create instance
          }
        }
      }
    }

    // Assign related records to models
    // Use the already defined modelPrimaryKey from above
    for (final model in models) {
      final pkValue = model.toMap()[modelPrimaryKey];
      if (pkValue != null && relatedMap.containsKey(pkValue)) {
        // Store relationship in model's internal map
        model.relations ??= <String, dynamic>{};
        model.relations![relationName] = relatedMap[pkValue];
      }
    }
  }

  Future<void> _loadManyToMany(
    Database db,
    List<BaseModel> models,
    RelationshipInfo relationship,
    ModelInfo modelInfo,
    String relationName,
  ) async {
    if (relationship.joinTable == null ||
        relationship.thisForeignKey == null ||
        relationship.targetForeignKey == null) {
      return;
    }

    final targetInfo = ModelRegistry().getInfo(relationship.targetType);
    if (targetInfo == null) return;

    // Get primary keys of parent models
    final modelPrimaryKey = modelInfo.primaryKey;
    if (modelPrimaryKey == null) return;
    final parentKeys = models
        .map((m) => m.toMap()[modelPrimaryKey] as dynamic)
        .where((v) => v != null)
        .toList();

    if (parentKeys.isEmpty) return;

    // Load through join table
    if (targetInfo.primaryKey == null) return;
    final placeholders = List.filled(parentKeys.length, '?').join(', ');
    final query = '''
      SELECT t.*, j.${relationship.thisForeignKey} as _parent_id
      FROM ${targetInfo.tableName} t
      INNER JOIN ${relationship.joinTable} j
        ON t.${targetInfo.primaryKey} = j.${relationship.targetForeignKey}
      WHERE j.${relationship.thisForeignKey} IN ($placeholders)
    ''';

    final relatedRecords = await db.rawQuery(query, parentKeys);
    final relatedMap = <dynamic, List<BaseModel>>{};

    // Group related records by parent key using factory function
    if (targetInfo.factory != null) {
      for (final row in relatedRecords) {
        final parentId = row['_parent_id'];
        if (parentId != null) {
          relatedMap.putIfAbsent(parentId, () => []);
          try {
            // Remove the temporary _parent_id column before creating model
            final cleanRow = Map<String, dynamic>.from(row);
            cleanRow.remove('_parent_id');
            final instance = targetInfo.factory!(cleanRow);
            relatedMap[parentId]!.add(instance);
          } catch (e) {
            // Failed to create instance
          }
        }
      }
    }

    // Assign related records to models
    // Use the already defined modelPrimaryKey from above
    for (final model in models) {
      final pkValue = model.toMap()[modelPrimaryKey];
      if (pkValue != null && relatedMap.containsKey(pkValue)) {
        // Store relationship in model's internal map
        model.relations ??= <String, dynamic>{};
        model.relations![relationName] = relatedMap[pkValue];
      }
    }
  }
}
