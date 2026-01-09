/// Annotation to mark a field as a database column
class Column {
  /// The name of the column in the database
  final String? name;

  /// Whether the column is nullable
  final bool nullable;

  /// Default value for the column
  final String? defaultValue;

  /// Whether this column should be ignored
  final bool ignore;

  const Column({
    this.name,
    this.nullable = true,
    this.defaultValue,
    this.ignore = false,
  });
}

