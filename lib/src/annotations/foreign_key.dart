/// Annotation to mark a field as a foreign key
class ForeignKey {
  /// The name of the referenced table
  final String table;

  /// The name of the referenced column
  final String column;

  /// Whether to cascade on delete
  final bool onDeleteCascade;

  /// Whether to cascade on update
  final bool onUpdateCascade;

  const ForeignKey({
    required this.table,
    required this.column,
    this.onDeleteCascade = false,
    this.onUpdateCascade = false,
  });
}

