/// Base class for all ORM models.
///
/// All model classes must extend this class and implement the required methods.
/// Models should be annotated with [Table] and their fields with [Column].
///
/// Example:
/// ```dart
/// @Table(name: 'users')
/// class User extends BaseModel {
///   @PrimaryKey()
///   @Column(name: 'id')
///   int? id;
///
///   @Column(name: 'name')
///   String? name;
///
///   @override
///   Map<String, dynamic> toMap() => {'id': id, 'name': name};
///
///   @override
///   BaseModel fromMap(Map<String, dynamic> map) =>
///       User()..id = map['id']..name = map['name'];
///
///   @override
///   String get tableName => 'users';
/// }
/// ```
abstract class BaseModel {
  /// Internal storage for loaded relationships.
  ///
  /// This is used by the ORM to store eagerly loaded associations.
  /// Public field to allow AssociationLoader to access it.
  Map<String, dynamic>? relations;

  /// Convert model to map for database operations.
  ///
  /// This method is used when inserting or updating records.
  /// All fields that should be persisted must be included in the returned map.
  Map<String, dynamic> toMap();

  /// Create model from map.
  ///
  /// This method is used when reading records from the database.
  /// Should create a new instance of the model and populate it with data from the map.
  BaseModel fromMap(Map<String, dynamic> map);

  /// Get the table name for this model.
  ///
  /// Should return the same name as specified in the [Table] annotation.
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
