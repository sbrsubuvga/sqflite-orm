/// Annotation to mark a field as a foreign key.
///
/// Use this annotation along with [Column] to define foreign key relationships.
///
/// Example:
/// ```dart
/// @ForeignKey(table: 'users', column: 'id')
/// @Column(name: 'userId')
/// int? userId;
/// ```
class ForeignKey {
  /// The name of the referenced table.
  final String table;

  /// The name of the referenced column (typically 'id').
  final String column;

  /// Whether to cascade on delete.
  ///
  /// If `true`, deleting the referenced record will delete this record.
  final bool onDeleteCascade;

  /// Whether to cascade on update.
  ///
  /// If `true`, updating the referenced record's key will update this record.
  final bool onUpdateCascade;

  const ForeignKey({
    required this.table,
    required this.column,
    this.onDeleteCascade = false,
    this.onUpdateCascade = false,
  });
}
