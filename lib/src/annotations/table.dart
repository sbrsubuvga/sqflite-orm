/// Annotation to mark a class as a database table.
///
/// Use this annotation on model classes that extend [BaseModel].
///
/// Example:
/// ```dart
/// @Table(name: 'users')
/// class User extends BaseModel {
///   // ...
/// }
/// ```
class Table {
  /// The name of the table in the database.
  final String name;

  const Table({required this.name});
}
