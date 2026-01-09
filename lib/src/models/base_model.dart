/// Base class for all ORM models
abstract class BaseModel {
  /// Internal storage for loaded relationships
  /// This is used by the ORM to store eagerly loaded associations
  /// Public field to allow AssociationLoader to access it
  Map<String, dynamic>? relations;

  /// Convert model to map for database operations
  Map<String, dynamic> toMap();

  /// Create model from map
  BaseModel fromMap(Map<String, dynamic> map);

  /// Get the table name for this model
  String get tableName;

  /// Get a loaded relationship by name
  /// 
  /// Returns the relationship data if it was loaded via withRelations()
  /// Returns null if the relationship hasn't been loaded
  /// 
  /// Example:
  /// ```dart
  /// final post = await db.query<Post>()
  ///   .withRelations(['author'])
  ///   .findByPk(1);
  /// final author = post?.getRelation<User>('author');
  /// ```
  T? getRelation<T>(String relationName) {
    if (relations == null) return null;
    final relation = relations![relationName];
    if (relation is T) {
      return relation;
    }
    if (relation is List && relation.isNotEmpty && relation.first is T) {
      return relation.first as T?;
    }
    return null;
  }

  /// Get a loaded relationship list by name (for OneToMany/ManyToMany)
  /// 
  /// Returns the relationship list if it was loaded via withRelations()
  /// Returns empty list if the relationship hasn't been loaded
  /// 
  /// Example:
  /// ```dart
  /// final user = await db.query<User>()
  ///   .withRelations(['posts'])
  ///   .findByPk(1);
  /// final posts = user?.getRelationList<Post>('posts') ?? [];
  /// ```
  List<T> getRelationList<T>(String relationName) {
    if (relations == null) return [];
    final relation = relations![relationName];
    if (relation is List<T>) {
      return relation;
    }
    if (relation is T) {
      return [relation];
    }
    return [];
  }
}

