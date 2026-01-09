/// Annotation to mark a field as a primary key
class PrimaryKey {
  /// Whether the primary key is auto-incrementing
  final bool autoIncrement;

  const PrimaryKey({this.autoIncrement = true});
}

