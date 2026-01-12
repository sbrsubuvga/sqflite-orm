/// Annotation to mark a field as a primary key.
///
/// Use this annotation along with [Column] to mark a field as the primary key.
///
/// Example:
/// ```dart
/// @PrimaryKey()
/// @Column(name: 'id')
/// int? id;
/// ```
class PrimaryKey {
  /// Whether the primary key is auto-incrementing.
  ///
  /// Defaults to `true`. Set to `false` for manually assigned primary keys.
  final bool autoIncrement;

  const PrimaryKey({this.autoIncrement = true});
}
