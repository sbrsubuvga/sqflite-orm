/// Annotation for one-to-many relationship
class OneToMany {
  /// The target model type
  final Type targetType;

  /// The foreign key column name in the target table
  final String foreignKey;

  const OneToMany({
    required this.targetType,
    required this.foreignKey,
  });
}

/// Annotation for many-to-one relationship
class ManyToOne {
  /// The target model type
  final Type targetType;

  /// The foreign key column name in the current table
  final String foreignKey;

  const ManyToOne({
    required this.targetType,
    required this.foreignKey,
  });
}

/// Annotation for many-to-many relationship
class ManyToMany {
  /// The target model type
  final Type targetType;

  /// The join table name
  final String joinTable;

  /// The foreign key column name in the join table pointing to this table
  final String thisForeignKey;

  /// The foreign key column name in the join table pointing to the target table
  final String targetForeignKey;

  const ManyToMany({
    required this.targetType,
    required this.joinTable,
    required this.thisForeignKey,
    required this.targetForeignKey,
  });
}

