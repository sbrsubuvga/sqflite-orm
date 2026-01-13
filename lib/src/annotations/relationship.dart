/// Annotation for one-to-many relationship.
///
/// Defines a one-to-many relationship where one record in this model
/// can have many related records in the target model.
///
/// Example:
/// ```dart
/// @Table(name: 'users')
/// class User extends BaseModel {
///   @OneToMany(targetType: Post, foreignKey: 'userId')
///   List<Post>? posts;
/// }
/// ```
class OneToMany {
  /// The target model type (the "many" side of the relationship).
  final Type targetType;

  /// The foreign key column name in the target table that references this model.
  final String foreignKey;

  /// Create a one-to-many relationship annotation.
  ///
  /// [targetType] is the target model type.
  /// [foreignKey] is the foreign key column name in the target table.
  const OneToMany({
    required this.targetType,
    required this.foreignKey,
  });
}

/// Annotation for many-to-one relationship.
///
/// Defines a many-to-one relationship where many records in this model
/// can belong to one record in the target model.
///
/// Example:
/// ```dart
/// @Table(name: 'posts')
/// class Post extends BaseModel {
///   @ManyToOne(targetType: User, foreignKey: 'userId')
///   User? author;
/// }
/// ```
class ManyToOne {
  /// The target model type (the "one" side of the relationship).
  final Type targetType;

  /// The foreign key column name in the current table that references the target model.
  final String foreignKey;

  /// Create a many-to-one relationship annotation.
  ///
  /// [targetType] is the target model type.
  /// [foreignKey] is the foreign key column name in the current table.
  const ManyToOne({
    required this.targetType,
    required this.foreignKey,
  });
}

/// Annotation for many-to-many relationship.
///
/// Defines a many-to-many relationship where records in this model
/// can have many related records in the target model, and vice versa.
/// Requires a join table to store the relationships.
///
/// Example:
/// ```dart
/// @Table(name: 'posts')
/// class Post extends BaseModel {
///   @ManyToMany(
///     targetType: Tag,
///     joinTable: 'post_tags',
///     thisForeignKey: 'postId',
///     targetForeignKey: 'tagId',
///   )
///   List<Tag>? tags;
/// }
/// ```
class ManyToMany {
  /// The target model type.
  final Type targetType;

  /// The join table name that stores the many-to-many relationships.
  final String joinTable;

  /// The foreign key column name in the join table pointing to this model's primary key.
  final String thisForeignKey;

  /// The foreign key column name in the join table pointing to the target model's primary key.
  final String targetForeignKey;

  /// Create a many-to-many relationship annotation.
  ///
  /// [targetType] is the target model type.
  /// [joinTable] is the name of the join table.
  /// [thisForeignKey] is the foreign key in the join table for this model.
  /// [targetForeignKey] is the foreign key in the join table for the target model.
  const ManyToMany({
    required this.targetType,
    required this.joinTable,
    required this.thisForeignKey,
    required this.targetForeignKey,
  });
}
