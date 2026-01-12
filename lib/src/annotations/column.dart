/// Annotation to mark a field as a database column.
///
/// Use this annotation on fields in model classes to specify column properties.
///
/// Example:
/// ```dart
/// @Column(name: 'email', nullable: false)
/// String? email;
///
/// @Column(name: 'created_at', defaultValue: 'CURRENT_TIMESTAMP')
/// DateTime? createdAt;
/// ```
class Column {
  /// The name of the column in the database.
  ///
  /// If null, the field name will be used as the column name.
  final String? name;

  /// Whether the column is nullable.
  ///
  /// Defaults to `true`.
  final bool nullable;

  /// Default value for the column.
  ///
  /// Can be a SQL expression like 'CURRENT_TIMESTAMP' or a literal value.
  final String? defaultValue;

  /// Whether this column should be ignored by the ORM.
  ///
  /// If `true`, this field will not be included in database operations.
  final bool ignore;

  const Column({
    this.name,
    this.nullable = true,
    this.defaultValue,
    this.ignore = false,
  });
}
