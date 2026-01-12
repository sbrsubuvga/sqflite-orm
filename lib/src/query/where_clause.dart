/// Builder for WHERE clauses in SQL queries.
///
/// Provides a fluent API for building WHERE conditions.
/// All conditions are combined with AND by default.
///
/// Example:
/// ```dart
/// final where = WhereClause()
///   .equals('status', 'active')
///   .greaterThan('age', 18)
///   .isNotNull('email');
///
/// final users = await db.query<User>()
///   .whereClause(where)
///   .findAll();
/// ```
class WhereClause {
  final List<String> conditions = [];
  final List<dynamic> arguments = [];

  /// Add an equality condition.
  ///
  /// Example:
  /// ```dart
  /// WhereClause().equals('email', 'john@example.com')
  /// ```
  WhereClause equals(String column, dynamic value) {
    conditions.add('$column = ?');
    arguments.add(value);
    return this;
  }

  /// Add a not-equal condition.
  ///
  /// Example:
  /// ```dart
  /// WhereClause().notEquals('status', 'deleted')
  /// ```
  WhereClause notEquals(String column, dynamic value) {
    conditions.add('$column != ?');
    arguments.add(value);
    return this;
  }

  /// Add a greater than condition.
  ///
  /// Example:
  /// ```dart
  /// WhereClause().greaterThan('age', 18)
  /// ```
  WhereClause greaterThan(String column, dynamic value) {
    conditions.add('$column > ?');
    arguments.add(value);
    return this;
  }

  /// Add a less than condition.
  ///
  /// Example:
  /// ```dart
  /// WhereClause().lessThan('age', 65)
  /// ```
  WhereClause lessThan(String column, dynamic value) {
    conditions.add('$column < ?');
    arguments.add(value);
    return this;
  }

  /// Add a greater than or equal condition.
  ///
  /// Example:
  /// ```dart
  /// WhereClause().greaterThanOrEqual('score', 100)
  /// ```
  WhereClause greaterThanOrEqual(String column, dynamic value) {
    conditions.add('$column >= ?');
    arguments.add(value);
    return this;
  }

  /// Add a less than or equal condition.
  ///
  /// Example:
  /// ```dart
  /// WhereClause().lessThanOrEqual('price', 100.0)
  /// ```
  WhereClause lessThanOrEqual(String column, dynamic value) {
    conditions.add('$column <= ?');
    arguments.add(value);
    return this;
  }

  /// Add a LIKE condition for pattern matching.
  ///
  /// Example:
  /// ```dart
  /// WhereClause().like('name', '%john%')
  /// ```
  WhereClause like(String column, String pattern) {
    conditions.add('$column LIKE ?');
    arguments.add(pattern);
    return this;
  }

  /// Add an IN condition to match any value in a list.
  ///
  /// Example:
  /// ```dart
  /// WhereClause().inList('status', ['active', 'pending'])
  /// ```
  WhereClause inList(String column, List<dynamic> values) {
    if (values.isEmpty) {
      conditions.add('1 = 0'); // Always false
      return this;
    }
    final placeholders = List.filled(values.length, '?').join(', ');
    conditions.add('$column IN ($placeholders)');
    arguments.addAll(values);
    return this;
  }

  /// Add an IS NULL condition.
  ///
  /// Example:
  /// ```dart
  /// WhereClause().isNull('deletedAt')
  /// ```
  WhereClause isNull(String column) {
    conditions.add('$column IS NULL');
    return this;
  }

  /// Add an IS NOT NULL condition.
  ///
  /// Example:
  /// ```dart
  /// WhereClause().isNotNull('email')
  /// ```
  WhereClause isNotNull(String column) {
    conditions.add('$column IS NOT NULL');
    return this;
  }

  /// Combine with another WhereClause using AND.
  ///
  /// Example:
  /// ```dart
  /// final where = WhereClause().equals('status', 'active')
  ///   .and(WhereClause().greaterThan('age', 18));
  /// ```
  WhereClause and(WhereClause other) {
    conditions.addAll(other.conditions);
    arguments.addAll(other.arguments);
    return this;
  }

  /// Combine with another WhereClause using OR.
  ///
  /// Example:
  /// ```dart
  /// final where = WhereClause().equals('status', 'active')
  ///   .or(WhereClause().equals('status', 'pending'));
  /// ```
  WhereClause or(WhereClause other) {
    if (conditions.isNotEmpty) {
      final current = conditions.join(' AND ');
      conditions.clear();
      conditions.add('($current OR ${other.conditions.join(' AND ')})');
      arguments.addAll(other.arguments);
    } else {
      conditions.addAll(other.conditions);
      arguments.addAll(other.arguments);
    }
    return this;
  }

  /// Build the WHERE clause SQL string.
  ///
  /// Returns an empty string if no conditions are set.
  String build() {
    if (conditions.isEmpty) return '';
    return 'WHERE ${conditions.join(' AND ')}';
  }

  /// Get the arguments for the WHERE clause.
  ///
  /// These are the values that correspond to the placeholders (?) in the SQL.
  List<dynamic> get args => arguments;
}
